# Hooks

This repo is the `ai` plugin, so `hooks/hooks.json` here is the plugin's hook
file. Claude Code runs it in every session where `ai@ai` is enabled.

| Hook | Event | What it does |
|---|---|---|
| `plugin-scout-due.sh` | `SessionStart` (startup) | Prints one line when a repo's last `plugin-scout` run is 7+ days old (`PLUGIN_SCOUT_DAYS`) and the repo has new commits or a marketplace has refreshed since. In a git repo that was never scanned, it suggests a first run once, remembered in `~/.claude/plugin-scout/nudged.txt`. Prints nothing otherwise. |

The other hooks in `~/.claude/settings.json` belong to other apps:

- `~/.pulser/hooks/pulser-hook.sh` — see [../integrations/pulser.md](../integrations/pulser.md)
- `~/.pixel-agents/hooks/claude-hook.js` — not tracked, by choice

## Adding a hook

1. Write the script here, for example `hooks/my-hook.sh`, and make it
   executable: `chmod +x hooks/my-hook.sh`.
2. Add it to `hooks/hooks.json`, with the command
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh"`.
3. Keep `SessionStart` and `UserPromptSubmit` hooks silent by default: what
   they print goes into the context of every session.
