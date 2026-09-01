# Hooks

This folder is empty on purpose. The owner writes no hooks of their own today.

Every hook in `~/.claude/settings.json` belongs to another app:

- `~/.pulser/hooks/pulser-hook.sh` — see [../integrations/pulser.md](../integrations/pulser.md)
- `~/.pixel-agents/hooks/claude-hook.js` — not tracked, by choice

## Adding a hook of your own

1. Write the script here, for example `hooks/my-hook.sh`.
2. Make it executable: `chmod +x hooks/my-hook.sh`.
3. Add the entry to `~/.claude/settings.json` by hand, pointing at the repo
   path. `scripts/install.sh` does not touch `settings.json`.
4. Refresh the reference copy: `cp ~/.claude/settings.json settings/claude-settings.json`.
