---
name: plugin-scout
description: "Pick which installed Claude Code plugins to enable for the current repo, from its code and its recent sessions, and output an enabledPlugins block for .claude/settings.local.json. Use when the user says '/plugin-scout', 'which plugins should I enable here', 'set up plugins for this repo', or has plugins disabled globally and wants a per-project set. Not for finding or installing new plugins from a marketplace."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-16"
---

# Plugin scout

The user keeps every plugin disabled in `~/.claude/settings.json` and enables them per repo. A `true` in `.claude/settings.local.json` overrides the user-level `false` key by key, so the output is a small block holding only the plugins this repo needs. Every enabled plugin costs context every session, so leave out any plugin that has no evidence behind it.

## 1. Collect

Run the scan from the repo root:

```bash
bash <this skill's directory>/scripts/scan.sh . 30
```

It prints four things: each installed plugin with its components, hook events, LSP binary, and the description characters it loads every session; what each plugin is for; the repo's current `enabledPlugins`; and usage across the last 30 sessions in this repo (plugin skills, agents, and MCP servers called, slash commands typed, and the user's prompts).

Then read the codebase. Look at the manifests and config (`package.json`, `pubspec.yaml`, `Cargo.toml`, `*.csproj`, `go.mod`, `composer.json`, `Package.swift`, `build.gradle*`, `app.json`/`eas.json`, `vercel.json`, `supabase/`, `sentry.*`, `.github/`), the file extensions that dominate `git ls-files`, and the repo's CLAUDE.md or AGENTS.md. Find evidence. Do not read the source code.

## 2. Decide

Give each plugin one verdict with one piece of evidence: a file you saw, or a count from the scan.

- **Enable** when the repo uses the stack or service, or the sessions show the user calling its parts. Usage in sessions is the strongest evidence. A plugin the user called several times stays in, even when the code does not show the stack.
- **LSP plugins** cost no description context and give diagnostics after edits. Enable one when that language makes up real code in the repo. If the scan marks the binary `(missing)`, the plugin does nothing: name the install command in the notes instead of enabling it, or enable it and say the binary must be installed first.
- **MCP-only plugins** are cheap, because tool search defers their tools. Enable one when the repo talks to that service. Note any login or env var the server needs.
- **Heavy plugins** (thousands of description characters, or hooks on `SessionStart` or `UserPromptSubmit`, which inject text every session) need direct evidence: the stack is in the repo, or the sessions show use. "Might be handy" is not enough. For a heavy plugin on the shortlist, run `claude plugin details <id>` and report its always-on token estimate.
- **Duplicates**: when the same plugin is installed from two marketplaces (the scan shows the same component counts under two ids), enable one and say which.
- **General-purpose plugins** (code review, writing, skill authoring) go in only when the sessions show use in this repo. The user can turn one on for a single session when needed.
- `ai@ai` holds the user's own skills, this one included. Enable it when the sessions here used one of its skills.
- Ignore `mcp__claude_ai_*` servers in the usage list. They are claude.ai connectors, not plugins.

## 3. Report

Open with one line: the number of plugins enabled, and the description characters they add, summed from the scan.

Then the block to paste. List only `true` entries. The user-level `false` already covers everything else:

```json
{
  "enabledPlugins": {
    "plugin@marketplace": true
  }
}
```

Then a table of the enabled plugins:

| Plugin | Evidence | Cost |
|---|---|---|

Then one line per plugin you considered and left out, with the reason. Skip plugins that have no link to this repo at all.

If `.claude/settings.local.json` already exists, show the merged result, not only the new block, and point out the keys you would change. Before you suggest the file, check that git ignores it (`git check-ignore .claude/settings.local.json`). If git does not ignore it, say so. Write the file only when the user asks. After writing, tell the user to restart the session and run `claude plugin list` to confirm.
