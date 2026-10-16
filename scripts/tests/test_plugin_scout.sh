#!/usr/bin/env bash
# plugin-scout keeps a state file per repo. record.sh writes it and keeps it
# out of git, scan.sh reports what changed since, and the SessionStart hook
# speaks only when a run is due.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
scripts="$repo/skills/plugin-scout/scripts"
hook="$repo/hooks/plugin-scout-due.sh"
tmp=$(mktemp -d)
export HOME="$tmp/home"

# A fake plugin setup: one marketplace with two plugins, one installed.
mkdir -p "$HOME/.claude/plugins/marketplaces/m/.claude-plugin"
printf '{"m":{"installLocation":"%s"}}\n' "$HOME/.claude/plugins/marketplaces/m" >"$HOME/.claude/plugins/known_marketplaces.json"
printf '{"plugins":[{"name":"a","description":"A"},{"name":"b","lspServers":{"x":{"command":"x","extensionToLanguage":{".dart":"dart"}}}}]}\n' \
  >"$HOME/.claude/plugins/marketplaces/m/.claude-plugin/marketplace.json"
printf '{"plugins":{"a@m":[{"installPath":"%s"}]}}\n' "$tmp/none" >"$HOME/.claude/plugins/installed_plugins.json"

proj="$tmp/proj"
mkdir -p "$proj" && cd "$proj" && git init -q && echo x >a.ts && git add . &&
  git -c user.email=t@t -c user.name=t commit -qm init

out=$(echo '{"stack":[],"enabled":["a@m"],"declined":[]}' | bash "$scripts/record.sh" "$proj" 2>&1)
assert_rc 0 $? "record.sh saves a run"
assert_file "$proj/.claude/plugin-scout.json" "the state file is written"
assert_eq "a@m,b@m" "$(jq -r '.known_plugins | join(",")' "$proj/.claude/plugin-scout.json")" "the state lists the marketplace catalog"
git -C "$proj" check-ignore -q .claude/plugin-scout.json
assert_rc 0 $? "the state file is gitignored after the first run"
echo '{}' | bash "$scripts/record.sh" "$proj" >/dev/null 2>&1
assert_eq "1" "$(grep -c plugin-scout.json "$proj/.gitignore")" "a second run does not add the ignore line again"
echo 'not json' | bash "$scripts/record.sh" "$proj" >/dev/null 2>&1
assert_rc 1 $? "record.sh refuses input that is not JSON"

out=$(bash "$scripts/scan.sh" "$proj" 1 2>&1)
assert_contains "$out" "NOTHING NEW" "a scan right after a run finds nothing new"

out=$(CLAUDE_PROJECT_DIR="$proj" bash "$hook")
assert_eq "" "$out" "the hook is silent when the last run is recent"

echo 'void main() {}' >"$proj/main.dart" && git -C "$proj" add . &&
  git -C "$proj" -c user.email=t@t -c user.name=t commit -qm dart
out=$(bash "$scripts/scan.sh" "$proj" 1 2>&1)
assert_contains "$out" "Commits since: 1." "the scan counts commits since the last run"
assert_contains "$out" "New file types: dart." "the scan names new file types"
assert_contains "$out" '`b@m` for .dart' "the scan names an uninstalled language server for a repo file type"

jq '.last_run_epoch -= 8 * 86400' "$proj/.claude/plugin-scout.json" >"$tmp/s" && mv "$tmp/s" "$proj/.claude/plugin-scout.json"
out=$(CLAUDE_PROJECT_DIR="$proj" bash "$hook")
assert_contains "$out" "plugin-scout:" "the hook speaks when a week old run has new commits"

out=$(CLAUDE_PROJECT_DIR="$tmp" bash "$hook")
assert_eq "" "$out" "the hook is silent outside a scanned repo"

assert_eq "SessionStart" "$(jq -r '.hooks | keys[]' "$repo/hooks/hooks.json")" "hooks.json registers only the SessionStart hook"

cd / && rm -rf "$tmp"
finish
