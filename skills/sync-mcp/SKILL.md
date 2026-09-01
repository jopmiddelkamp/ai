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

For each server, open the "Where to check" link with WebFetch.

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

All three must pass. Then, with approval:

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
5. Run `bash scripts/apply-mcp.sh --dry-run`, then apply.

## Removing a server

1. Delete the entry from `mcp/servers.json` and the section from
   `mcp/README.md`.
2. Run `bash scripts/apply-mcp.sh`. The script replaces the whole `mcpServers`
   key, so the server disappears from the machine.
3. Tell the user they may delete the now-unused line from `~/.claude/mcp.env`.

## Keeping this skill current

When a server changes shape, or when Claude Code changes how it reads
`mcpServers`, fix this file in the same session and say what you changed.
Record the new fact in the matching section of `mcp/README.md` too.
