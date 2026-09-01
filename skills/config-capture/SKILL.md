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

A path is **tracked** when either of these is true:

- it is a symlink pointing into this repo, or
- its relative path appears in `~/.claude/.ai-repo-manifest`.

The second case matters: `install.sh --copy` writes real files rather than
links, and those are owned even though they are not symlinks. Check the
manifest before you call anything untracked:

```bash
grep -qxF "skills/<name>" ~/.claude/.ai-repo-manifest && echo tracked
```

`check-drift.sh` from step 1 already applies both rules, so when its "untracked
content" section and this loop disagree, believe `check-drift.sh`.

For each genuinely untracked item, read its frontmatter and show the user its
`name` and `description`.

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

Read the entry with its secrets masked. **Never print the raw object.** It
holds live tokens, and printing one copies it into this conversation's stored
transcript:

```bash
jq '.mcpServers["<name>"]' ~/.claude.json \
  | sed -E 's/("(Authorization|[A-Z_]*TOKEN|[A-Z_]*KEY|[A-Z_]*SECRET)": *")[^"]*/\1<REDACTED>/'
```

That shows you the shape, which is all you need. Copy the shape into
`mcp/servers.json` and replace every masked value, and every machine-specific
path, with a `${VAR}` placeholder. If you need to know a real value, do not
read it: ask the owner to put it into `~/.claude/mcp.env` themselves. Add a section to
`mcp/README.md` and a row to its variables table. Tell the user the exact line
to add to `~/.claude/mcp.env`.

**An AI tool:** write a new file in `integrations/` following the shape of the
files already there, and add a row to `integrations/README.md`.

### 7. Install and verify

```bash
bash scripts/install.sh --dry-run --force
bash scripts/install.sh --force
bash scripts/tests/run.sh
bash scripts/check-drift.sh
git add -A
bash scripts/check-secrets.sh --staged
```

**`--force` is required here, and leaving it off breaks the whole run.** The
item you just captured still sits on the machine as a real file or directory,
not a link. Without `--force`, `install.sh` refuses to replace it and exits 1
from inside its loop, so every later skill, style and command is left
uninstalled too. With `--force` it moves the original into
`~/.claude/.backup-<timestamp>/` first, so nothing is lost.

Read the `--dry-run --force` output before the real run and confirm every
`backup` line names a path you meant to capture.

`check-secrets.sh` runs after `git add` and with `--staged` on purpose. Its
default mode scans only files git already tracks, so a freshly copied file
would not be scanned at all.

`check-drift.sh` must end with `in sync`.

### 8. Commit

```bash
git add -A
git commit -m "feat: capture <what> from the machine"
```

## Keeping this skill current

When `~/.claude` gains a new kind of content, add a step here that finds it,
and add a matching folder to the repo. Say what you changed.
