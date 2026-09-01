#!/usr/bin/env bash
# apply-mcp.sh renders the template and merges it into .claude.json.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/apply-mcp.sh"
template="$repo/mcp/servers.json"

vars=$(grep -oE '\$\{[A-Z0-9_]+\}' "$template" | tr -d '${}' | sort -u)

good_env=$(mktemp)
for v in $vars; do printf '%s=test-%s\n' "$v" "$v" >>"$good_env"; done

# --- case 1: a full env file renders everything ---
home=$(make_fake_home)
printf '{"numStartups":42}\n' >"$home/.claude.json"
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$script" >/dev/null 2>&1
assert_rc 0 $? "apply succeeds with a full env file"
assert_eq "42" "$(jq -r '.numStartups' "$home/.claude.json")" "unrelated keys survive"
assert_eq "Bearer test-GBRAIN_TOKEN" \
  "$(jq -r '.mcpServers.gbrain.headers.Authorization' "$home/.claude.json")" \
  "the gbrain token is substituted"
assert_eq "test-TRELLO_MCP_PATH" \
  "$(jq -r '.mcpServers.trello.args[0]' "$home/.claude.json")" \
  "the trello path is substituted"
if grep -q '${' "$home/.claude.json"; then
  _fail "no placeholder survives" "found a \${ in the result"
else
  _pass "no placeholder survives"
fi
assert_eq "7" "$(jq -r '.mcpServers | length' "$home/.claude.json")" "all seven servers are written"

# --- case 2: a missing variable aborts and names it ---
bad_env=$(mktemp)
grep -v '^GBRAIN_TOKEN=' "$good_env" >"$bad_env"
out=$(GBRAIN_TOKEN= CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$bad_env" bash "$script" 2>&1)
rc=$?
assert_rc 1 $rc "a missing variable aborts"
assert_contains "$out" "GBRAIN_TOKEN" "the error names the missing variable"

# --- case 3: --dry-run changes nothing ---
printf '{"numStartups":7}\n' >"$home/.claude.json"
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$script" --dry-run >/dev/null 2>&1
assert_rc 0 $? "--dry-run succeeds"
assert_eq "null" "$(jq -r '.mcpServers' "$home/.claude.json")" "--dry-run writes no servers"

rm -rf "$home" "$good_env" "$bad_env"
finish
