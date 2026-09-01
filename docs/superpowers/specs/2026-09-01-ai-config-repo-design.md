# AI Config Repo — Design

- **Date:** 2026-09-01
- **Repo:** `git@github.com:jopmiddelkamp/ai.git`
- **Status:** approved, ready for an implementation plan

## Purpose

One private repo holds every customization for AI coding agents. The repo is the
source of truth. A script applies it to `~/.claude`. Another agent, such as
Codex, reads the same files and maps them into its own format.

The repo also holds content copied from other people's public repos. Each copy
records where it came from. A skill refreshes those copies on demand.

## Goals

1. Keep all custom Claude Code content in git.
2. Apply the repo to a machine with one command.
3. Copy a single skill out of any public repo, without a fork and without a
   submodule.
4. Refresh copied content from upstream while keeping local edits.
5. Keep every secret out of the repo.
6. Stay agent-neutral, so Codex can use the same files later.

## Non-goals

- The scripts never overwrite `~/.claude/settings.json`.
- The repo ships no Codex-specific code. The layout supports Codex; the code
  comes later, when the need is real.
- The repo stores no third-party hooks and no plugin caches.
- The repo has no two-way sync engine. One direction only: repo to machine.

## Layout

```
ai/
├── README.md                   for the owner: what lives here
├── AGENTS.md                   for any AI agent: how to read and apply this repo
├── sources.yaml                upstream links for copied content
├── .gitignore                  blocks secrets
│
├── skills/
│   ├── bro/SKILL.md
│   ├── github-pr-comment/SKILL.md
│   ├── review-pr/SKILL.md
│   ├── skill-sync-reminder/SKILL.md
│   ├── humanizer/              copied from blader/humanizer
│   ├── config-capture/SKILL.md new
│   ├── sync-upstream/SKILL.md  new
│   └── sync-mcp/SKILL.md       new
│
├── output-styles/
│   └── eli5.md
│
├── commands/
│   └── bro.md
│
├── hooks/
│   └── README.md               shape and rules; no hooks of our own today
│
├── mcp/
│   ├── servers.json            template with ${VAR} placeholders
│   └── README.md               one section per server
│
├── settings/
│   ├── claude-settings.json    sanitized copy, reference only
│   └── plugins.md              marketplaces and enabled plugins
│
├── integrations/
│   ├── README.md               index table of third-party tools
│   └── <tool>.md               one file per tool
│
├── scripts/
│   ├── install.sh              link the repo into ~/.claude
│   ├── apply-mcp.sh            fill placeholders and write ~/.claude.json
│   ├── check-drift.sh          report repo against machine
│   └── check-secrets.sh        block a commit that carries a token
│
└── docs/
    ├── claude-inventory.md     analysis of the current setup
    └── superpowers/specs/      design documents
```

## Content shape

The repo uses the Claude Code file shapes, because they are documented and
already in use.

| Kind | Shape | Frontmatter keys |
|---|---|---|
| Skill | directory with `SKILL.md` | `name`, `description` |
| Output style | one markdown file | `name`, `description`, `keep-coding-instructions` |
| Command | one markdown file | `description` |

Every shape is YAML frontmatter plus markdown. Any agent can parse it.

## Install

`scripts/install.sh` creates symlinks. The owner edits a file in the repo and
the change is live at once.

| Repo path | Machine path |
|---|---|
| `skills/<name>/` | `~/.claude/skills/<name>` |
| `output-styles/<file>.md` | `~/.claude/output-styles/<file>.md` |
| `commands/<file>.md` | `~/.claude/commands/<file>.md` |

Rules:

- The script refuses to replace a real file or directory. It replaces only a
  symlink that already points into this repo.
- `--dry-run` prints the plan and changes nothing.
- `--force` replaces a real file, but first moves it to
  `~/.claude/.backup-<timestamp>/`.
- `--copy` writes copies instead of symlinks. This is the fallback for a host
  that does not follow symlinks.

