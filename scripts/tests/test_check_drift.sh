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
rm -f "$home/.claude/commands/bro.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a removed link is drift"
assert_contains "$out" "commands/bro.md" "the report names the missing path"

# Add an untracked skill.
mkdir -p "$home/.claude/skills/mystery"
printf -- '---\nname: mystery\n---\n' >"$home/.claude/skills/mystery/SKILL.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
assert_contains "$out" "mystery" "the report names an untracked skill"

# Remove a server from the machine.
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
jq 'del(.mcpServers.gbrain)' "$home/.claude.json" >"$home/x" && mv "$home/x" "$home/.claude.json"
rm -rf "$home/.claude/skills/mystery"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a missing MCP server is drift"
assert_contains "$out" "gbrain" "the report names the missing server"

rm -rf "$home" "$good_env"
finish
