# Integrations

Third-party tools that touch the AI setup on this machine. One file per tool.

These tools are **not** installed by this repo. The notes tell you what each
one is, what it changes, and how to get it back on a new machine.

| Tool | Kind | Secrets | Note |
|---|---|---|---|
| GBrain | hosted MCP service | yes | [gbrain.md](gbrain.md) |
| Pulser | macOS app with Claude Code hooks | no | [pulser.md](pulser.md) |
| ClaudeUsageBar | macOS menu bar app | no | [claude-usage-bar.md](claude-usage-bar.md) |
| Wispr Flow | macOS app with an MCP server | OAuth | [wispr-flow.md](wispr-flow.md) |
| Trello Desktop MCP | local MCP server | yes | [trello-desktop-mcp.md](trello-desktop-mcp.md) |
| Moneybird | hosted MCP service, two administrations | yes | [moneybird.md](moneybird.md) |
| Vercel | hosted MCP service | OAuth | [vercel.md](vercel.md) |
| Claude desktop | macOS app | no | [claude-desktop.md](claude-desktop.md) |

## Deliberately not tracked

**Pixel Agents** installs ten Claude Code hooks from `~/.pixel-agents/hooks/`.
The owner chose not to track it. **Pencil** installs an MCP server from inside
its app bundle; its server entry stays in `mcp/servers.json`, but it has no note
here, also by choice.

## Adding a note

Copy the headings from any file here. Keep the order. The `config-capture`
skill writes new files in this shape.