`AGENTS.md` states the same mapping in prose, so another agent can build its own
install path.

## Secrets

`mcp/servers.json` holds the server shape and never a token:

```json
{
  "gbrain": {
    "type": "http",
    "url": "https://hosted-gbrain-production.up.railway.app/mcp",
    "headers": { "Authorization": "Bearer ${GBRAIN_TOKEN}" }
  }
}
```

Real values live in `~/.claude/mcp.env`, outside the repo:

```
GBRAIN_TOKEN=...
MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN=...
MONEYBIRD_HOLDING_42_TOKEN=...
TRELLO_API_KEY=...
TRELLO_TOKEN=...
```

`scripts/apply-mcp.sh` reads `mcp/servers.json`, substitutes every `${VAR}` from
`mcp.env`, and writes the result into the `mcpServers` key of `~/.claude.json`
with `jq`. All other keys of that file stay unchanged. The script writes to a
temp file and moves it into place, so a failure never truncates the config.

The script aborts when a variable is missing, and names the variable.

`.gitignore` blocks `*.env`, `mcp.env`, `secrets/`, and `.DS_Store`.

## Upstream links

`sources.yaml` lists everything copied from another repo.

```yaml
sources:
  - name: humanizer
    kind: skill
    local: skills/humanizer
    repo: https://github.com/blader/humanizer
    path: .
    ref: main
    pinned: 523374dee72d67c7b2b5f858ea0094ffda49c3ac
    pinned_at: 2026-07-21
    license: MIT
    notes: AI-writing cleanup skill.
```

| Field | Meaning |
|---|---|
| `name` | short id, unique in the file |
| `kind` | `skill`, `command`, `output-style`, or `doc` |
| `local` | path in this repo |
| `repo` | upstream clone URL |
| `path` | path inside the upstream repo; `.` means the repo root |
| `ref` | upstream branch to follow |
| `pinned` | upstream commit the local copy matches |
| `pinned_at` | date of that commit |
| `license` | upstream license |
| `notes` | free text |

Copied content keeps its upstream `LICENSE` file.

The repo stores the copied files only. It never stores a nested `.git`
directory. `skills/humanizer/.git` exists today and gets removed during the
move. `sources.yaml` holds the commit, so the history stays reachable upstream.

## Skill: sync-upstream

Refreshes copied content. Steps per entry in `sources.yaml`:

1. Clone the upstream repo into a temp directory, or fetch it if already there.
2. Compare `pinned` with the head of `ref`. Report the number of commits behind.
3. Show the upstream diff for `path` between `pinned` and head.
4. Show the local diff: the copy in `local` against the upstream tree at
   `pinned`. This diff is the set of local edits.
5. Propose a merged result and stop.
6. On approval, write the files, then set `pinned` and `pinned_at`.

Rules:

- The skill never writes without approval.
- The skill handles one entry at a time and reports a summary at the end.
- When an entry has no local edits, the skill still shows the upstream diff
  before writing.
- When the upstream repo is gone, the skill reports it and continues.

## Skill: sync-mcp

Keeps the MCP server definitions current.

`mcp/README.md` holds one section per server with these fields: purpose,
transport, URL or command, required environment variables, documentation URL,
and the date last checked.

Steps:

1. Read `mcp/README.md` and `mcp/servers.json`.
2. Fetch each documentation URL.
3. Report any change: a new URL, a new transport, a renamed header, a new
   required variable.
4. Propose edits to `servers.json` and `README.md`, and stop for approval.
5. On approval, write the files and update the date last checked.
6. Update its own notes when a server moves or changes shape.

## Skill: config-capture

Runs the reverse direction: machine to repo.

Steps:

1. Scan `~/.claude/skills`, `~/.claude/output-styles`, and `~/.claude/commands`
   for entries that are not symlinks into this repo.
