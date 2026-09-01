---
name: config-capture
description: Pull new AI agent customizations from this machine into the repo. Use when the user adds a skill, output style, command, MCP server, or AI tool outside the repo and wants it stored, or says capture my config, import my settings, or what is not in the repo yet.
---

# Config Capture

The repo is the source of truth. Sometimes content appears on the machine
first: a skill made in a chat, an output style added in the app, a new MCP
server, a new AI tool. This skill moves that content into the repo.

## Ground rules

1. **Never copy a secret into a tracked file.** Replace it with `${VAR}` and
   tell the user which line to add to `~/.claude/mcp.env`.
2. **Never write without approval.** List the findings first.
3. **Never delete anything from the machine** except through
   `bash scripts/install.sh`, which replaces a real file with a link and keeps
   a backup.

## Steps

### 1. Find the drift

```bash
bash scripts/check-drift.sh
```

Read the "untracked content" and "MCP servers" sections. These are the
candidates.

### 2. Find untracked skills, styles, and commands

```bash
for sub in skills output-styles commands; do
  for e in "$HOME/.claude/$sub"/*; do
    [ -e "$e" ] || continue
    [ -L "$e" ] && continue
    printf '%s\n' "$e"
  done
done
```

Anything that is a real file or directory, and not a symlink, is untracked.
For each one, read its frontmatter and show the user its `name` and
`description`.

### 3. Find untracked MCP servers

```bash
jq -r '.mcpServers | keys[]' ~/.claude.json
jq -r 'keys[]' mcp/servers.json
```

Report every key in the first list that is missing from the second.

### 4. Find untracked AI tools

```bash
ls -1 /Applications ~/Applications
ls -1d "$HOME"/.[a-z]*/hooks 2>/dev/null
```

Compare against the files in `integrations/`. Report any AI-related app or
hook directory that has no note yet.

### 5. Report and propose

Show one table: what was found, what kind it is, and where it would go in the
repo. Recommend which items to take and which to skip.

**Stop here. Wait for a yes.**

### 6. Capture the approved items

**A skill:**

```bash
cp -R "$HOME/.claude/skills/<name>" "skills/<name>"
rm -rf "skills/<name>/.git"
```

If it came from somebody else's repo, add an entry to `sources.yaml` with the
upstream URL and the current head commit. Ask the user for the URL when you
cannot find it.

**An output style or a command:** copy the single file into `output-styles/`
or `commands/`. Use a lowercase file name.

**An MCP server:**

```bash
jq '.mcpServers["<name>"]' ~/.claude.json
```

Copy the shape into `mcp/servers.json`. Replace every token, key, and
machine-specific path with a `${VAR}` placeholder. Add a section to
`mcp/README.md` and a row to its variables table. Tell the user the exact line
to add to `~/.claude/mcp.env`.

**An AI tool:** write a new file in `integrations/` following the shape of the
files already there, and add a row to `integrations/README.md`.

### 7. Install and verify

```bash
bash scripts/install.sh --dry-run
bash scripts/install.sh
bash scripts/tests/run.sh
bash scripts/check-secrets.sh
bash scripts/check-drift.sh
```

Every command must pass. `check-drift.sh` must end with `in sync`.

### 8. Commit

```bash
git add -A
git commit -m "feat: capture <what> from the machine"
```

## Keeping this skill current

When `~/.claude` gains a new kind of content, add a step here that finds it,
and add a matching folder to the repo. Say what you changed.
