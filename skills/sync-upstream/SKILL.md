---
name: sync-upstream
description: Refresh content this repo copied from other public repos. Use when the user asks to update, sync, or refresh vendored skills, or asks what changed upstream. Reads sources.yaml, fetches each upstream repo, shows the upstream diff and the local edits, and proposes a merge for approval.
---

# Sync Upstream

This repo copies single skills out of other people's public repos. It never
forks and never uses a submodule. `sources.yaml` records where each copy came
from and which commit it matches.

Your job: bring each copy up to date without losing the owner's edits.

## Ground rules

1. **Never write without approval.** Show the change, then wait.
2. **Handle one entry at a time.** Finish it before you start the next.
3. **Never keep a nested `.git` directory** in the repo.
4. **Never widen the scope.** Copy only the `path` the entry names.
5. When an upstream repo is gone, say so and move to the next entry. The local
   copy keeps working.

## Steps

### 1. Read the manifest

Read `sources.yaml`. Build the list of entries. Tell the user how many entries
you will check.

If the user named one entry, check only that one.

### 2. Fetch each upstream repo

Work in a scratch directory. Use a shallow clone of the branch in `ref`:

```bash
work=$(mktemp -d)
git clone --quiet --filter=blob:none --no-checkout "<repo>" "$work/<name>"
git -C "$work/<name>" fetch --quiet origin "<ref>"
```

Record the head commit:

```bash
git -C "$work/<name>" rev-parse "origin/<ref>"
```

### 3. Report the gap

Compare the head commit with `pinned`.

- Equal: report "up to date" and go to the next entry.
- Different: count the commits and list their subjects.

```bash
git -C "$work/<name>" log --oneline "<pinned>..origin/<ref>" -- "<path>"
```

If that command lists nothing, the changes did not touch `path`. Report that,
update `pinned` and `pinned_at` anyway, then still run step 9 and commit in
step 9's own words — a manifest-only change is a change, and leaving it
uncommitted means the next run repeats the same fetch and the same report.

### 4. Show the upstream diff

```bash
git -C "$work/<name>" diff "<pinned>..origin/<ref>" -- "<path>"
```

Summarise it in plain words before you show it. Say which files changed and
what the change does.

### 5. Find the owner's edits

Check the local copy against the upstream tree at `pinned`:

```bash
git -C "$work/<name>" checkout --quiet "<pinned>" -- "<path>"
diff -ru -x .git "$work/<name>/<path>" "<local>"
```

**`-x .git` is not optional.** The clone keeps its own `.git` directory and the
local copy never has one, because this repo strips it when vendoring. Without
`-x .git` every entry reports `Only in ...: .git` and looks edited.

Two further differences are vendoring artefacts, not edits:

- A `LICENSE` this repo copied in when the upstream licence sits outside
  `path`. It exists locally and not under the upstream subtree.
- Anything the entry's `notes` field records as deliberately removed.

Sort what the diff prints into artefacts and real edits, and say which is
which. If only artefacts remain, say "no local edits" and the merge is a plain
copy.

### 6. Propose the merge

State three things:

1. What upstream changed.
2. What the owner changed.
3. Whether the two touch the same lines.

When they do not overlap, propose the merged file and ask for approval.
When they do overlap, show both sides and ask the owner which one wins.

**Stop here. Wait for a yes.**

### 7. Apply

On approval:

```bash
git -C "$work/<name>" checkout --quiet "origin/<ref>" -- "<path>"
rm -rf "<local>"
cp -R "$work/<name>/<path>" "<local>"
rm -rf "<local>/.git"
```

Then put back everything step 7 wiped:

1. **Re-apply any local edit** the owner chose to keep.
2. **Restore the artefacts step 5 listed.** `rm -rf "<local>"` removed the whole
   directory, so a `LICENSE` this repo copied in from outside `path` is gone.
   Copy it back. This is not optional: `sources.yaml` records a licence for
   every entry, and losing the file breaks that claim on the very first refresh.

Then confirm the directory holds what you expect before you continue.

### 8. Update the manifest

Set `pinned` to the new head commit. Set `pinned_at` to that commit's date:

```bash
git -C "$work/<name>" log -1 --format=%cs "origin/<ref>"
```

### 9. Verify and clean up

```bash
bash scripts/tests/run.sh
bash scripts/check-secrets.sh
rm -rf "$work"
```

Both must pass before you commit.

### 10. Commit

One commit per entry:

```bash
git add sources.yaml <local>
git commit -m "chore: update <name> to upstream <short-sha>"
```

## Adding a new source

When the owner points at a repo and asks for one skill out of it:

1. Clone it into a scratch directory.
2. Show the owner the skills it holds, with each `description` line.
3. Ask which ones to take.
4. Copy only those directories into `skills/`.
5. Remove any nested `.git`.
6. Copy the upstream `LICENSE` into the skill directory when one exists.
7. Add an entry to `sources.yaml` with the current head commit.
8. Show the owner exactly which files landed and what the new entry says.
   **Stop here. Wait for a yes** before you install or commit.
9. Run `bash scripts/install.sh` so the new skill goes live.
9. Run `bash scripts/tests/run.sh` and `bash scripts/check-secrets.sh`.
10. Commit.

## Keeping this skill current

When Claude Code changes the skill file format, or when a step here stops
working, fix this file in the same session and say what you changed.
