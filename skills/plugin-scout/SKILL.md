---
name: plugin-scout
description: "Pick which Claude Code plugins to enable for the current repo, from its code, its recent sessions, and your marketplaces, and output an enabledPlugins block for .claude/settings.local.json. Tracks each run, so a repeat run reports only what changed. Run it with /ai:plugin-scout."
disable-model-invocation: true
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-16"
---

# Plugin scout

The user keeps every plugin disabled in `~/.claude/settings.json` and enables them per repo. A `true` in `.claude/settings.local.json` overrides the user-level `false` key by key, so the skill writes only the plugins this repo needs. Every enabled plugin costs context every session, so leave out any plugin that has no evidence behind it.

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

- `NOTHING NEW`: report it (step 4), record the run (step 5), and stop. Do not re-audit the repo.
- `CHANGES`: check only what changed against the recorded stack. A new dependency or file type can bring in a new stack. A new marketplace plugin can fit the existing stack. Keep last run's verdicts for everything else, and do not re-propose a plugin listed under `declined` unless the reason no longer holds.

### First run

Read the codebase. Look at the manifests and config (`package.json`, `pubspec.yaml`, `Cargo.toml`, `*.csproj`, `go.mod`, `composer.json`, `Package.swift`, `build.gradle*`, `app.json`/`eas.json`, `vercel.json`, `supabase/`, `sentry.*`, `.github/`), the file extensions that dominate `git ls-files`, and the repo's CLAUDE.md or AGENTS.md. Find evidence. Do not read the source code.

## 2. Decide

Give each plugin one verdict with one piece of evidence: a file you saw, or a count from the scan.

**Trusted sources only.** Add a plugin only when its `source` in the scan is `anthropic` (Anthropic or one of its partners, from an Anthropic-owned marketplace) or `own` (the user's own marketplaces). Never add a `third-party` plugin, whatever the evidence, and do not mention it. A `third-party` plugin that this repo enables goes under "Plugins to Remove", with "Why: third-party source".

- **Enable** when the repo uses the stack or service, or the sessions show the user calling its parts. Usage in sessions is the strongest evidence. A plugin the user called several times stays in, even when the code does not show the stack.
- **LSP plugins** cost no description context and give diagnostics after edits. Enable one when that language makes up real code in the repo. If the scan marks the binary `(missing)`, the plugin does nothing: name the install command in the notes instead of enabling it, or enable it and say the binary must be installed first.
- **MCP-only plugins** are cheap, because tool search defers their tools. Enable one when the repo talks to that service. Note any login or env var the server needs.
- **Heavy plugins** (thousands of description characters, or hooks on `SessionStart` or `UserPromptSubmit`, which inject text every session) need direct evidence: the stack is in the repo, or the sessions show use. "Might be handy" is not enough. For a heavy plugin on the shortlist, run `claude plugin details <id>` and report its always-on token estimate.
- **Duplicates**: when the same plugin is installed from two marketplaces (the scan shows the same component counts under two ids), enable the one whose source is `anthropic`.
- **General-purpose plugins** (code review, writing, skill authoring) go in only when the sessions show use in this repo. The user can turn one on for a single session when needed.
- `ai@ai` holds the user's own skills, this one included. Enable it when the sessions here used one of its skills.
- Ignore `mcp__claude_ai_*` servers in the usage list. They are claude.ai connectors, not plugins.
- **Not installed yet**: grep the catalog TSV for each technology in the stack (its name, its framework, its service). An uninstalled plugin that fits the stack is a candidate, with the same evidence bar as an installed one. On a first run with a big stack, run the catalog search in a subagent and have it return only the matching rows.

## 3. Apply

Merge the verdicts into `enabledPlugins` in `.claude/settings.local.json`. Keep every other key in that file. Write `true` for each plugin to add. For each plugin to remove, delete its `true` entry, because the user-level `false` already turns it off. If git does not ignore the file (`git check-ignore .claude/settings.local.json`), add it to `.gitignore` first.

Do not install plugins or tools yourself. A plugin that is not installed, or that does not work yet, gets a fix line in the report.

## 4. Report

Keep the report short. Use exactly this shape, with no table, no JSON, and no list of plugins you left out:

```
# Plugins to Add

## <plugin id>
Why: <one line of evidence: a file, or a count from the scan>
Fix: <only when it does not work yet: the command to run>

# Plugins to Remove

## <plugin id>
Why: <one line>

# What else have I done

- <one line per action: the settings file written, .gitignore changed, the run recorded>
- Restart the session, then run `claude plugin list` to check.
```

Write "None." under a heading that has no plugins. On a `NOTHING NEW` run, write only "Nothing new since <date>." under "What else have I done".

Fix lines, by problem:
- Not installed: `claude plugin install <id> && claude plugin disable <id> --scope user`. The local `true` turns it on for this repo only.
- LSP binary missing: the install command from the plugin's README.
- MCP server that needs a login: run `/mcp` and log in to `<server>`.

## 5. Record

At the end of every run, also a `NOTHING NEW` run, save the state so that the next run and the weekly reminder can compare against it:

```bash
echo '<judgment JSON>' | bash <this skill's directory>/scripts/record.sh .
```

The judgment is `{"stack": [{"tech", "evidence", "plugins": [ids]}], "enabled": [ids], "declined": [{"plugin", "reason"}]}`. On a repeat run, start from the recorded values and change only what this run decided. `record.sh` adds the time, HEAD, file types, installed plugins, and the marketplace catalog, writes `.claude/plugin-scout.json`, and adds that file to `.gitignore` on the first run. So that new worktrees keep the settings, it also makes sure both `.claude/settings.local.json` and `.claude/plugin-scout.json` are copied into each new worktree: a setup command in `worktrees.json` (or `.cursor/worktrees.json` when that file is in use) for gflow and Cursor, and a line in `.worktreeinclude` for the worktrees Claude Code creates. List each file it changed under "What else have I done"; `worktrees.json` and `.worktreeinclude` are committed files, so the user commits them.

The `ai` plugin's SessionStart hook reads this file. When a scanned repo's last run is 7 or more days old (`PLUGIN_SCOUT_DAYS` changes the interval) and the repo has new commits or a marketplace has refreshed since, it prints a reminder. It also prints one, once, in a git repo without the file. The skill runs only when the user types `/ai:plugin-scout`, never on its own.
