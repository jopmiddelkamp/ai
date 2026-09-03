#!/usr/bin/env bash
# Every stored skill must have the right shape, and no nested git repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

for s in bro github-pr-comment review-pr skill-sync-reminder humanizer \
         sync-upstream sync-mcp config-capture; do
  assert_file "$repo/skills/$s/SKILL.md" "skills/$s/SKILL.md exists"
  assert_eq "---" "$(head -1 "$repo/skills/$s/SKILL.md" 2>/dev/null)" "skills/$s/SKILL.md opens with frontmatter"
  if grep -qE '^name:[[:space:]]*'"$s"'[[:space:]]*$' "$repo/skills/$s/SKILL.md" 2>/dev/null; then
    _pass "skills/$s declares name: $s"
  else
    _fail "skills/$s declares name: $s" "frontmatter name does not match the directory"
  fi
  assert_no_file "$repo/skills/$s/.git" "skills/$s holds no nested git repo"
done

assert_file "$repo/output-styles/eli5.md" "output-styles/eli5.md exists"
assert_file "$repo/commands/bro.md" "commands/bro.md exists"

# web-prefs.sh pastes memory/CLAUDE.md as-is, so it must not open with a
# frontmatter fence.
if [ -f "$repo/memory/CLAUDE.md" ] && ! head -1 "$repo/memory/CLAUDE.md" | grep -qx -- '---'; then
  _pass "memory/CLAUDE.md exists and has no frontmatter"
else
  _fail "memory/CLAUDE.md exists and has no frontmatter" "missing file, or it opens with ---"
fi

if grep -q '^name: ELI5-readable' "$repo/output-styles/eli5.md" 2>/dev/null; then
  _pass "the output style keeps the name ELI5-readable"
else
  _fail "the output style keeps the name ELI5-readable" "name line not found"
fi

finish
