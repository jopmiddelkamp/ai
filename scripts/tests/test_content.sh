#!/usr/bin/env bash
# Every stored skill must have the right shape, and no nested git repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

for s in bro pull-request-comment-style review-pr config-capture \
         business-coach research; do
  assert_file "$repo/skills/$s/SKILL.md" "skills/$s/SKILL.md exists"
  assert_eq "---" "$(head -1 "$repo/skills/$s/SKILL.md" 2>/dev/null)" "skills/$s/SKILL.md opens with frontmatter"
  if grep -qE '^name:[[:space:]]*'"$s"'[[:space:]]*$' "$repo/skills/$s/SKILL.md" 2>/dev/null; then
    _pass "skills/$s declares name: $s"
  else
    _fail "skills/$s declares name: $s" "frontmatter name does not match the directory"
  fi
  assert_no_file "$repo/skills/$s/.git" "skills/$s holds no nested git repo"
done

# The repo is a Claude Code plugin. Both manifests must exist, agree on the
# name, and point the plugin at skills/ only: commands/ and output-styles/ are
# linked by install.sh, so the plugin must not load them a second time.
pj="$repo/.claude-plugin/plugin.json"
mj="$repo/.claude-plugin/marketplace.json"
assert_file "$pj" ".claude-plugin/plugin.json exists"
assert_file "$mj" ".claude-plugin/marketplace.json exists"
if command -v jq >/dev/null 2>&1; then
  assert_eq "ai" "$(jq -r .name "$pj" 2>/dev/null)" "plugin.json is named ai"
  assert_eq "./skills/" "$(jq -r .skills "$pj" 2>/dev/null)" "plugin.json loads skills/"
  assert_eq "0" "$(jq -r '.commands | length' "$pj" 2>/dev/null)" "plugin.json loads no commands"
  assert_eq "0" "$(jq -r '.outputStyles | length' "$pj" 2>/dev/null)" "plugin.json loads no output styles"
  assert_eq "ai" "$(jq -r .name "$mj" 2>/dev/null)" "marketplace.json is named ai"
  assert_eq "ai" "$(jq -r '.plugins[0].name' "$mj" 2>/dev/null)" "marketplace.json lists the ai plugin"
  assert_eq "./" "$(jq -r '.plugins[0].source' "$mj" 2>/dev/null)" "marketplace.json points at the repo root"
fi
if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$repo" >/dev/null 2>&1
  assert_rc 0 $? "claude plugin validate passes"
fi

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
