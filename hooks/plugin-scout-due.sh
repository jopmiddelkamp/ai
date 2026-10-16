#!/usr/bin/env bash
# SessionStart hook: say so when a repo's plugin-scout run is due. Prints
# nothing, so costs no context, except in two cases:
# - a git repo that was never scanned: once per repo, remembered in
#   ~/.claude/plugin-scout/nudged.txt;
# - a scanned repo whose last run is older than PLUGIN_SCOUT_DAYS (default 7)
#   and that changed since: new commits, or a marketplace that refreshed.
set -uo pipefail

dir=${CLAUDE_PROJECT_DIR:-$PWD}
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
state="$root/.claude/plugin-scout.json"
if [ ! -f "$state" ]; then
  nudged="$HOME/.claude/plugin-scout/nudged.txt"
  grep -qxF "$root" "$nudged" 2>/dev/null && exit 0
  mkdir -p "$(dirname "$nudged")" && echo "$root" >>"$nudged"
  echo "plugin-scout: this repo has no plugin check yet. Tell the user in one line that they can type /ai:plugin-scout to pick the plugins to enable here; you cannot run it for them. This reminder shows once per repo."
  exit 0
fi
command -v jq >/dev/null || exit 0

days=${PLUGIN_SCOUT_DAYS:-7}
last=$(jq -r '.last_run_epoch // 0' "$state" 2>/dev/null)
age=$(( ($(date +%s) - ${last:-0}) / 86400 ))
[ "$age" -ge "$days" ] || exit 0

commit=$(jq -r '.last_commit // ""' "$state")
commits=0
[ -n "$commit" ] && commits=$(git -C "$root" rev-list --count "$commit"..HEAD 2>/dev/null || echo 0)
fresh=$(find "$HOME/.claude/plugins/marketplaces" -maxdepth 3 -name marketplace.json -newer "$state" 2>/dev/null | head -1)
[ "$commits" -gt 0 ] || [ -n "$fresh" ] || exit 0

why="$commits new commits"
[ -n "$fresh" ] && why="$why, refreshed marketplaces"
echo "plugin-scout: the last plugin check for this repo was $age days ago ($why). Tell the user in one line that they can type /ai:plugin-scout to check for new plugins; you cannot run it for them."
