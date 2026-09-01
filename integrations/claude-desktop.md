# Claude desktop

## What it is
The Claude desktop app for macOS. Bundle id `com.anthropic.claudefordesktop`,
version 1.40609.0 on 2026-09-01.

## How it touches the AI setup
It is a separate store from Claude Code. Skills uploaded to the claude.ai
profile do **not** sync with the skills in this repo. The `skill-sync-reminder`
skill in this repo exists for exactly that reason.

`Claude Code URL Handler.app` in `~/Applications` handles `claude://` links. It
comes with Claude Code.

## Config on disk
Its own application support directory. It does not read `~/.claude/skills`.

## Secrets
None on disk that this repo manages.

## Where to check
https://claude.ai/download

## How to reinstall
Install the app and sign in. Then upload any skill you want available in the
app; this repo stays the source of truth.
