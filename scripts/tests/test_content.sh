#!/usr/bin/env bash
# Every stored skill must have the right shape, and no nested git repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

for s in bro brief deepen pull-request-comment-style review-pr \
         business-coach research writing-readable-code \
         compliance dry-principles kiss-principles owasp solid-principles; do
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
# name, and let the plugin load skills/ and output-styles/. Leaving out the
# outputStyles key keeps the default output-styles/ scan.
pj="$repo/.claude-plugin/plugin.json"
mj="$repo/.claude-plugin/marketplace.json"
assert_file "$pj" ".claude-plugin/plugin.json exists"
assert_file "$mj" ".claude-plugin/marketplace.json exists"
if command -v jq >/dev/null 2>&1; then
  assert_eq "ai" "$(jq -r .name "$pj" 2>/dev/null)" "plugin.json is named ai"
  assert_eq "./skills/" "$(jq -r .skills "$pj" 2>/dev/null)" "plugin.json loads skills/"
  assert_eq "false" "$(jq -r 'has("outputStyles")' "$pj" 2>/dev/null)" "plugin.json keeps the default output-styles/ scan"
  assert_eq "ai" "$(jq -r .name "$mj" 2>/dev/null)" "marketplace.json is named ai"
  assert_eq "ai" "$(jq -r '.plugins[0].name' "$mj" 2>/dev/null)" "marketplace.json lists the ai plugin"
  assert_eq "./" "$(jq -r '.plugins[0].source' "$mj" 2>/dev/null)" "marketplace.json points at the repo root"
fi
if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$repo" >/dev/null 2>&1
  assert_rc 0 $? "claude plugin validate passes"
fi

# The inventory lists exactly the skills in skills/, so the list cannot go
# stale. The README and the manifests name no skills and give no count.
inv="$repo/docs/claude-inventory.md"
on_disk=$(cd "$repo/skills" && ls -d */ | tr -d / | sort)
listed=$(sed -n 's/^| `\([^`]*\)` | own | yes, `skills\/.*$/\1/p' "$inv" | sort)
assert_eq "$on_disk" "$listed" "docs/claude-inventory.md lists every skill in skills/"
if grep -qE '[0-9]+ skills' "$repo/README.md"; then
  _fail "README.md gives no skill count" "a count goes stale; link the inventory instead"
else
  _pass "README.md gives no skill count"
fi

assert_file "$repo/output-styles/eli5.md" "output-styles/eli5.md exists"

# web-prefs.sh pastes memory/CLAUDE.md as-is, so it must not open with a
# frontmatter fence.
if [ -f "$repo/memory/CLAUDE.md" ] && ! head -1 "$repo/memory/CLAUDE.md" | grep -qx -- '---'; then
  _pass "memory/CLAUDE.md exists and has no frontmatter"
else
  _fail "memory/CLAUDE.md exists and has no frontmatter" "missing file, or it opens with ---"
fi

if grep -qx 'name: eli5' "$repo/output-styles/eli5.md" 2>/dev/null; then
  _pass "the output style keeps the name eli5"
else
  _fail "the output style keeps the name eli5" "name line not found"
fi

finish
