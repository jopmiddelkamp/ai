# Instructions for an AI agent

This repo holds one person's customizations for AI coding agents. **The repo is
the source of truth.** A machine is a copy of it.

The files use the Claude Code shapes, because they are documented and stable.
That is a file format choice, not a lock-in. Any agent may map them into its
own system.

## The mapping

| Folder | What it holds | Shape |
|---|---|---|
| `.claude-plugin/` | the plugin and marketplace manifests | `plugin.json` names the plugin `ai`, which loads `skills/` and `output-styles/`; `marketplace.json` makes the repo installable with `claude plugin marketplace add jopmiddelkamp/ai` |
| `skills/` | one directory per skill | `SKILL.md`, YAML frontmatter with `name` and `description`, then markdown instructions |
| `output-styles/` | one file per style | YAML frontmatter with `name`, `description`, `keep-coding-instructions`, then the style rules; the plugin loads it as `ai:<name>` |
| `memory/` | the global user memory | plain markdown, no frontmatter; installs as `~/.claude/CLAUDE.md` |
| `hooks/` | event scripts | plain executables; empty today |
| `mcp/` | MCP server definitions | `servers.json`, a template with `${VAR}` placeholders |
| `settings/` | reference only | never applied by a script |
| `integrations/` | notes on third-party tools | markdown with fixed headings |

## For Claude Code

```bash
claude plugin marketplace add jopmiddelkamp/ai
claude plugin install ai@ai  # the plugin delivers skills/ and output-styles/
bash scripts/install.sh     # symlink memory into ~/.claude
bash scripts/apply-mcp.sh   # render mcp/servers.json into ~/.claude.json
bash scripts/check-drift.sh # report differences
bash scripts/web-prefs.sh   # copy the claude.ai preferences text to the clipboard
```

## For another agent

Read the mapping table. Install the same content the way your host expects. Two
rules hold for every host:

1. **Never copy a `${VAR}` placeholder as a literal.** Read the real value from
   `~/.claude/mcp.env`, which git ignores.
2. **Never write a secret into a file in this repo.**

## Rules you must follow when you change this repo

1. Run `bash scripts/tests/run.sh`. It must print `ALL TESTS PASSED`.
2. Run `bash scripts/check-secrets.sh`. It must print `clean`.
3. Never copy a skill out of another repo. Install it as a plugin and list it
   in `settings/plugins.md`.
4. Use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`.
