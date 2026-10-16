#!/usr/bin/env bash
# Collect the facts plugin-scout needs: what each installed plugin adds,
# what this project enables today, and what recent sessions here used.
# Usage: scan.sh [project-dir] [number-of-sessions]
set -uo pipefail

project=$(cd "${1:-$PWD}" && pwd)
sessions=${2:-30}
plugins_dir="$HOME/.claude/plugins"
installed="$plugins_dir/installed_plugins.json"

command -v jq >/dev/null || { echo "scan.sh needs jq" >&2; exit 1; }
[ -f "$installed" ] || { echo "no $installed; no plugins installed" >&2; exit 1; }

# Characters in the always-loaded descriptions of one component folder.
desc_chars() {
  local total=0 f n
  for f in "$@"; do
    [ -f "$f" ] || continue
    n=$(awk '/^---/{c++; next} c==1 && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$f" | wc -c)
    total=$((total + n))
  done
  echo "$total"
}

known="$plugins_dir/known_marketplaces.json"
settings="$HOME/.claude/settings.json"

# A plugin's metadata may sit in its own plugin.json or in its entry in the
# marketplace manifest (LSP plugins keep everything there). Merge both.
meta() {
  local id=$1 path=$2 name=${1%@*} mkt=${1#*@} loc entry='{}' own='{}'
  loc=$(jq -r --arg m "$mkt" '.[$m].installLocation // empty' "$known" 2>/dev/null)
  [ -f "$loc/.claude-plugin/marketplace.json" ] &&
    entry=$(jq -c --arg n "$name" '[.plugins[]? | select(.name==$n)][0] // {}' "$loc/.claude-plugin/marketplace.json")
  [ -f "$path/.claude-plugin/plugin.json" ] && own=$(jq -c . "$path/.claude-plugin/plugin.json")
  jq -cn --argjson a "$entry" --argjson b "$own" '$a * $b'
}

echo "# Installed plugins"
echo
echo "user: the value in ~/.claude/settings.json. desc-chars: description"
echo "characters of skills, agents and commands, which load every session."
echo "Hooks on SessionStart or UserPromptSubmit can inject far more."
echo
printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  plugin user skills agents commands mcp hooks lsp desc-chars
echo '|---|---|---|---|---|---|---|---|---|'
rows=$(jq -r '.plugins | to_entries[] | "\(.key)\t\(.value[0].installPath)"' "$installed" | sort)
while IFS=$'\t' read -r id path; do
  [ -d "$path" ] || continue
  m=$(meta "$id" "$path")
  user=$(jq -r --arg id "$id" '.enabledPlugins // {} | if has($id) then .[$id] | tostring else "unset" end' "$settings" 2>/dev/null)
  skills=("$path"/skills/*/SKILL.md)
  agents=("$path"/agents/*.md)
  commands=("$path"/commands/*.md)
  ns=0; [ -f "${skills[0]}" ] && ns=${#skills[@]}
  na=0; [ -f "${agents[0]}" ] && na=${#agents[@]}
  nc=0; [ -f "${commands[0]}" ] && nc=${#commands[@]}
  mcp=$( { [ -f "$path/.mcp.json" ] && jq -r '(.mcpServers // .) | keys[]' "$path/.mcp.json"
           jq -r '.mcpServers | objects | keys[]' <<<"$m"; } 2>/dev/null | sort -u | paste -sd, -)
  hooks=$( { [ -f "$path/hooks/hooks.json" ] && jq -r '(.hooks // .) | keys[]' "$path/hooks/hooks.json"
             jq -r '.hooks | objects | keys[]' <<<"$m"; } 2>/dev/null | sort -u | paste -sd, -)
  # Name the LSP binary and whether it is on PATH: without it the plugin does nothing.
  lsp=$( { [ -f "$path/.lsp.json" ] && jq -c . "$path/.lsp.json"; jq -c '.lspServers // empty' <<<"$m"; } 2>/dev/null |
    jq -r 'to_entries[] | .value.command' 2>/dev/null | sort -u |
    while read -r bin; do
      if command -v "$bin" >/dev/null; then echo "$bin"; else echo "$bin(missing)"; fi
    done | paste -sd, -)
  chars=$(desc_chars "${skills[@]}" "${agents[@]}" "${commands[@]}")
  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$id" "$user" "$ns" "$na" "$nc" "${mcp:--}" "${hooks:--}" "${lsp:--}" "$chars"
done <<<"$rows"

echo
echo "# What each plugin is for"
echo
while IFS=$'\t' read -r id path; do
  [ -d "$path" ] || continue
  d=$(meta "$id" "$path" | jq -r '.description // "-"' | tr '\n' ' ' | cut -c1-200)
  echo "- \`$id\`: $d"
  names=$(for s in "$path"/skills/*/SKILL.md "$path"/agents/*.md "$path"/commands/*.md; do
    [ -f "$s" ] || continue
    if [ "$(basename "$s")" = SKILL.md ]; then basename "$(dirname "$s")"; else basename "$s" .md; fi
  done | paste -sd, - | sed 's/,/, /g')
  [ -n "$names" ] && echo "  - components: $names"
done <<<"$rows"

echo
echo "# This project's settings"
echo
for f in "$project/.claude/settings.json" "$project/.claude/settings.local.json"; do
  if [ -f "$f" ]; then
    echo "${f#"$project"/}: $(jq -c '.enabledPlugins // {}' "$f")"
  else
    echo "${f#"$project"/}: missing"
  fi
done

# Claude Code stores transcripts under the project path with every
# non-alphanumeric character turned into a dash.
tdir="$HOME/.claude/projects/$(printf '%s' "$project" | sed 's/[^A-Za-z0-9]/-/g')"
echo
echo "# Usage in the last $sessions sessions"
echo
if [ ! -d "$tdir" ]; then
  echo "No transcripts at $tdir."
  exit 0
fi
files=$(ls -t "$tdir"/*.jsonl 2>/dev/null | head -n "$sessions")
if [ -z "$files" ]; then
  echo "No transcripts at $tdir."
  exit 0
fi
echo "Read $(echo "$files" | wc -l | tr -d ' ') sessions from $tdir."
echo
echo "## Plugin components called (count, name)"
echo
# Plugin skills and agents are named plugin:name; plugin MCP tools are
# named mcp__plugin_<plugin>_<server>__<tool>.
echo "$files" | tr '\n' '\0' | xargs -0 jq -r '
  select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") |
  if .name=="Skill" then "skill " + (.input.skill // "?")
  elif .name=="Agent" or .name=="Task" then "agent " + (.input.subagent_type // "general-purpose")
  elif (.name|startswith("mcp__")) then "mcp " + (.name|split("__")[1])
  else empty end' 2>/dev/null | sort | uniq -c | sort -rn | head -40

echo
echo "## Slash commands typed"
echo
echo "$files" | tr '\n' '\0' | xargs -0 jq -r '
  select(.type=="user") | .message.content |
  (if type=="string" then . else ([.[]? | select(.type=="text") | .text] | join(" ")) end) |
  scan("<command-name>/?([^<]+)</command-name>")[0]' 2>/dev/null | sort | uniq -c | sort -rn | head -20

echo
echo "## What the user asked (first 160 characters of each prompt)"
echo
echo "$files" | tr '\n' '\0' | xargs -0 jq -r '
  select(.type=="user" and (.isMeta|not)) | .message.content |
  (if type=="string" then . else ([.[]? | select(.type=="text") | .text] | join(" ")) end) |
  select((startswith("<task-notification") or startswith("[Request interrupted")) | not) |
  gsub("<[^>]+>[^<]*</[^>]+>"; "") | gsub("\\s+"; " ") | ltrimstr(" ") |
  select(length > 15) | .[0:160]' 2>/dev/null | head -80 | sed 's/^/- /'
