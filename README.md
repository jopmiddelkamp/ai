# ai

My private config for AI coding agents. This repo is the source of truth. My
machine is a copy of it.

## First use on a new machine

```bash
git clone git@github.com:jopmiddelkamp/ai.git ~/Projects/prive/ai
cd ~/Projects/prive/ai

# 1. Turn on the secret guard.
git config core.hooksPath .githooks

# 2. See what installing would do. On a machine that already has real files in
#    ~/.claude, this prints "blocked" lines and exits 1. That is expected.
bash scripts/install.sh --dry-run

# 3. Install. Add --force when step 2 reported blocked paths: it moves each
#    original into ~/.claude/.backup-<timestamp>/ before replacing it.
bash scripts/install.sh --force

# 4. Install the skills. This repo is a Claude Code plugin; the plugin
#    delivers skills/. install.sh does not link them.
claude plugin marketplace add jopmiddelkamp/ai
claude plugin install ai@ai

# 5. Create the secrets file. Git never sees it.
touch ~/.claude/mcp.env
chmod 600 ~/.claude/mcp.env

# 6. Fill it in, then check and apply.
bash scripts/apply-mcp.sh --dry-run
bash scripts/apply-mcp.sh
```

**Step 6 needs you to edit `~/.claude/mcp.env` by hand first.** The table in
[mcp/README.md](mcp/README.md) says where each of the six values comes from.
`--dry-run` prints `MISSING` for anything you have not filled in yet.

## Daily use

| I want to | Do this |
|---|---|
| store something I added outside the repo | say "capture what is not in the repo yet" |
| use somebody else's skill | install it as a plugin and add it to [settings/plugins.md](settings/plugins.md) |
| change a skill | edit `skills/<name>/SKILL.md`, commit, push, then see below |

## Changing a skill

Claude Code loads the skills from the plugin, not from this folder. The plugin
is this repo on GitHub. So a skill change goes live in three steps:

```bash
git commit -am "feat: ..." && git push
claude plugin marketplace update ai && claude plugin update ai@ai
# then restart Claude Code
```

The marketplace has `autoUpdate` on, so a restart alone usually picks the
change up too. Output styles, commands, and the memory file are symlinks, so
those change live.

## Commands

```bash
bash scripts/install.sh      # link styles, commands, and memory into ~/.claude
bash scripts/apply-mcp.sh    # write the MCP servers into ~/.claude.json
bash scripts/check-drift.sh  # what differs between repo and machine
bash scripts/check-secrets.sh  # is anything leaking
bash scripts/tests/run.sh    # run every test
bash scripts/web-prefs.sh    # copy my claude.ai preferences text
bash scripts/web-skills.sh   # zip my skills for claude.ai upload
```

## Claude web

claude.ai cannot read files and has no API for preferences. Sync is one paste:

```bash
bash scripts/web-prefs.sh
```

It joins [memory/CLAUDE.md](memory/CLAUDE.md) and the body of
[output-styles/eli5.md](output-styles/eli5.md), and copies the text to the
clipboard. Paste it into claude.ai → Settings → Profile → Preferences. Repeat
after every change to either file.

Skills need one drag each. claude.ai has no API for profile skills; the
`/v1/skills` API writes to API workspaces, not to the claude.ai account.

```bash
bash scripts/web-skills.sh              # every skill
bash scripts/web-skills.sh review-pr    # only these
```

It writes one zip per skill into `tmp/web-skills/`, with the skill folder at
the zip root. Upload each zip in claude.ai → Settings → Capabilities → Skills,
replacing the old version.

## What is here

| Folder | What |
|---|---|
| [.claude-plugin/](.claude-plugin/) | the plugin and marketplace manifests; the plugin is named `ai` |
| [skills/](skills/) | 6 skills, delivered by the plugin |
| [output-styles/](output-styles/) | the ELI5-readable style |
| [memory/](memory/) | the always-on rules, linked to `~/.claude/CLAUDE.md` |
| [commands/](commands/) | the `/bro` command |
| [mcp/](mcp/) | 7 MCP servers, no secrets |
| [integrations/](integrations/) | notes on 8 third-party tools |
| [settings/](settings/) | reference copies of settings and plugins |
| [hooks/](hooks/) | empty; see its README |
| [scripts/](scripts/) | install, apply, check |
| [docs/](docs/) | the inventory, the design, and this plan |

## Rules

1. No secret ever enters this repo. Use `${VAR}` and `~/.claude/mcp.env`.
2. Never copy a skill out of somebody else's repo. Install it as a plugin and
   list it in [settings/plugins.md](settings/plugins.md).

[AGENTS.md](AGENTS.md) says the same thing for an agent.
