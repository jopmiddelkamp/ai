#!/usr/bin/env bash
# Refuse content that looks like a live credential.
# Not `set -e`: a non-matching grep must not abort the scan.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ALLOWLIST="$REPO_ROOT/scripts/secret-allowlist.txt"

# Shapes that are almost always a real credential.
HIGH_SIGNAL='Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[A-Za-z0-9_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

# A long opaque run. Pure hexadecimal is skipped, because that is a git hash.
GENERIC_MIN=40

usage() {
  cat <<'USAGE'
Usage: check-secrets.sh [--staged] [file ...]

  --staged   Scan the files git has staged.
  (no args)  Scan every file git tracks.
USAGE
}

FILES=""
MODE="tracked"

while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE="staged" ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'check-secrets.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) MODE="args"; FILES="$FILES
$1" ;;
  esac
  shift
done

case "$MODE" in
  staged)  FILES=$(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACM) ;;
  tracked) FILES=$(git -C "$REPO_ROOT" ls-files) ;;
esac

allowed() {
  [ -f "$ALLOWLIST" ] || return 1
  grep -qxF "$1" "$ALLOWLIST"
}

# A "path:" line in the allowlist skips a whole tracked file, matched on its
# repo-relative path. Two files here hold fake credentials as their own
# content: this guard's test fixtures, and the plan document those fixtures
# were copied from. Without this, the guard could never pass its own
# repo-wide scan, and its pre-commit hook could never commit its own tests.
path_allowed() {
  [ -f "$ALLOWLIST" ] || return 1
  grep -qxF "path:$1" "$ALLOWLIST"
}

report() { printf '%s:%s: possible credential\n' "$1" "$2" >&2; }

HITS=0

scan_file() {
  file="$1"
  [ -f "$file" ] || return 0
  # Skip binary files.
  grep -qI . "$file" 2>/dev/null || return 0

  n=0
  while IFS= read -r line; do
    n=$((n + 1))
    if printf '%s' "$line" | grep -qE "$HIGH_SIGNAL"; then
      report "$file" "$n"; HITS=$((HITS + 1)); continue
    fi
    for tok in $(printf '%s' "$line" | grep -oE "[A-Za-z0-9_-]{$GENERIC_MIN,}" 2>/dev/null); do
      case "$tok" in
        *[!0-9a-f]*)
          allowed "$tok" && continue
          report "$file" "$n"; HITS=$((HITS + 1)); break
          ;;
      esac
    done
  done <"$file"
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$MODE" in
    args)
      scan_file "$f"
      ;;
    *)
      path_allowed "$f" && continue
      scan_file "$REPO_ROOT/$f"
      ;;
  esac
done <<EOF
$FILES
EOF

if [ "$HITS" -gt 0 ]; then
  printf '\ncheck-secrets.sh: %s possible credential(s) found.\n' "$HITS" >&2
  printf 'Move the value to ~/.claude/mcp.env and use a ${VAR} placeholder.\n' >&2
  printf 'A false positive? Add the exact string to scripts/secret-allowlist.txt.\n' >&2
  exit 1
fi

printf 'check-secrets.sh: clean\n'
exit 0
