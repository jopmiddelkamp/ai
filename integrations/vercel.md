# Vercel

## What it is
A hosting platform. It hosts its own MCP server.

## How it touches the AI setup
It is an MCP server named `vercel-private` at `https://mcp.vercel.com`. It
covers deployments, build logs, runtime logs, projects, and analytics.

## Config on disk
- `mcp/servers.json` in this repo, key `vercel-private`
- `~/.claude.json`, key `mcpServers.vercel-private`

## Secrets
None on disk. It uses OAuth.

## Where to check
https://vercel.com/docs/mcp

## How to reinstall
Run `bash scripts/apply-mcp.sh`, then authorise the server in an interactive
Claude Code session with `/mcp`.
