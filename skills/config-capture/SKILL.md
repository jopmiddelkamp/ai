---
name: config-capture
description: Use when something was added to this machine outside the repo and must be stored in it, such as a skill made in a chat, an output style or slash command added in the app, an MCP server added with claude mcp add, or a new AI tool. Triggers on "capture my config", "import my settings", "get this skill into the repo", "store it in the repo", "what is not in the repo yet", "what is on this machine that the repo does not have".
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
   a backup. The one exception is a captured skill; see step 7.

## How skills reach Claude Code

Skills are not symlinked. The repo is a Claude Code plugin (`ai@ai`), and the
plugin delivers `skills/`. So a skill that sits in `~/.claude/skills` is always
untracked, even when a skill of the same name exists in the repo. Output
styles, commands, and `CLAUDE.md` are still symlinks made by `install.sh`.

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

Every entry under `~/.claude/skills` is untracked; the plugin loads the repo's
skills from its own cache. A style or command is **tracked** when either of
these is true:

- it is a symlink pointing into this repo, or
- its relative path appears in `~/.claude/.ai-repo-manifest`.

The second case matters: `install.sh --copy` writes real files rather than
links, and those are owned even though they are not symlinks. Check the
manifest before you call anything untracked:

```bash
grep -qxF "skills/<name>" ~/.claude/.ai-repo-manifest && echo tracked
```

`check-drift.sh` from step 1 already applies both rules. Use the loop only to
see the raw candidates. When the two disagree, believe `check-drift.sh`.

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

If it came from somebody else's repo, do not copy it. Install it as a plugin
with `claude plugin marketplace add <owner>/<repo>` and add it to
`settings/plugins.md` and `settings/claude-settings.json` instead.

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
git add -A
bash scripts/check-secrets.sh --staged
```

**`--force` is required for a captured style or command.** The item still sits
on the machine as a real file, not a link. Without `--force`, `install.sh`
refuses to replace it and exits 1 from inside its loop, so every later style
and command is left uninstalled too. With `--force` it moves the original into
`~/.claude/.backup-<timestamp>/` first, so nothing is lost.

Read the `--dry-run --force` output before the real run and confirm every
`backup` line names a path you meant to capture.

**A captured skill needs one more step.** `install.sh` does not touch
`~/.claude/skills`. The repo copy goes live through the plugin after the commit
in step 8 is pushed and the plugin is refreshed:

```bash
claude plugin marketplace update ai && claude plugin update ai@ai
```

Until then the machine copy keeps working. After the refresh, ask the user for
a yes and then remove the machine copy, or the skill loads twice:

```bash
rm -rf ~/.claude/skills/<name>
bash scripts/check-drift.sh
```

`check-drift.sh` must end with `in sync`.

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
