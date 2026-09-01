#!/usr/bin/env bash
# Refuse content that looks like a live credential.
# Not `set -e`: a non-matching grep must not abort the scan.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ALLOWLIST="$REPO_ROOT/scripts/secret-allowlist.txt"

# Shapes that are almost always a real credential. Each has a fixed prefix or
# a fixed structure, so the false-positive rate is near zero.
HIGH_SIGNAL='Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|sk-[A-Za-z0-9]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|glpat-[A-Za-z0-9_-]{16,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|xox[baprs]-[A-Za-z0-9-]{10,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|AIza[A-Za-z0-9_-]{30,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|A(KIA|SIA)[0-9A-Z]{16}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|-----BEGIN [A-Z ]*PRIVATE KEY-----'

# A credential introduced by name. This is the rule that catches what the other
# two structurally cannot: a 64-character hexadecimal Trello token, which the
# generic rule skips as a git hash, and an AWS secret key containing / or +,
# which the generic character class excludes. Requiring a secret-shaped
# identifier immediately before the separator is what stops it matching every
# long path in the repo.
NAMED='(secret|token|passwd|password|api[_-]?key|access[_-]?key|apikey)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+=_.-]{16,}'

# A long opaque run. Pure lowercase hexadecimal is skipped, because that is a
# git hash. The character class deliberately excludes / + and =: a POSIX path
# such as /Users/someone/Projects/prive/ai/scripts is over 40 characters and
# would otherwise be reported on nearly every line of this repo. The NAMED rule
# above covers the credentials this exclusion would otherwise miss.
GENERIC_MIN=40

usage() {
  cat <<'USAGE'
Usage: check-secrets.sh [--staged] [file ...]

  --staged   Scan the staged content of the files git has staged. This reads
             the index, not the working tree, because the index is what a
             commit will actually record.
  (no args)  Scan every file git tracks, as it exists in the working tree.
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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/checksecrets.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

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

# scan_file <file to read> <label to report>
#
# Two greps per FILE, not two per line. The old per-line loop forked up to two
# subprocesses for every line, which took minutes on a large tracked file and
# pushed people towards --no-verify. It also dropped a final line that had no
# trailing newline, because `read` returns non-zero there.
scan_file() {
  src="$1"
  label="$2"
  [ -s "$src" ] || return 0
  # Skip binary files.
  grep -qI . "$src" 2>/dev/null || return 0

  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -nE "$HIGH_SIGNAL" "$src" 2>/dev/null | cut -d: -f1 | sort -un)
EOF

  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -niE "$NAMED" "$src" 2>/dev/null | cut -d: -f1 | sort -un)
EOF

  while IFS= read -r pair; do
    [ -n "$pair" ] || continue
    ln=${pair%%:*}
    tok=${pair#*:}
    case "$tok" in
      *[!0-9a-f]*) ;;
      *) continue ;;
    esac
    allowed "$tok" && continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -noE "[A-Za-z0-9_-]{$GENERIC_MIN,}" "$src" 2>/dev/null)
EOF
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$MODE" in
    args)
      scan_file "$f" "$f"
      ;;
    staged)
      path_allowed "$f" && continue
      # Read what the commit would record, not what is on disk. A file staged
      # and then edited differs, and the staged version is the one that counts.
      blob="$WORK/staged"
      git -C "$REPO_ROOT" show ":$f" >"$blob" 2>/dev/null || continue
      scan_file "$blob" "$f"
      rm -f "$blob"
      ;;
    *)
      path_allowed "$f" && continue
      scan_file "$REPO_ROOT/$f" "$f"
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
