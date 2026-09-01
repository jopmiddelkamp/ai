# Trello Desktop MCP

## What it is
A local MCP server that reads and writes Trello boards, lists, and cards. It
runs from a git checkout, not from a package.

## How it touches the AI setup
It is an MCP server named `trello`. Claude Code starts it with
`node <TRELLO_MCP_PATH>`.

## Config on disk
- `mcp/servers.json` in this repo, key `trello`
- `~/.claude.json`, key `mcpServers.trello`
- The checkout at `~/Projects/misc/Trello-Desktop-MCP`

## Secrets
`TRELLO_API_KEY` and `TRELLO_TOKEN`, both in `~/.claude/mcp.env`. The path
`TRELLO_MCP_PATH` also lives there, because it is machine-specific.

## Where to check
- Upstream: `git@github.com:kocakli/Trello-Desktop-MCP.git`
- Local checkout: `~/Projects/misc/Trello-Desktop-MCP`

## How to reinstall
```bash
git clone git@github.com:kocakli/Trello-Desktop-MCP.git ~/Projects/misc/Trello-Desktop-MCP
cd ~/Projects/misc/Trello-Desktop-MCP && npm install && npm run build
```
Then set `TRELLO_MCP_PATH` in `~/.claude/mcp.env` to the built
`dist/index.js`, add the two Trello secrets, and run
`bash scripts/apply-mcp.sh`.