2. Scan `~/.claude.json` for MCP servers absent from `mcp/servers.json`.
3. Scan `/Applications` and `~/Applications` for AI tools absent from
   `integrations/`.
4. Report the findings and propose where each one belongs.
5. On approval, copy the content in, replace secrets with `${VAR}`
   placeholders, and run `scripts/install.sh` to relink.

The skill never sends a captured token to the repo. It writes a placeholder and
names the variable to add to `mcp.env`.

## Integrations folder

`integrations/` documents third-party tools that touch the AI setup. Each file
answers: what the tool does, its kind, its version at time of writing, where its
config lives, how it connects to Claude Code, its documentation URL, whether it
holds secrets, and how to reinstall it.

Files to write first:

| File | Tool | Kind |
|---|---|---|
| `gbrain.md` | hosted GBrain knowledge service | MCP service |
| `pulser.md` | Pulser | app with Claude Code hooks |
| `claude-usage-bar.md` | ClaudeUsageBar | menu bar app |
| `wispr-flow.md` | Wispr Flow | dictation app with an MCP server |
| `trello-desktop-mcp.md` | Trello Desktop MCP | local MCP server |
| `moneybird.md` | Moneybird | two MCP endpoints |
| `vercel.md` | Vercel | MCP service |
| `claude-desktop.md` | Claude desktop app | app |

`integrations/README.md` holds the index table.

## Inventory document

`docs/claude-inventory.md` records the current setup: skills, output styles,
commands, MCP servers, plugin marketplaces, enabled plugins, scripts, hooks, and
settings that matter. It marks each item as stored in the repo or excluded, and
gives the reason for every exclusion.

## What stays out

| Item | Reason |
|---|---|
| Hooks for `~/.pulser` | Owned by another tool. Documented in `integrations/pulser.md`. |
| Hooks for `~/.pixel-agents` | Owned by another tool. Not tracked, by request. |
| `~/.claude/plugins/` cache | Claude Code downloads it. `settings/plugins.md` lists the sources. |
| Any token or key | Secrets never reach GitHub. |
| Automatic `settings.json` writes | Too risky. Stored as a reference copy. |

## Error handling

- Every script uses `set -euo pipefail`.
- Every script accepts `--dry-run`.
- `install.sh` backs up a real file before replacing it.
- `apply-mcp.sh` validates its output with `jq` before it replaces
  `~/.claude.json`, and keeps a timestamped backup.
- Each skill stops and asks before it writes.

## Testing

Shell scripts get a test harness under `scripts/tests/`. Each test sets `HOME`
to a temp directory, builds a fake `~/.claude`, runs the script, and asserts the
result. Plain `bash` runs the tests; no extra tool is needed.

Cases to cover:

1. `install.sh` creates the expected symlinks in an empty fake home.
2. `install.sh` refuses to replace a real file, and exits non-zero.
3. `install.sh --force` moves the real file to the backup directory.
4. `install.sh` is safe to run twice and reports no change the second time.
5. `apply-mcp.sh` substitutes every placeholder.
6. `apply-mcp.sh` aborts and names the variable when one is missing.
7. `apply-mcp.sh` leaves all other keys of `~/.claude.json` unchanged.
8. `check-drift.sh` reports a difference after a file changes on the machine.
9. `check-secrets.sh` exits non-zero when a staged file holds a token-like
   string, and exits zero on clean content.

## Risks

| Risk | Response |
|---|---|
| A secret reaches a commit | `.gitignore` plus `scripts/check-secrets.sh`, which greps staged files for long token-like strings and exits non-zero on a hit. A `pre-commit` hook runs it. |
| Claude Code stops following symlinks | `install.sh` gains a `--copy` mode. Documented as the fallback. |
| An upstream repo disappears | `sources.yaml` keeps the pinned commit and the local copy. The copy keeps working. |
| Upstream changes conflict with local edits | `sync-upstream` shows both diffs and waits for a decision. |
