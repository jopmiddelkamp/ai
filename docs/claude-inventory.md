# Claude setup inventory

What was custom on this machine on 2026-09-01, and where each item now lives.

## Skills

Claude Code loads these through the `ai@ai` plugin, which is this repo. They
are not symlinked into `~/.claude/skills`.

| Name | Source | In repo |
|---|---|---|
| `bro` | own | yes, `skills/bro` |
| `pull-request-comment-style` | own | yes, `skills/pull-request-comment-style` |
| `review-pr` | own | yes, `skills/review-pr` |
| `research` | own | yes, `skills/research` |
| `business-coach` | own | yes, `skills/business-coach` |

Removed on 2026-09-10: `sync-upstream` and `sync-mcp` (nothing is copied from
other repos any more; other people's skills are plugins) and
`skill-sync-reminder` (replaced by `scripts/web-skills.sh`).

Removed on 2026-10-07: `config-capture`.

## Output styles

| Name | File | In repo |
|---|---|---|
| `eli5` (named `ELI5-readable` until 2026-10-07) | was `~/.claude/output-styles/ELI5.md` | yes, `output-styles/eli5.md`; the `ai@ai` plugin loads it as `ai:eli5` |

## Slash commands

None. `commands/bro.md` was removed on 2026-10-07. The `bro` skill still
triggers on `/bro`.

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

7 marketplaces, 19 enabled plugins. Listed in `settings/plugins.md`. One of
them, `ai@ai`, is this repo.

## Excluded on purpose

| Item | Reason |
|---|---|
| `~/.claude/plugins/` cache | Claude Code downloads it |
| `~/.claude/projects/`, `sessions/`, `history.jsonl` | session data, not config |
| `~/.claude/backups/`, `file-history/`, `shell-snapshots/` | machine state |
| Third-party hooks | owned by Pulser and Pixel Agents |
| Every token | secrets never reach GitHub |

## Refreshing this document

Update the tables by hand when the machine gets new content.
