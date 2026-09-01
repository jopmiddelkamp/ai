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

# 4. Create the secrets file. Git never sees it.
touch ~/.claude/mcp.env
chmod 600 ~/.claude/mcp.env

# 5. Fill it in, then check and apply.
bash scripts/apply-mcp.sh --dry-run
bash scripts/apply-mcp.sh
```

**Step 5 needs you to edit `~/.claude/mcp.env` by hand first.** The table in
[mcp/README.md](mcp/README.md) says where each of the six values comes from.
`--dry-run` prints `MISSING` for anything you have not filled in yet.

## Daily use

| I want to | Say this to the agent |
|---|---|
| refresh the skills I copied from other repos | "update the copied skills" |
| check my MCP servers | "check the MCP servers" |
| store something I added outside the repo | "capture what is not in the repo yet" |
| take one skill from a repo I found | "take the X skill from <url>" |

## Commands

```bash
bash scripts/install.sh      # link this repo into ~/.claude
bash scripts/apply-mcp.sh    # write the MCP servers into ~/.claude.json
bash scripts/check-drift.sh  # what differs between repo and machine
bash scripts/check-secrets.sh  # is anything leaking
bash scripts/tests/run.sh    # run every test
```

## What is here

| Folder | What |
|---|---|
| [skills/](skills/) | 8 skills |
| [output-styles/](output-styles/) | the ELI5-readable style |
| [commands/](commands/) | the `/bro` command |
| [mcp/](mcp/) | 7 MCP servers, no secrets |
| [integrations/](integrations/) | notes on 8 third-party tools |
| [settings/](settings/) | reference copies of settings and plugins |
| [hooks/](hooks/) | empty; see its README |
| [scripts/](scripts/) | install, apply, check |
| [docs/](docs/) | the inventory, the design, and this plan |

## Rules

1. No secret ever enters this repo. Use `${VAR}` and `~/.claude/mcp.env`.
2. Content copied from another repo gets an entry in
   [sources.yaml](sources.yaml).
3. Never fork a repo to take one skill from it. Copy the folder and record the
   link.

[AGENTS.md](AGENTS.md) says the same thing for an agent.
