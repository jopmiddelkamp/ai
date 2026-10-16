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

It prints:
- each installed plugin, with its components, hook events, LSP binary, and the description characters it loads every session;
- what each plugin is for;
- the repo's current `enabledPlugins`;
- the marketplace catalog: every plugin in your known marketplaces, saved to a TSV file whose path the scan prints, plus any uninstalled language servers that match the repo's file types;
- usage across the last 30 sessions in this repo: plugin skills, agents, and MCP servers called, slash commands typed, and the user's prompts.

### Repeat runs

When `.claude/plugin-scout.json` exists, the scan opens with **Since the last run**. That section lists the commits since then, the changed dependency and config files, new file types, newly installed plugins, and plugins that are new in your marketplaces. It ends with `NOTHING NEW` or `CHANGES`.

- `NOTHING NEW`: say so in one line, record the run (step 4), and stop. Do not re-audit the repo.
- `CHANGES`: check only what changed against the recorded stack. A new dependency or file type can bring in a new stack. A new marketplace plugin can fit the existing stack. Keep last run's verdicts for everything else, and do not re-propose a plugin listed under `declined` unless the reason no longer holds.

### First run

Read the codebase. Look at the manifests and config (`package.json`, `pubspec.yaml`, `Cargo.toml`, `*.csproj`, `go.mod`, `composer.json`, `Package.swift`, `build.gradle*`, `app.json`/`eas.json`, `vercel.json`, `supabase/`, `sentry.*`, `.github/`), the file extensions that dominate `git ls-files`, and the repo's CLAUDE.md or AGENTS.md. Find evidence. Do not read the source code.

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
- **Not installed yet**: grep the catalog TSV for each technology in the stack (its name, its framework, its service). An uninstalled plugin that fits the stack is a candidate, with the same evidence bar as an installed one. On a first run with a big stack, run the catalog search in a subagent and have it return only the matching rows.

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

For a candidate that is not installed, give the commands that keep it off everywhere except this repo:

```bash
claude plugin install <id>
claude plugin disable <id> --scope user
claude plugin enable <id> --scope local
```

Run them only when the user asks. Then check that the plugin works: an LSP binary on PATH, an MCP server that needs a login (`/mcp`).

## 4. Record

At the end of every run, also a `NOTHING NEW` run, save the state so that the next run and the weekly reminder can compare against it:

```bash
echo '<judgment JSON>' | bash <this skill's directory>/scripts/record.sh .
```

The judgment is `{"stack": [{"tech", "evidence", "plugins": [ids]}], "enabled": [ids], "declined": [{"plugin", "reason"}]}`. On a repeat run, start from the recorded values and change only what this run decided. `record.sh` adds the time, HEAD, file types, installed plugins, and the marketplace catalog, writes `.claude/plugin-scout.json`, and adds that file to `.gitignore` on the first run. Tell the user when it changed `.gitignore`.

The `ai` plugin's SessionStart hook reads this file. When a scanned repo's last run is 7 or more days old (`PLUGIN_SCOUT_DAYS` changes the interval) and the repo has new commits or a marketplace has refreshed since, it asks you to suggest a run. If that reminder appears at the start of a session, offer the run in one line and go on with the user's request.
