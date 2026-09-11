#!/usr/bin/env bash
# Every skill directory must have the right shape, whatever its name.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

count=0
for d in "$repo"/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "${d%/}")
  count=$((count + 1))
  f="$d/SKILL.md"
  assert_file "$f" "skills/$name has SKILL.md"
  [ -f "$f" ] || continue
  assert_eq "---" "$(head -1 "$f")" "skills/$name opens with frontmatter"
  if grep -qE '^name:[[:space:]]*'"$name"'[[:space:]]*$' "$f"; then
    _pass "skills/$name declares its own name"
  else
    _fail "skills/$name declares its own name" "the name line does not match the directory"
  fi
  if grep -qE '^description:' "$f"; then
    _pass "skills/$name has a description"
  else
    _fail "skills/$name has a description" "no description line"
  fi
  assert_no_file "$d/.git" "skills/$name holds no nested git repo"
done

if [ "$count" -gt 0 ]; then
  _pass "found $count skills to check"
else
  _fail "found $count skills to check" "the skills directory is empty"
fi

# Nothing is copied from other repos any more. Somebody else's skill is
# installed as a plugin and listed in settings/plugins.md.
assert_no_file "$repo/sources.yaml" "sources.yaml is gone"

finish
