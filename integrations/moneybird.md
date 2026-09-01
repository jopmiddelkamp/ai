# Moneybird

## What it is
Dutch bookkeeping software. It hosts its own MCP server.

## How it touches the AI setup
Two MCP servers point at the same endpoint,
`https://moneybird.com/mcp/v1/read_write`. The token selects the
administration.

| Server key | Administration |
|---|---|
| `moneybird-middelkamp-development` | Middelkamp Development |
| `moneybird-holding-42` | Holding 42 |

Both are **read and write**. They can create invoices and change records. Treat
every write as a real bookkeeping action.

## Config on disk
- `mcp/servers.json` in this repo, keys `moneybird-middelkamp-development` and
  `moneybird-holding-42`
- `~/.claude.json`, the matching `mcpServers` keys

## Secrets
`MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN` and `MONEYBIRD_HOLDING_42_TOKEN`, both
sent as `Authorization: Bearer <token>`. Both live in `~/.claude/mcp.env`.

## Where to check
https://developer.moneybird.com/

## How to reinstall
Create a personal API token per administration in Moneybird, put each one in
`~/.claude/mcp.env`, then run `bash scripts/apply-mcp.sh`.
