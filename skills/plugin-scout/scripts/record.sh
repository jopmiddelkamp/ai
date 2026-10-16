#!/usr/bin/env bash
# Save a plugin-scout run so the next run can report only what changed.
# Reads the run's judgment as JSON on stdin:
#   {"stack": [{"tech", "evidence", "plugins": [...]}], "enabled": [...],
#    "declined": [{"plugin", "reason"}]}
# Adds the facts a script can collect itself (time, HEAD, file types,
# installed plugins, marketplace catalog) and writes .claude/plugin-scout.json.
# Usage: record.sh [project-dir] < judgment.json
set -uo pipefail

project=$(cd "${1:-$PWD}" && pwd)
plugins_dir="$HOME/.claude/plugins"
state="$project/.claude/plugin-scout.json"

command -v jq >/dev/null || { echo "record.sh needs jq" >&2; exit 1; }
judgment=$(cat)
jq -e 'type == "object"' >/dev/null 2>&1 <<<"$judgment" || { echo "stdin is not a JSON object" >&2; exit 1; }

head=$(git -C "$project" rev-parse HEAD 2>/dev/null || echo "")
extensions=$(git -C "$project" ls-files 2>/dev/null | sed -n 's/^.*[^/]\.\([A-Za-z0-9]*\)$/\1/p' |
  tr 'A-Z' 'a-z' | sort -u | jq -R . | jq -sc .)
installed=$(jq -c '.plugins | keys' "$plugins_dir/installed_plugins.json" 2>/dev/null || echo '[]')
catalog=$(jq -r 'to_entries[] | "\(.key)\t\(.value.installLocation)"' "$plugins_dir/known_marketplaces.json" 2>/dev/null |
  while IFS=$'\t' read -r mkt loc; do
    jq -r --arg m "$mkt" '.plugins[]?.name | "\(.)@\($m)"' "$loc/.claude-plugin/marketplace.json" 2>/dev/null
  done | sort -u | jq -R . | jq -sc .)

mkdir -p "$project/.claude"
jq -n \
  --argjson j "$judgment" \
  --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson epoch "$(date +%s)" \
  --arg head "$head" \
  --argjson extensions "${extensions:-[]}" \
  --argjson installed "$installed" \
  --argjson catalog "${catalog:-[]}" \
  '{version: 1, last_run: $now, last_run_epoch: $epoch, last_commit: $head,
    stack: ($j.stack // []), enabled: ($j.enabled // []), declined: ($j.declined // []),
    extensions: $extensions, installed: $installed, known_plugins: $catalog}' >"$state.tmp" &&
  mv "$state.tmp" "$state"

# The state is personal, like settings.local.json: keep it out of git.
if git -C "$project" rev-parse --git-dir >/dev/null 2>&1 &&
   ! git -C "$project" check-ignore -q .claude/plugin-scout.json; then
  gi="$project/.gitignore"
  [ -s "$gi" ] && [ -n "$(tail -c1 "$gi")" ] && echo >>"$gi"
  echo ".claude/plugin-scout.json" >>"$gi"
  echo "added .claude/plugin-scout.json to .gitignore"
fi
echo "saved $state"
