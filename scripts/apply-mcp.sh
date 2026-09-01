#!/usr/bin/env bash
# Render mcp/servers.json and merge it into the mcpServers key of ~/.claude.json.
# Secrets come from an env file that git never sees.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
ENV_FILE="${MCP_ENV_FILE:-$CLAUDE_DIR/mcp.env}"
TEMPLATE="$REPO_ROOT/mcp/servers.json"

DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: apply-mcp.sh [--dry-run]

  --dry-run  Show which variables are set and which are missing. Write nothing.

Environment:
  CLAUDE_JSON   Target file. Default: $HOME/.claude.json
  MCP_ENV_FILE  Secrets file. Default: $CLAUDE_DIR/mcp.env
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'apply-mcp.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || { printf 'apply-mcp.sh: jq is required.\n' >&2; exit 1; }
[ -f "$TEMPLATE" ] || { printf 'apply-mcp.sh: missing %s\n' "$TEMPLATE" >&2; exit 1; }

# Load the secrets file into the environment of this process only.
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

VARS=$(grep -oE '\$\{[A-Z0-9_]+\}' "$TEMPLATE" | tr -d '${}' | sort -u)

MISSING=""
for var in $VARS; do
  if [ -z "${!var:-}" ]; then MISSING="$MISSING $var"; fi
done

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'template: %s\n' "$TEMPLATE"
  printf 'env file: %s\n' "$ENV_FILE"
  printf 'target:   %s\n\n' "$CLAUDE_JSON"
  for var in $VARS; do
    if [ -z "${!var:-}" ]; then printf '  MISSING  %s\n' "$var"; else printf '  set      %s\n' "$var"; fi
  done
  printf '\nservers: %s\n' "$(jq -r 'keys | join(", ")' "$TEMPLATE")"
  exit 0
fi

if [ -n "$MISSING" ]; then
  printf 'apply-mcp.sh: no value for:%s\n' "$MISSING" >&2
  printf 'apply-mcp.sh: add each one to %s\n' "$ENV_FILE" >&2
  exit 1
fi

rendered=$(cat "$TEMPLATE")
for var in $VARS; do
  rendered=${rendered//\$\{$var\}/${!var}}
done

printf '%s' "$rendered" | jq empty 2>/dev/null || {
  printf 'apply-mcp.sh: the rendered template is not valid JSON.\n' >&2
  exit 1
}

[ -f "$CLAUDE_JSON" ] || printf '{}\n' >"$CLAUDE_JSON"

tmp="$CLAUDE_JSON.tmp.$$"
jq --argjson servers "$rendered" '.mcpServers = $servers' "$CLAUDE_JSON" >"$tmp"
jq empty "$tmp" 2>/dev/null || { rm -f "$tmp"; printf 'apply-mcp.sh: refusing to write invalid JSON.\n' >&2; exit 1; }

cp "$CLAUDE_JSON" "$CLAUDE_JSON.backup-$(date +%Y%m%d-%H%M%S)"
mv "$tmp" "$CLAUDE_JSON"

printf 'wrote %s servers to %s\n' "$(printf '%s' "$rendered" | jq -r 'length')" "$CLAUDE_JSON"
