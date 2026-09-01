# Shared helpers for the shell tests. Source this file; do not run it.
# Deliberately does not use `set -e`, because a failing check must not abort the file.
set -uo pipefail

CHECKS_RUN=0
CHECKS_FAILED=0

_pass() { CHECKS_RUN=$((CHECKS_RUN + 1)); printf '  ok   %s\n' "$1"; }
_fail() {
  CHECKS_RUN=$((CHECKS_RUN + 1))
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
  printf '  FAIL %s\n' "$1" >&2
  [ $# -gt 1 ] && printf '       %s\n' "$2" >&2
  return 0
}

assert_eq() { # expected actual message
  if [ "$1" = "$2" ]; then _pass "$3"; else _fail "$3" "expected '$1', got '$2'"; fi
}

assert_rc() { # expected_code actual_code message
  if [ "$1" -eq "$2" ]; then _pass "$3"; else _fail "$3" "expected exit $1, got $2"; fi
}

assert_symlink_to() { # link target message
  if [ ! -L "$1" ]; then
    _fail "$3" "'$1' is not a symlink"
  elif [ "$(readlink "$1")" = "$2" ]; then
    _pass "$3"
  else
    _fail "$3" "'$1' points at '$(readlink "$1")', want '$2'"
  fi
}

assert_file() { # path message
  if [ -e "$1" ]; then _pass "$2"; else _fail "$2" "'$1' does not exist"; fi
}

assert_no_file() { # path message
  if [ ! -e "$1" ]; then _pass "$2"; else _fail "$2" "'$1' exists but should not"; fi
}

assert_contains() { # haystack needle message
  case "$1" in
    *"$2"*) _pass "$3" ;;
    *) _fail "$3" "'$2' not found in output" ;;
  esac
}

make_fake_home() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/aicfg.XXXXXX")
  mkdir -p "$d/.claude/skills" "$d/.claude/output-styles" "$d/.claude/commands"
  printf '{}\n' >"$d/.claude.json"
  printf '%s' "$d"
}

finish() {
  printf '  -- %s checks, %s failed\n' "$CHECKS_RUN" "$CHECKS_FAILED"
  [ "$CHECKS_FAILED" -eq 0 ] || exit 1
  exit 0
}
