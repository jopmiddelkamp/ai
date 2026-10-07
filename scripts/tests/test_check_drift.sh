#!/usr/bin/env bash
# check-drift.sh reports a machine that no longer matches the repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
drift="$repo/scripts/check-drift.sh"
install="$repo/scripts/install.sh"
apply="$repo/scripts/apply-mcp.sh"
template="$repo/mcp/servers.json"

good_env=$(mktemp)
for v in $(grep -oE '\$\{[A-Z0-9_]+\}' "$template" | tr -d '${}' | sort -u); do
  printf '%s=test-%s\n' "$v" "$v" >>"$good_env"
done

home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$apply" >/dev/null 2>&1

CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" >/dev/null 2>&1
assert_rc 0 $? "a freshly installed machine reports no drift"

# Break one link.
rm -f "$home/.claude/CLAUDE.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a removed link is drift"
assert_contains "$out" "missing: CLAUDE.md" "the report names the missing path"

# Remove a server from the machine.
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
jq 'del(.mcpServers.gbrain)' "$home/.claude.json" >"$home/x" && mv "$home/x" "$home/.claude.json"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a missing MCP server is drift"
assert_contains "$out" "gbrain" "the report names the missing server"

# Reinstall to a clean, in-sync baseline before testing content mismatches.
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$apply" >/dev/null 2>&1
CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" >/dev/null 2>&1
assert_rc 0 $? "a reinstalled machine is back in sync"

# Replace the link with a real file.
rm -f "$home/.claude/CLAUDE.md"
printf 'not the real content\n' >"$home/.claude/CLAUDE.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a real file in place of the link is drift"
assert_contains "$out" "not linked to the repo" "the report calls out the missing link"
CLAUDE_DIR="$home/.claude" bash "$install" --force >/dev/null 2>&1

# Change one server's url on the machine while everything else stays in sync.
jq '.mcpServers.gbrain.url = "https://example.invalid/mcp"' "$home/.claude.json" >"$home/x" && mv "$home/x" "$home/.claude.json"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a changed server url is drift"
assert_contains "$out" "gbrain" "the report names the server with the changed field"
assert_contains "$out" "url" "the report names the changed field"

# Take the plugin registry away. The plugin delivers skills, so its absence is
# drift even when every link is in place.
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$apply" >/dev/null 2>&1
rm -f "$home/.claude/plugins/installed_plugins.json"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a missing plugin registry is drift"
assert_contains "$out" "ai@ai" "the report names the plugin"

rm -rf "$home" "$good_env"
finish
