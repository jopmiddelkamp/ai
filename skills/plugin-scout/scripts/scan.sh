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

# Trusted sources: marketplaces whose manifest names Anthropic as owner
# (Anthropic's own plugins and its partners'), Anthropic's plugin directory,
# and the user's own marketplaces in PLUGIN_SCOUT_OWN (default: ai gflow).
anthropic_mkts=$(jq -r 'to_entries[] | "\(.key)\t\(.value.installLocation)"' "$known" 2>/dev/null |
  while IFS=$'\t' read -r mkt loc; do
    [ "$(jq -r '.owner.name // ""' "$loc/.claude-plugin/marketplace.json" 2>/dev/null)" = Anthropic ] && echo "$mkt"
  done; echo anthropic-plugin-directory)
own_mkts=${PLUGIN_SCOUT_OWN:-ai gflow}
source_of() { # plugin id -> anthropic, own, or third-party
  local mkt=${1#*@}
  if grep -qxF "$mkt" <<<"$anthropic_mkts"; then echo anthropic
  elif [[ " $own_mkts " == *" $mkt "* ]]; then echo own
  else echo third-party; fi
}

# Every plugin in the Anthropic marketplaces: id, category, installed or not,
# LSP file extensions, description. Too long to print; the skill greps it.
# Third-party marketplaces are left out, so nothing from them is suggested.
catalog="${TMPDIR:-/tmp}/plugin-scout-catalog.tsv"
jq -r 'to_entries[] | "\(.key)\t\(.value.installLocation)"' "$known" 2>/dev/null |
while IFS=$'\t' read -r mkt loc; do
  grep -qxF "$mkt" <<<"$anthropic_mkts" || continue
  jq -r --arg m "$mkt" --slurpfile inst "$installed" '.plugins[]? | "\(.name)@\($m)" as $id |
    [ $id, (.category // "-"),
      (if ($inst[0].plugins | has($id)) then "installed" else "-" end),
      ([.lspServers // {} | .[] | .extensionToLanguage // {} | keys[]] | unique | join(",")),
      ((.description // "-") | gsub("\\s+"; " ") | .[0:160]) ] | @tsv' \
    "$loc/.claude-plugin/marketplace.json" 2>/dev/null
done | sort -u >"$catalog"

# File extensions in the repo, lower case, with how many files have each.
repo_exts=$(git -C "$project" ls-files 2>/dev/null | sed -n 's/^.*[^/]\.\([A-Za-z0-9]*\)$/\1/p' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn)

state="$project/.claude/plugin-scout.json"
if [ -f "$state" ]; then
  echo "# Since the last run"
  echo
  last=$(jq -r '.last_commit // ""' "$state")
  echo "Last run: $(jq -r .last_run "$state"), at commit ${last:0:12}."
  news=0
  if [ -n "$last" ] && git -C "$project" cat-file -e "$last" 2>/dev/null; then
    commits=$(git -C "$project" rev-list --count "$last"..HEAD)
  else
    commits=$(git -C "$project" rev-list --count --since="$(jq -r .last_run "$state")" HEAD 2>/dev/null || echo 0)
    last=$(git -C "$project" rev-list -n1 --before="$(jq -r .last_run "$state")" HEAD 2>/dev/null)
  fi
  echo "Commits since: $commits."
  if [ "$commits" -gt 0 ] && [ -n "$last" ]; then
    echo
    echo "## Files added or changed since (dependency and config files first)"
    echo
    git -C "$project" diff --name-status "$last" HEAD |
      awk '{print ($2 ~ /(package\.json|pubspec\.yaml|Cargo\.toml|go\.mod|composer\.json|\.csproj|Package\.swift|build\.gradle|requirements|pyproject|Gemfile|Dockerfile|\.ya?ml$|\.toml$)/ ? 0 : 1) "\t" $0}' |
      sort -k1,1 -s | cut -f2- | head -60
  fi
  new_exts=$(jq -r '.extensions[]?' "$state" | sort -u | comm -13 - <(awk '{print $2}' <<<"$repo_exts" | sort -u) | paste -sd, -)
  echo
  echo "New file types: ${new_exts:-none}."
  new_inst=$(jq -r '.installed[]?' "$state" | sort -u | comm -13 - <(jq -r '.plugins | keys[]' "$installed" | sort -u) | paste -sd, -)
  echo "Newly installed plugins: ${new_inst:-none}."
  new_cat=$(jq -r '.known_plugins[]?' "$state" | sort -u | comm -13 - <(cut -f1 "$catalog" | sort -u))
  echo "New plugins in your marketplaces: $(printf '%s' "$new_cat" | grep -c . || true)."
  if [ -n "$new_cat" ]; then
    grep -F -f <(printf '%s\n' "$new_cat") "$catalog" | awk -F'\t' '{print "- `" $1 "` (" $2 "): " $5}'
  fi
  [ "$commits" -gt 0 ] || [ -n "$new_exts" ] || [ -n "$new_inst" ] || [ -n "$new_cat" ] && news=1
  echo
  if [ "$news" -eq 0 ]; then
    echo "NOTHING NEW since the last run."
  else
    echo "CHANGES since the last run: check them against the stack below."
  fi
  echo
  echo "## Stack and plugins recorded last run"
  echo
  jq -r '.stack[]? | "- \(.tech) (\(.evidence)): \(.plugins | join(", "))"' "$state"
  echo "- enabled: $(jq -r '.enabled | join(", ")' "$state")"
  jq -r '.declined[]? | "- declined \(.plugin): \(.reason)"' "$state"
  echo
fi

echo "# Installed plugins"
echo
echo "source: anthropic (Anthropic or a partner), own (the user's), or"
echo "third-party (never recommend). user: the value in ~/.claude/settings.json."
echo "desc-chars: description"
echo "characters of skills, agents and commands, which load every session."
echo "Hooks on SessionStart or UserPromptSubmit can inject far more."
echo
printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
  plugin source user skills agents commands mcp hooks lsp desc-chars
echo '|---|---|---|---|---|---|---|---|---|---|'
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
  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$id" "$(source_of "$id")" "$user" "$ns" "$na" "$nc" "${mcp:--}" "${hooks:--}" "${lsp:--}" "$chars"
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

echo
echo "# Marketplace catalog"
echo
echo "$(wc -l <"$catalog" | tr -d ' ') plugins in $catalog"
echo "(columns: id, category, installed, LSP extensions, description)."
echo
echo "## Language servers for this repo's file types that are not installed"
echo
awk '{print $2}' <<<"$repo_exts" | head -15 | while read -r ext; do
  awk -F'\t' -v e="$ext" '$3 != "installed" && $4 != "" { n = split($4, xs, ","); for (i = 1; i <= n; i++) if (xs[i] == "." e) print "- `" $1 "` for ." e }' "$catalog"
done | sort -u

echo
echo "## Top file types in this repo"
echo
head -15 <<<"$repo_exts" | awk '{print "- ." $2 ": " $1 " files"}'

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
if [ -f "$state" ]; then
  # A repeat run reads only the sessions since the last one.
  files=$(find "$tdir" -maxdepth 1 -name '*.jsonl' -newer "$state" -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n "$sessions")
else
  files=$(ls -t "$tdir"/*.jsonl 2>/dev/null | head -n "$sessions")
fi
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
