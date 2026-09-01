#!/usr/bin/env bash
# Render mcp/servers.json and merge it into the mcpServers key of ~/.claude.json.
# Secrets come from an env file that git never sees.
set -euo pipefail

# Everything this script writes can hold a credential.
umask 077

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
  CLAUDE_DIR    Base directory. Default: $HOME/.claude
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

# Check the target before touching it. Without this, a target that is already
# corrupt makes the jq call below fail under `set -e`, which aborts the script
# with jq's own exit code and leaves an empty temp file next to the user's
# config forever.
if ! jq empty "$CLAUDE_JSON" 2>/dev/null; then
  printf 'apply-mcp.sh: %s is not valid JSON. Refusing to touch it.\n' "$CLAUDE_JSON" >&2
  printf 'apply-mcp.sh: restore it from a .backup- copy first.\n' >&2
  exit 1
fi

tmp="$CLAUDE_JSON.tmp.$$"
# Clean the temp file up on every exit path, including an abort under `set -e`.
trap 'rm -f "$tmp"' EXIT
jq --argjson servers "$rendered" '.mcpServers = $servers' "$CLAUDE_JSON" >"$tmp"
jq empty "$tmp" 2>/dev/null || { printf 'apply-mcp.sh: refusing to write invalid JSON.\n' >&2; exit 1; }

# This file holds live bearer tokens. A plain redirect creates the temp file at
# 0644 under the default umask, and the mv then carries that mode onto the
# target, quietly making every token world-readable. Pin the mode explicitly on
# both the replacement and the backup.
backup="$CLAUDE_JSON.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CLAUDE_JSON" "$backup"
chmod 600 "$backup"
chmod 600 "$tmp"
mv "$tmp" "$CLAUDE_JSON"

printf 'wrote %s servers to %s\n' "$(printf '%s' "$rendered" | jq -r 'length')" "$CLAUDE_JSON"
