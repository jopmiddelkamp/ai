#!/usr/bin/env bash
# Report every difference between this repo and the machine.
# Not `set -e`: the script must list all drift, not stop at the first item.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
MANIFEST="$CLAUDE_DIR/.ai-repo-manifest"
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

# 1. Everything the repo holds must be installed and point back here.
printf 'installed content\n'
for d in "$REPO_ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  rel="skills/$(basename "${d%/}")"
  dest="$CLAUDE_DIR/$rel"
  if [ ! -e "$dest" ]; then note "missing: $rel"
  elif [ -L "$dest" ] && [ "$(readlink "$dest")" != "${d%/}" ]; then note "wrong target: $rel"
  fi
done
for f in "$REPO_ROOT"/output-styles/*.md "$REPO_ROOT"/commands/*.md; do
  [ -f "$f" ] || continue
  case "$f" in
    */output-styles/*) rel="output-styles/$(basename "$f")" ;;
    *) rel="commands/$(basename "$f")" ;;
  esac
  dest="$CLAUDE_DIR/$rel"
  if [ ! -e "$dest" ]; then note "missing: $rel"
  elif [ -L "$dest" ] && [ "$(readlink "$dest")" != "$f" ]; then note "wrong target: $rel"
  fi
done

# 2. Content on the machine that the repo does not track.
printf '\nuntracked content\n'
for sub in skills output-styles commands; do
  [ -d "$CLAUDE_DIR/$sub" ] || continue
  for e in "$CLAUDE_DIR/$sub"/*; do
    [ -e "$e" ] || continue
    name=$(basename "$e")
    case "$name" in .*) continue ;; esac
    rel="$sub/$name"
    if [ ! -e "$REPO_ROOT/$rel" ]; then note "not in repo: $rel"; fi
  done
done

# 3. MCP servers.
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
else
  note "cannot compare MCP servers: jq, the template, or $CLAUDE_JSON is missing"
fi

# 4. The manifest itself.
printf '\nmanifest\n'
if [ -f "$MANIFEST" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -e "$CLAUDE_DIR/$rel" ] || note "manifest lists a path that is gone: $rel"
  done <"$MANIFEST"
else
  note "no manifest at $MANIFEST; run scripts/install.sh"
fi

printf '\n'
if [ "$DRIFT" -eq 0 ]; then
  printf 'in sync\n'
  exit 0
fi
printf '%s difference(s) found\n' "$DRIFT"
exit 1
