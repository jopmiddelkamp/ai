#!/usr/bin/env bash
# The PostToolUse hook speaks only when a tool call just opened a pull request.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
hook="$repo/hooks/pr-created.sh"

run() { # tool command output
  jq -n --arg t "$1" --arg c "$2" --arg o "$3" \
    '{tool_name: $t, tool_input: {command: $c}, tool_response: {stdout: $o}}' | bash "$hook"
}

out=$(run Bash "gh pr create --fill" "https://github.com/o/r/pull/42")
assert_eq "https://github.com/o/r/pull/42" "$(jq -r '.hookSpecificOutput.additionalContext' <<<"$out" | grep -oE 'https://[^)]+')" "gh pr create with a PR URL triggers pr-enrich"
assert_eq "PostToolUse" "$(jq -r '.hookSpecificOutput.hookEventName' <<<"$out")" "the hook names its event"

out=$(run Bash "gflow finish --base develop --breaking=false" "PR: https://dev.azure.com/o/p/_git/r/pullrequest/7 (squash)")
assert_contains "$out" "pullrequest/7" "gflow finish with an Azure DevOps PR URL triggers pr-enrich"

out=$(run Bash "sflow finish --base develop" "https://github.com/stream-bv/shuttel-app/pull/5")
assert_contains "$out" "pull/5" "sflow finish triggers pr-enrich"

out=$(run Bash "bflow finish" "https://github.com/Beans-BV/beans-api/pull/490")
assert_contains "$out" "pull/490" "bflow finish triggers pr-enrich"

out=$(run Bash "sflow start feature/x" "https://github.com/stream-bv/shuttel-app/pull/5")
assert_eq "" "$out" "sflow start is silent"

out=$(run Bash "gh pr view 42" "https://github.com/o/r/pull/42")
assert_eq "" "$out" "viewing a PR is silent"

out=$(run Bash "gflow finish --base develop" "nothing to finish")
assert_eq "" "$out" "a PR command without a PR URL is silent"

out=$(run mcp__github__create_pull_request "" '{"html_url":"https://github.com/o/r/pull/9"}')
assert_contains "$out" "pull/9" "an MCP create-pull-request tool triggers pr-enrich"

out=$(run mcp__github__get_pull_request "" '{"html_url":"https://github.com/o/r/pull/9"}')
assert_eq "" "$out" "an MCP read tool is silent"

assert_eq "Bash|mcp__.*" "$(jq -r '.hooks.PostToolUse[0].matcher' "$repo/hooks/hooks.json")" "hooks.json registers the PR hook for Bash and MCP tools"

finish
