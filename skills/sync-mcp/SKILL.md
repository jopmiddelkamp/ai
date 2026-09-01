---
name: sync-mcp
description: Check and update the MCP server definitions in this repo. Use when the user asks to update, check, verify, or add an MCP server, or reports that a server stopped working. Reads mcp/servers.json and mcp/README.md, checks each server against its source of truth, and proposes edits for approval.
---

# Sync MCP

`mcp/servers.json` holds the shape of every MCP server. `mcp/README.md` holds
one section per server with its purpose, transport, secrets, where to check for
changes, and the date last checked.

Your job: keep both files true, and never let a secret reach a tracked file.

## Ground rules

1. **Never write a real token into a tracked file.** Use `${VAR}`.
2. **Never write without approval.** Show the edit, then wait.
3. Every new variable gets a row in the variables table of `mcp/README.md`.
4. After any edit, run `bash scripts/check-secrets.sh`.

## Steps

### 1. Read both files

Read `mcp/servers.json` and `mcp/README.md`. List each server with its
transport and its "Last checked" date. Show the list to the user.

### 2. Compare with the live machine

```bash
jq -r '.mcpServers | keys | join(", ")' ~/.claude.json
bash scripts/check-drift.sh
```

Report three groups:

- On the machine but not in the repo. These are new; offer to add them.
- In the repo but not on the machine. These need `bash scripts/apply-mcp.sh`.
- In both. These continue to step 3.

### 3. Check each source of truth

Read the server's "Where to check" line first. Only three of the seven are
URLs. The rest name a local repo or an app, and WebFetch cannot open those.

- **The line is a URL:** fetch it with WebFetch.
- **The line names a local repo,** as gbrain and trello do: run
  `git -C <repo> log -1 --oneline` and `git -C <repo> status -sb`, and report
  whether the checkout is behind its remote.
- **The line names an app,** as pencil does: run `ls -l <path>` on the command
  and report whether it still exists.

Then, by transport:

- **http servers:** confirm the URL, the transport, and the auth header shape.
- **stdio servers:** confirm the command path still exists on disk with
  `ls -l <path>`. For a server built from a local repo, run `git -C <repo> log
  -1 --oneline` and report whether the checkout is behind its remote.

Report every difference you find. Report "no change" for the rest.

### 4. Propose the edits

Show the exact edits to `mcp/servers.json` and `mcp/README.md`. Set the
"Last checked" date of every server you checked to today.

**Stop here. Wait for a yes.**

### 5. Apply and verify

```bash
jq empty mcp/servers.json
bash scripts/check-secrets.sh
bash scripts/apply-mcp.sh --dry-run
```

`jq empty` and `check-secrets.sh` must exit 0. `apply-mcp.sh --dry-run` always
exits 0 even when a variable is missing, so read its output rather than its exit
code: every variable must print `set`, and none may print `MISSING`.

Then, with approval:

```bash
bash scripts/apply-mcp.sh
```

### 6. Commit

```bash
git add mcp
git commit -m "chore: refresh MCP server definitions"
```

## Adding a server

1. Ask for the server name, transport, URL or command, and which secrets it
   needs.
2. Add the entry to `mcp/servers.json`, with every secret as `${VAR}`.
3. Add a section to `mcp/README.md` and a row to the variables table.
4. Tell the user which line to add to `~/.claude/mcp.env`. Never write that
   file for them when it holds a token they have not given you.
5. Show the exact edits you made to both files.
   **Stop here. Wait for a yes.**
6. Run `bash scripts/apply-mcp.sh --dry-run`, then apply.

## Removing a server

1. Delete the entry from `mcp/servers.json` and the section from
   `mcp/README.md`.
2. Show what you deleted, and say plainly that applying will remove the server
   from the machine. `apply-mcp.sh` replaces the whole `mcpServers` key rather
   than merging into it, so this is not reversible from the repo alone.
   **Stop here. Wait for a yes.**
3. Run `bash scripts/apply-mcp.sh`.
4. Tell the user they may delete the now-unused line from `~/.claude/mcp.env`.

## Keeping this skill current

When a server changes shape, or when Claude Code changes how it reads
`mcpServers`, fix this file in the same session and say what you changed.
Record the new fact in the matching section of `mcp/README.md` too.
