# Claude setup inventory

What was custom on this machine on 2026-09-01, and where each item now lives.

## Skills

| Name | Source | In repo |
|---|---|---|
| `bro` | own | yes, `skills/bro` |
| `github-pr-comment` | own | yes, `skills/github-pr-comment` |
| `review-pr` | own | yes, `skills/review-pr` |
| `skill-sync-reminder` | own | yes, `skills/skill-sync-reminder` |
| `humanizer` | `blader/humanizer`, v2.9.1 | yes, `skills/humanizer`, listed in `sources.yaml` |
| `sync-upstream` | own, new | yes |
| `sync-mcp` | own, new | yes |
| `config-capture` | own, new | yes |

## Output styles

| Name | File | In repo |
|---|---|---|
| `ELI5-readable` | was `~/.claude/output-styles/ELI5.md` | yes, `output-styles/eli5.md` |

## Slash commands

| Name | In repo |
|---|---|
| `/bro` | yes, `commands/bro.md` |

`/bro` repeats the `bro` skill. Keep both: the command is the fast path, the
skill is the one an agent finds on its own.

## MCP servers

| Key | Transport | Secret | In repo |
|---|---|---|---|
| `pencil` | stdio, app bundle | no | yes |
| `moneybird-middelkamp-development` | http | yes | yes, as `${VAR}` |
| `moneybird-holding-42` | http | yes | yes, as `${VAR}` |
| `trello` | stdio, node | yes | yes, as `${VAR}` |
| `vercel-private` | http, OAuth | no | yes |
| `gbrain` | http | yes | yes, as `${VAR}` |
| `wispr-flow` | http, OAuth | no | yes |

Five MCP connectors still need an interactive login: Google Calendar, Google
Drive, Sentry, Slack, and Wispr Flow. Authorise them with `/mcp` in an
interactive session, or in the claude.ai connector settings.

## Scripts in `~/.claude`

| File | What it does | In repo |
|---|---|---|
| `statusline-command.sh` | status line styled after the robbyrussell zsh theme | yes, copy in `settings/machine/` |
| `shell-init.sh` | loads `.zshrc` and `.zprofile` into the bash tool | yes, copy in `settings/machine/` |

No script installs these two. `settings/claude-settings.json` points at them by
absolute path, so a rebuild copies them from `settings/machine/` into
`~/.claude/` by hand and runs `chmod +x` on the status line.

## Hooks

Every hook belongs to another app. See `hooks/README.md`.

| Owner | Script | Events |
|---|---|---|
| Pulser | `~/.pulser/hooks/pulser-hook.sh` | 7 |
| Pixel Agents | `~/.pixel-agents/hooks/claude-hook.js` | 12 |

## Plugins

5 marketplaces, 17 enabled plugins. Listed in `settings/plugins.md`.

## Excluded on purpose

| Item | Reason |
|---|---|
| `~/.claude/plugins/` cache | Claude Code downloads it |
| `~/.claude/projects/`, `sessions/`, `history.jsonl` | session data, not config |
| `~/.claude/backups/`, `file-history/`, `shell-snapshots/` | machine state |
| Third-party hooks | owned by Pulser and Pixel Agents |
| Every token | secrets never reach GitHub |

## Refreshing this document

Ask the agent to "capture what is not in the repo yet". The `config-capture`
skill finds new content and updates this table.
