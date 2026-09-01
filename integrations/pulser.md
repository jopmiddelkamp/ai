# Pulser

## What it is
A macOS app that watches Claude Code sessions and plays a sound or shows a
notification on each event. Bundle id `app.getpulser.pulser`, version 0.1.13 on
2026-09-01.

## How it touches the AI setup
It registers `~/.pulser/hooks/pulser-hook.sh` on seven Claude Code hook events:
`PreToolUse`, `PostToolUse`, `PermissionRequest`, `UserPromptSubmit`,
`SessionStart`, `SessionEnd`, and `Stop`. The hook reads the event JSON from
stdin and posts it to a local server on the port in `~/.pulser/port`.

## Config on disk
- `~/.pulser/preferences.json` — sounds and notification switches
- `~/.pulser/port` — the local server port
- `~/.pulser/usage_history.json` — its own usage log
- `~/.claude/settings.json` — the seven hook entries

## Secrets
None. The hook only talks to `127.0.0.1`.

## Where to check
https://getpulser.app

## How to reinstall
Install the app. It writes its own hook entries into
`~/.claude/settings.json`. This repo does not manage those entries.
