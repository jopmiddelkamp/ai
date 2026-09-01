# GBrain

## What it is
A hosted personal knowledge brain. It stores pages, facts, timelines, and code
graphs, and answers questions over them.

## How it touches the AI setup
It is an MCP server named `gbrain`. It adds a large tool set for search,
recall, capture, and graph traversal. It also ships its own agent contract,
which tells the agent to search the brain before an external lookup.

## Config on disk
- `mcp/servers.json` in this repo, key `gbrain`
- `~/.claude.json`, key `mcpServers.gbrain`
- A per-project entry also exists for `~/Projects/prive/hosted-gbrain`.

## Secrets
`GBRAIN_TOKEN`, sent as `Authorization: Bearer <token>`. It lives in
`~/.claude/mcp.env`.

## Where to check
- Source repo: `git@github.com:jopmiddelkamp/hosted-gbrain.git`
- Local checkout: `~/Projects/prive/hosted-gbrain`
- Deployment: `https://hosted-gbrain-production.up.railway.app/mcp` on Railway

## How to reinstall
Add `GBRAIN_TOKEN` to `~/.claude/mcp.env`, then run
`bash scripts/apply-mcp.sh`.
