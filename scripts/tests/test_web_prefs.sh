#!/usr/bin/env bash
# web-prefs.sh builds the claude.ai preferences text: the global memory
# rules first, then the output-style body, with no frontmatter.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

out=$(bash "$repo/scripts/web-prefs.sh" 2>/dev/null)
assert_rc 0 $? "web-prefs.sh succeeds"
assert_contains "$out" "Dutch-style directness" "the output holds the behavior rules"
assert_contains "$out" "ASD-STE100" "the output holds the style rules"

case "$out" in
  *"name: ELI5-readable"*) _fail "the output strips the frontmatter" "the name line leaked through" ;;
  *) _pass "the output strips the frontmatter" ;;
esac

first=$(printf '%s\n' "$out" | grep -n -m1 'Dutch-style directness' | cut -d: -f1)
second=$(printf '%s\n' "$out" | grep -n -m1 'ASD-STE100' | cut -d: -f1)
if [ -n "$first" ] && [ -n "$second" ] && [ "$first" -lt "$second" ]; then
  _pass "the behavior rules come before the style rules"
else
  _fail "the behavior rules come before the style rules" "wrong order or a marker is missing"
fi

finish
