#!/usr/bin/env bash
# PostToolUse hook: when a tool call just opened a pull request, tell Claude
# to run the pr-enrich skill, so the PR template gets filled in. Prints
# nothing for every other tool call.
# A call counts when the command or tool name creates a PR (gh, gflow, sflow,
# bflow, az, or an MCP create-pull-request tool) and its output holds a PR URL.
set -uo pipefail
command -v jq >/dev/null || exit 0

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
out=$(jq -r '.tool_response | tostring' <<<"$input")

creates='gh pr create|[gsb]flow (finish|bump|sync)|az repos pr create'
if [ "$tool" = "Bash" ]; then
  grep -qE "$creates" <<<"$cmd" || exit 0
else
  grep -qiE 'create_?pull_?request' <<<"$tool" || exit 0
fi
url=$(grep -oE 'https://[^"[:space:]]+/(pull|pullrequest)/[0-9]+' <<<"$out" | head -1)
[ -n "$url" ] || exit 0

msg="pr-enrich: a pull request was just created ($url). Run the ai:pr-enrich skill on it now: follow every instruction, checklist, and placeholder in its body, and find the linked work item."
jq -n --arg m "$msg" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
