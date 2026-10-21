#!/usr/bin/env bash
# eval-with-plugins.sh copies eval cases and loads named plugins next to the
# ai plugin. --build-only builds the copies without a paid eval run.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/eval-with-plugins.sh"

if ! command -v jq >/dev/null 2>&1; then
  _pass "jq is missing, so the eval-with-plugins checks are skipped"
  finish
fi

home=$(make_fake_home)
fake="$home/.claude/plugins/cache/fake/fake/1.0.0"
mkdir -p "$fake/.claude-plugin"
printf '{"name":"fake"}\n' >"$fake/.claude-plugin/plugin.json"
printf '{"plugins":{"fake@market":[{"scope":"user","installPath":"%s"}]}}\n' "$fake" \
  >"$home/.claude/plugins/installed_plugins.json"
out="$home/out"

# --- case 1: a build copies the case and loads both plugins ---
CLAUDE_DIR="$home/.claude" bash "$script" --build-only "$out" 'prcs-suggestion' fake@market >/dev/null 2>&1
assert_rc 0 $? "a build succeeds"
case_dir="$out/prcs-suggestion"
prompt=$(cat "$case_dir/prompt.md" 2>/dev/null)
assert_contains "$prompt" 'plugins: ["ai-plugin", "fake-plugin"]' "the case loads the ai plugin and the named plugin"
want=$(( $(sed -n 's/^max_turns: //p' "$repo/evals/prcs-suggestion/prompt.md") + 2 ))
assert_contains "$prompt" "max_turns: $want" "max_turns rises by 2 per named plugin"
assert_file "$case_dir/ai-plugin/skills/pr-comment-style/SKILL.md" "the ai plugin holds the skills"
assert_file "$case_dir/ai-plugin/output-styles/eli5.md" "the ai plugin holds the output style"
assert_file "$case_dir/fake-plugin/.claude-plugin/plugin.json" "the named plugin is copied"
assert_contains "$(cat "$case_dir/graders/fake-fired.md" 2>/dev/null)" '"fake:' "a grader checks that a skill of the named plugin ran"

# --- case 2: a plugin that is not installed stops the build ---
CLAUDE_DIR="$home/.claude" bash "$script" --build-only "$out" 'prcs-suggestion' missing@market >/dev/null 2>&1
assert_rc 1 $? "a plugin that is not installed stops the build"

# --- case 3: a glob that matches no case stops the build ---
CLAUDE_DIR="$home/.claude" bash "$script" --build-only "$out" 'no-such-case-*' fake@market >/dev/null 2>&1
assert_rc 1 $? "a glob with no match stops the build"

rm -rf "$home"
finish
