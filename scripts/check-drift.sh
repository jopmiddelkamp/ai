#!/usr/bin/env bash
# Report every difference between this repo and the machine.
# Not `set -e`: the script must list all drift, not stop at the first item.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
TEMPLATE="$REPO_ROOT/mcp/servers.json"

case "${1:-}" in
  "") ;;
  -h|--help) printf 'Usage: check-drift.sh\n\nReports differences between the repo and %s.\n' "$CLAUDE_DIR"; exit 0 ;;
  *) printf 'check-drift.sh: unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

DRIFT=0
note() { printf '  %s\n' "$1"; DRIFT=$((DRIFT + 1)); }

printf 'repo:    %s\n' "$REPO_ROOT"
printf 'machine: %s\n\n' "$CLAUDE_DIR"

# 1. The global memory must be a link back to this repo.
printf 'memory\n'
if [ ! -e "$CLAUDE_DIR/CLAUDE.md" ]; then
  note "missing: CLAUDE.md"
elif [ "$(readlink "$CLAUDE_DIR/CLAUDE.md")" != "$REPO_ROOT/memory/CLAUDE.md" ]; then
  note "not linked to the repo: CLAUDE.md; run scripts/install.sh --force"
fi

# 2. MCP servers.
printf '\nMCP servers\n'
if command -v jq >/dev/null 2>&1 && [ -f "$TEMPLATE" ] && [ -f "$CLAUDE_JSON" ]; then
  repo_keys=$(jq -r 'keys[]' "$TEMPLATE" | sort)
  live_keys=$(jq -r '.mcpServers // {} | keys[]' "$CLAUDE_JSON" | sort)
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$live_keys" | grep -qxF "$k" || note "missing on machine: $k"
  done <<EOF
$repo_keys
EOF
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$repo_keys" | grep -qxF "$k" || note "not in repo: $k"
  done <<EOF
$live_keys
EOF

  # A server can be present on both sides and still have drifted. Compare the
  # three fields that never hold a secret, so this stays safe to print.
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$live_keys" | grep -qxF "$k" || continue
    for field in type url command; do
      rv=$(jq -r --arg k "$k" --arg f "$field" '.[$k][$f] // "-"' "$TEMPLATE")
      # A field holding a ${VAR} cannot be compared. The machine has the
      # rendered value and the repo has the placeholder, so they always differ
      # and a correct machine would report permanent false drift.
      case "$rv" in *'${'*) continue ;; esac
      lv=$(jq -r --arg k "$k" --arg f "$field" '.mcpServers[$k][$f] // "-"' "$CLAUDE_JSON")
      [ "$rv" = "$lv" ] || note "$k: $field differs (repo: $rv, machine: $lv)"
    done
  done <<EOF
$repo_keys
EOF
else
  note "cannot compare MCP servers: jq, the template, or $CLAUDE_JSON is missing"
fi

# 3. The plugin that delivers skills/ and output-styles/.
printf '\nplugin\n'
INSTALLED="$CLAUDE_DIR/plugins/installed_plugins.json"
if command -v jq >/dev/null 2>&1 && [ -f "$INSTALLED" ]; then
  if ! jq -e '.plugins["ai@ai"]' "$INSTALLED" >/dev/null 2>&1; then
    note "plugin ai@ai is not installed; run: claude plugin marketplace add jopmiddelkamp/ai && claude plugin install ai@ai"
  fi
else
  note "no plugin registry at $INSTALLED; run: claude plugin marketplace add jopmiddelkamp/ai && claude plugin install ai@ai"
fi

printf '\n'
if [ "$DRIFT" -eq 0 ]; then
  printf 'in sync\n'
  exit 0
fi
printf '%s difference(s) found\n' "$DRIFT"
exit 1
