# Settings

`claude-settings.json` is a **reference copy** of `~/.claude/settings.json`.

No script writes it back. The live file holds hook entries owned by other apps,
such as Pulser and Pixel Agents. Overwriting it would break them.

Use this copy to rebuild a machine by hand, or to see what changed:

```bash
diff <(jq -S . settings/claude-settings.json) <(jq -S . ~/.claude/settings.json)
```

## The settings that matter

| Key | Value | Why |
|---|---|---|
| `model` | `opus[1m]` | the default model |
| `effort` / `effortLevel` | `max` | maximum reasoning effort |
| `outputStyle` | `ELI5-readable` | comes from `output-styles/eli5.md` in this repo |
| `permissions.defaultMode` | `auto` | fewer prompts |
| `tui` | `fullscreen` | full screen terminal interface |
| `statusLine.command` | `bash ~/.claude/statusline-command.sh` | the custom status line |
| `env.CLAUDE_ENV_FILE` | `~/.claude/shell-init.sh` | loads the zsh config into the bash tool |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | turns on agent teams |

## The two machine scripts

`settings/machine/` holds copies of `~/.claude/statusline-command.sh` and
`~/.claude/shell-init.sh`, because `claude-settings.json` names both by
absolute path. No script installs them. On a new machine:

```bash
cp settings/machine/statusline-command.sh ~/.claude/
cp settings/machine/shell-init.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
```

## Refreshing this copy

```bash
cp ~/.claude/settings.json settings/claude-settings.json
cp ~/.claude/statusline-command.sh settings/machine/statusline-command.sh
cp ~/.claude/shell-init.sh settings/machine/shell-init.sh
bash scripts/check-secrets.sh settings/claude-settings.json
git add settings/claude-settings.json && git commit -m "chore: refresh the settings reference"
```
