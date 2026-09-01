# Wispr Flow

## What it is
A macOS dictation app. Bundle id `com.electron.wispr-flow`, version 1.6.721 on
2026-09-01. The owner dictates prompts with it.

## How it touches the AI setup
It is an MCP server named `wispr-flow` at
`https://api.wisprflow.ai/connect/mcp`. It uses OAuth, so no token sits on
disk.

## Config on disk
- `mcp/servers.json` in this repo, key `wispr-flow`
- `~/.claude.json`, key `mcpServers.wispr-flow`

## Secrets
None on disk. The OAuth session lives in Claude Code.

## Where to check
https://wisprflow.ai

## How to reinstall
Run `bash scripts/apply-mcp.sh`, then authorise the server in an interactive
Claude Code session with `/mcp`. A non-interactive session cannot authorise it.
