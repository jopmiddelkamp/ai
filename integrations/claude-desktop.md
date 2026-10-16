# Claude desktop

## What it is
The Claude desktop app for macOS. Bundle id `com.anthropic.claudefordesktop`,
version 1.40609.0 on 2026-09-01.

## How it touches the AI setup
It installs the skills from this repo as the `ai@ai` plugin, the same as
Claude Code. Nothing is zipped or uploaded by hand.

`Claude Code URL Handler.app` in `~/Applications` handles `claude://` links. It
comes with Claude Code.

## Config on disk
Its own application support directory. It does not read `~/.claude/skills`.

## Secrets
None on disk that this repo manages.

## Where to check
https://claude.ai/download

## How to reinstall
Install the app, sign in, and install the `ai@ai` plugin; this repo stays the
source of truth.
