# ai

My private config for AI coding agents. This repo is the source of truth. My
machine is a copy of it.

## First use on a new machine

```bash
git clone git@github.com:jopmiddelkamp/ai.git ~/Projects/prive/ai
cd ~/Projects/prive/ai

git config core.hooksPath .githooks      # turn on the secret guard
bash scripts/install.sh --dry-run        # see the plan
bash scripts/install.sh                  # link skills, styles, commands

cp mcp/README.md /dev/null               # read it, then create the env file
bash scripts/apply-mcp.sh --dry-run      # see which secrets are missing
bash scripts/apply-mcp.sh                # write the MCP servers
```

Fill `~/.claude/mcp.env` with the real tokens. The table in
[mcp/README.md](mcp/README.md) says where to get each one.

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
bash scripts/check-secrets.sh# is anything leaking
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
