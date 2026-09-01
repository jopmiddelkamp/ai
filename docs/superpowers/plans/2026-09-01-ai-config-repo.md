# AI Config Repo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a private repo that holds every AI agent customization, applies it to `~/.claude` with one command, and refreshes content copied from other public repos.

**Architecture:** The repo is the source of truth. `scripts/install.sh` symlinks skills, output styles, and commands into `~/.claude` and records what it owns in a manifest file. `scripts/apply-mcp.sh` renders a secret-free MCP template and merges it into `~/.claude.json`. Three skills drive the maintenance loops: `sync-upstream` refreshes copied content, `sync-mcp` refreshes server definitions, and `config-capture` pulls new machine content back into the repo.

**Tech Stack:** bash 3.2 (the macOS system bash), `jq`, `git`. Tests are plain bash scripts. No package manager, no runtime, no build step.

**Spec:** `docs/superpowers/specs/2026-09-01-ai-config-repo-design.md`

## Global Constraints

- Repo root: `/Users/jopmiddelkamp/Projects/prive/ai`. Every path below is relative to it.
- Target platform: macOS. Use BSD-compatible flags only. Do not use GNU-only options such as `readlink -f`, `sed -i` without an argument, or `grep -P`.
- Target shell: bash 3.2. Do not use `declare -A`, `${var,,}`, or `mapfile`.
- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`. Three exceptions use `set -uo pipefail`: `scripts/check-secrets.sh` and `scripts/check-drift.sh`, because a non-matching `grep` must not abort a scan; and everything under `scripts/tests/`, because a failing check must not abort the rest of a test file. Each says so in a comment.
- Every script accepts `--dry-run` and changes nothing when it is given.
- Every script honours `CLAUDE_DIR` (default `$HOME/.claude`) and `CLAUDE_JSON` (default `$HOME/.claude.json`) so tests can point at a temp directory.
- No secret, token, key, or password may ever be written into a tracked file. Use a `${VAR}` placeholder.
- Skills use the Claude shape: a directory with `SKILL.md`, YAML frontmatter with `name` and `description`.
- Output styles use one markdown file with frontmatter `name`, `description`, `keep-coding-instructions`.
- Commands use one markdown file with frontmatter `description`.
- Commit messages use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`.
- Work on a branch named `feat/config-repo`. `master` is the default branch.
- Tests live in `scripts/tests/`. Run them all with `bash scripts/tests/run.sh`.

---

### Task 0: Create the working branch

**Files:**
- None.

**Interfaces:**
- Consumes: nothing.
- Produces: the branch `feat/config-repo`, checked out.

- [ ] **Step 1: Create and switch to the branch**

```bash
cd /Users/jopmiddelkamp/Projects/prive/ai
git checkout -b feat/config-repo
```

- [ ] **Step 2: Confirm the branch is active**

Run: `git branch --show-current`
Expected: `feat/config-repo`

---

### Task 1: Repo scaffold, ignore rules, and the test harness

**Files:**
- Create: `.gitignore`
- Create: `scripts/tests/lib.sh`
- Create: `scripts/tests/run.sh`
- Create: `scripts/tests/test_gitignore.sh`
- Create: `scripts/tests/test_harness.sh`
- Create: `skills/.gitkeep`, `output-styles/.gitkeep`, `commands/.gitkeep`, `hooks/.gitkeep`, `mcp/.gitkeep`, `settings/.gitkeep`, `integrations/.gitkeep`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/tests/lib.sh`, which every later test file sources. It exports these shell functions:
  - `assert_eq <expected> <actual> <message>`
  - `assert_rc <expected_code> <actual_code> <message>`
  - `assert_symlink_to <link_path> <target_path> <message>`
  - `assert_file <path> <message>`
  - `assert_no_file <path> <message>`
  - `assert_contains <haystack> <needle> <message>`
  - `make_fake_home` — prints the path of a new temp directory that holds `.claude/skills`, `.claude/output-styles`, `.claude/commands`, and a `.claude.json` holding `{}`
  - `finish` — prints the count of checks and failures, then exits 0 or 1

- [ ] **Step 1: Write the failing harness self-test**

Create `scripts/tests/test_harness.sh`:

```bash
#!/usr/bin/env bash
# Self-test for the test helpers.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

assert_eq "a" "a" "assert_eq accepts equal strings"
assert_rc 0 0 "assert_rc accepts equal codes"
assert_contains "hello world" "world" "assert_contains finds a substring"

home=$(make_fake_home)
assert_file "$home/.claude.json" "make_fake_home creates .claude.json"
assert_file "$home/.claude/skills" "make_fake_home creates the skills directory"
assert_no_file "$home/.claude/nothing" "assert_no_file accepts a missing path"

ln -s "$home/.claude.json" "$home/link"
assert_symlink_to "$home/link" "$home/.claude.json" "assert_symlink_to follows a link"

rm -rf "$home"

# The failure path must actually fail. Every other test file's pass/fail
# accounting rests on this, and until now it was verified only by reading.
# finish calls exit, so run the pair inside a subshell and capture its status.
( assert_eq a b "deliberate failure" >/dev/null 2>&1; finish ) >/dev/null 2>&1
assert_eq "1" "$?" "finish exits 1 after a failed check"
( assert_eq a a "deliberate pass" >/dev/null 2>&1; finish ) >/dev/null 2>&1
assert_eq "0" "$?" "finish exits 0 when every check passed"

finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_harness.sh`
Expected: FAIL with `No such file or directory` for `lib.sh`.

- [ ] **Step 3: Write the harness**

Create `scripts/tests/lib.sh`:

```bash
# Shared helpers for the shell tests. Source this file; do not run it.
# Deliberately does not use `set -e`, because a failing check must not abort the file.
set -uo pipefail

CHECKS_RUN=0
CHECKS_FAILED=0

_pass() { CHECKS_RUN=$((CHECKS_RUN + 1)); printf '  ok   %s\n' "$1"; }
_fail() {
  CHECKS_RUN=$((CHECKS_RUN + 1))
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
  printf '  FAIL %s\n' "$1" >&2
  [ $# -gt 1 ] && printf '       %s\n' "$2" >&2
  return 0
}

assert_eq() { # expected actual message
  if [ "$1" = "$2" ]; then _pass "$3"; else _fail "$3" "expected '$1', got '$2'"; fi
}

assert_rc() { # expected_code actual_code message
  if [ "$1" -eq "$2" ]; then _pass "$3"; else _fail "$3" "expected exit $1, got $2"; fi
}

assert_symlink_to() { # link target message
  if [ ! -L "$1" ]; then
    _fail "$3" "'$1' is not a symlink"
  elif [ "$(readlink "$1")" = "$2" ]; then
    _pass "$3"
  else
    _fail "$3" "'$1' points at '$(readlink "$1")', want '$2'"
  fi
}

assert_file() { # path message
  if [ -e "$1" ]; then _pass "$2"; else _fail "$2" "'$1' does not exist"; fi
}

assert_no_file() { # path message
  if [ ! -e "$1" ]; then _pass "$2"; else _fail "$2" "'$1' exists but should not"; fi
}

assert_contains() { # haystack needle message
  case "$1" in
    *"$2"*) _pass "$3" ;;
    *) _fail "$3" "'$2' not found in output" ;;
  esac
}

make_fake_home() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/aicfg.XXXXXX")
  mkdir -p "$d/.claude/skills" "$d/.claude/output-styles" "$d/.claude/commands"
  printf '{}\n' >"$d/.claude.json"
  printf '%s' "$d"
}

finish() {
  printf '  -- %s checks, %s failed\n' "$CHECKS_RUN" "$CHECKS_FAILED"
  [ "$CHECKS_FAILED" -eq 0 ] || exit 1
  exit 0
}
```

- [ ] **Step 4: Run it to make sure it passes**

Run: `bash scripts/tests/test_harness.sh`
Expected: PASS, `-- 9 checks, 0 failed`.

- [ ] **Step 5: Write the test runner**

Create `scripts/tests/run.sh`:

```bash
#!/usr/bin/env bash
# Run every test file in this directory.
set -uo pipefail
cd "$(dirname "$0")"

rc=0
for t in test_*.sh; do
  printf '\n== %s ==\n' "$t"
  bash "$t" || rc=1
done

printf '\n'
if [ "$rc" -eq 0 ]; then printf 'ALL TESTS PASSED\n'; else printf 'TESTS FAILED\n' >&2; fi
exit "$rc"
```

Make it executable:

```bash
chmod +x scripts/tests/run.sh
```

- [ ] **Step 6: Write the failing ignore-rules test**

Create `scripts/tests/test_gitignore.sh`:

```bash
#!/usr/bin/env bash
# The repo must refuse to track secret files.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
cd "$repo" || exit 1

check_ignored() { # relative_path message
  if git check-ignore -q "$1"; then _pass "$2"; else _fail "$2" "'$1' is not ignored"; fi
}

check_ignored "mcp.env" "mcp.env is ignored"
check_ignored "anything.env" "any .env file is ignored"
check_ignored "secrets/token.txt" "the secrets directory is ignored"
check_ignored ".DS_Store" ".DS_Store is ignored"

finish
```

- [ ] **Step 7: Run it to make sure it fails**

Run: `bash scripts/tests/test_gitignore.sh`
Expected: FAIL, four checks fail because `.gitignore` does not exist.

- [ ] **Step 8: Write the ignore rules**

Create `.gitignore`:

```gitignore
# Secrets. These must never reach GitHub.
*.env
mcp.env
secrets/

# macOS noise
.DS_Store

# Local scratch
*.local
*.backup-*
tmp/
```

- [ ] **Step 9: Create the empty content directories**

```bash
for d in skills output-styles commands hooks mcp settings integrations; do
  mkdir -p "$d" && touch "$d/.gitkeep"
done
```

- [ ] **Step 10: Run the whole suite**

Run: `bash scripts/tests/run.sh`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 11: Commit**

```bash
git add .gitignore scripts/tests skills output-styles commands hooks mcp settings integrations
git commit -m "chore: scaffold repo, ignore rules, and shell test harness"
```

---

### Task 2: Move the existing Claude content into the repo

**Files:**
- Create: `skills/bro/SKILL.md`, `skills/github-pr-comment/SKILL.md`, `skills/review-pr/SKILL.md`, `skills/skill-sync-reminder/SKILL.md`
- Create: `skills/humanizer/` (whole tree, without `.git`)
- Create: `output-styles/eli5.md`
- Create: `commands/bro.md`
- Create: `scripts/tests/test_content.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the content tree that Task 3 links into `~/.claude`. Directory names under `skills/` become the installed skill names.

- [ ] **Step 1: Write the failing content test**

Create `scripts/tests/test_content.sh`:

```bash
#!/usr/bin/env bash
# Every stored skill must have the right shape, and no nested git repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

for s in bro github-pr-comment review-pr skill-sync-reminder humanizer; do
  assert_file "$repo/skills/$s/SKILL.md" "skills/$s/SKILL.md exists"
  assert_eq "---" "$(head -1 "$repo/skills/$s/SKILL.md" 2>/dev/null)" "skills/$s/SKILL.md opens with frontmatter"
  if grep -qE '^name:[[:space:]]*'"$s"'[[:space:]]*$' "$repo/skills/$s/SKILL.md" 2>/dev/null; then
    _pass "skills/$s declares name: $s"
  else
    _fail "skills/$s declares name: $s" "frontmatter name does not match the directory"
  fi
  assert_no_file "$repo/skills/$s/.git" "skills/$s holds no nested git repo"
done

assert_file "$repo/output-styles/eli5.md" "output-styles/eli5.md exists"
assert_file "$repo/commands/bro.md" "commands/bro.md exists"

if grep -q '^name: ELI5-readable' "$repo/output-styles/eli5.md" 2>/dev/null; then
  _pass "the output style keeps the name ELI5-readable"
else
  _fail "the output style keeps the name ELI5-readable" "name line not found"
fi

finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_content.sh`
Expected: FAIL, every check fails because nothing has moved yet.

- [ ] **Step 3: Copy the content in**

```bash
cd /Users/jopmiddelkamp/Projects/prive/ai
for s in bro github-pr-comment review-pr skill-sync-reminder humanizer; do
  rm -rf "skills/$s"
  cp -R "$HOME/.claude/skills/$s" "skills/$s"
done
rm -rf skills/humanizer/.git
cp "$HOME/.claude/output-styles/ELI5.md" output-styles/eli5.md
cp "$HOME/.claude/commands/bro.md" commands/bro.md
rm -f skills/.gitkeep output-styles/.gitkeep commands/.gitkeep
find . -name .DS_Store -delete
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash scripts/tests/test_content.sh`
Expected: PASS.

- [ ] **Step 5: Confirm no secret came along**

Run: `grep -rIlE 'Bearer [A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}' skills output-styles commands`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add skills output-styles commands scripts/tests/test_content.sh
git commit -m "feat: move existing skills, output style, and command into the repo"
```

---

### Task 3: The install script

**Files:**
- Create: `scripts/install.sh`
- Create: `scripts/tests/test_install.sh`

**Interfaces:**
- Consumes: the content tree from Task 2.
- Produces:
  - `scripts/install.sh`, run as `install.sh [--dry-run] [--force] [--copy]`. Exit 0 on success, 1 on a blocked replacement, 2 on a bad option.
  - The manifest file `$CLAUDE_DIR/.ai-repo-manifest`. One line per installed path, relative to `$CLAUDE_DIR`, sorted. Task 7 (`check-drift.sh`) reads this file. Task 10 (`config-capture`) reads it too.

- [ ] **Step 1: Write the failing install test**

Create `scripts/tests/test_install.sh`:

```bash
#!/usr/bin/env bash
# install.sh links repo content into a fake ~/.claude.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/install.sh"

# --- case 1: empty home gets the links ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 0 $? "install succeeds on an empty home"
assert_symlink_to "$home/.claude/skills/bro" "$repo/skills/bro" "skills/bro is linked"
assert_symlink_to "$home/.claude/output-styles/eli5.md" "$repo/output-styles/eli5.md" "the output style is linked"
assert_symlink_to "$home/.claude/commands/bro.md" "$repo/commands/bro.md" "the command is linked"
assert_file "$home/.claude/.ai-repo-manifest" "the manifest is written"
if grep -qx 'skills/bro' "$home/.claude/.ai-repo-manifest"; then
  _pass "the manifest lists skills/bro"
else
  _fail "the manifest lists skills/bro" "line not found"
fi

# --- case 2: running twice changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" 2>&1)
assert_rc 0 $? "a second run succeeds"
assert_contains "$out" "0 changed" "a second run reports no change"
rm -rf "$home"

# --- case 3: a real file blocks the install ---
home=$(make_fake_home)
mkdir -p "$home/.claude/skills/bro"
printf 'mine\n' >"$home/.claude/skills/bro/SKILL.md"
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 1 $? "a real directory blocks the install"
assert_eq "mine" "$(cat "$home/.claude/skills/bro/SKILL.md")" "the real file is untouched"

# --- case 4: --force backs the real file up ---
CLAUDE_DIR="$home/.claude" bash "$script" --force >/dev/null 2>&1
assert_rc 0 $? "--force succeeds"
assert_symlink_to "$home/.claude/skills/bro" "$repo/skills/bro" "--force installs the link"
found=$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d | head -1)
assert_contains "$found" ".backup-" "--force creates a backup directory"
assert_file "$found/skills/bro/SKILL.md" "the backup keeps the old file under its namespace"
rm -rf "$home"

# --- case 5: a basename collision across namespaces keeps both backups ---
# install.sh only visits destinations that exist in ITS OWN repo, so the
# collision needs a repo whose output-styles/ and commands/ share a basename.
# This repo has no such pair, so build a throwaway one and run the same script
# from inside it. REPO_ROOT is derived from the script's own location, so a
# copy placed in <fake>/scripts/ treats <fake> as the repo.
fake_repo=$(mktemp -d "${TMPDIR:-/tmp}/aicfgrepo.XXXXXX")
mkdir -p "$fake_repo/scripts" "$fake_repo/skills" "$fake_repo/output-styles" "$fake_repo/commands"
cp "$script" "$fake_repo/scripts/install.sh"
printf 'repo-style\n' >"$fake_repo/output-styles/dup.md"
printf 'repo-command\n' >"$fake_repo/commands/dup.md"

home=$(make_fake_home)
printf 'old-style\n' >"$home/.claude/output-styles/dup.md"
printf 'old-command\n' >"$home/.claude/commands/dup.md"
CLAUDE_DIR="$home/.claude" bash "$fake_repo/scripts/install.sh" --force >/dev/null 2>&1
assert_rc 0 $? "--force succeeds when two namespaces share a basename"
found=$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d | head -1)
assert_eq "old-style" "$(cat "$found/output-styles/dup.md" 2>/dev/null)" "the output-styles backup survives"
assert_eq "old-command" "$(cat "$found/commands/dup.md" 2>/dev/null)" "the commands backup survives too"
rm -rf "$home" "$fake_repo"

# --- case 6: --dry-run changes nothing ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --dry-run >/dev/null 2>&1
assert_rc 0 $? "--dry-run succeeds"
assert_no_file "$home/.claude/skills/bro" "--dry-run creates no link"
assert_no_file "$home/.claude/.ai-repo-manifest" "--dry-run writes no manifest"
rm -rf "$home"

# --- case 7: --dry-run reports every blocked path and exits 1 ---
home=$(make_fake_home)
mkdir -p "$home/.claude/skills/bro"
printf 'mine\n' >"$home/.claude/skills/bro/SKILL.md"
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run 2>&1)
rc=$?
assert_rc 1 $rc "--dry-run exits 1 when a path is blocked"
assert_contains "$out" "blocked" "--dry-run reports the block"
assert_contains "$out" "skills/bro" "--dry-run names the blocked path"
assert_contains "$out" "commands/bro.md" "--dry-run keeps going past the block"
assert_eq "mine" "$(cat "$home/.claude/skills/bro/SKILL.md")" "--dry-run leaves the real file alone"
assert_no_file "$home/.claude/.ai-repo-manifest" "--dry-run writes no manifest when blocked"

# --- case 8: --dry-run --force previews the backup and still changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run --force 2>&1)
rc=$?
assert_rc 0 $rc "--dry-run --force exits 0"
assert_contains "$out" "backup" "--dry-run --force previews the backup"
assert_eq "mine" "$(cat "$home/.claude/skills/bro/SKILL.md")" "--dry-run --force changes nothing"
assert_eq "" "$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d)" "--dry-run --force creates no backup directory"
rm -rf "$home"

# --- case 9: --copy writes real files, and is safe to repeat ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --copy >/dev/null 2>&1
assert_rc 0 $? "--copy succeeds"
assert_file "$home/.claude/skills/bro/SKILL.md" "--copy writes a real file"
if [ -L "$home/.claude/skills/bro" ]; then
  _fail "--copy writes no symlink" "the path is still a link"
else
  _pass "--copy writes no symlink"
fi
CLAUDE_DIR="$home/.claude" bash "$script" --copy >/dev/null 2>&1
assert_rc 0 $? "--copy is safe to repeat"
rm -rf "$home"

# --- case 10: refuse to install into the repo itself ---
out=$(CLAUDE_DIR="$repo" bash "$script" --dry-run 2>&1)
assert_rc 2 $? "CLAUDE_DIR inside the repo exits 2"
assert_contains "$out" "inside the repo" "the error says why"
assert_eq "" "$(find "$repo/skills" -type l 2>/dev/null)" "no self-link was created in the repo"

# --- case 11: a bad option exits 2 ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --nope >/dev/null 2>&1
assert_rc 2 $? "an unknown option exits 2"
rm -rf "$home"

finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_install.sh`
Expected: FAIL, `install.sh` does not exist.

- [ ] **Step 3: Write the install script**

Create `scripts/install.sh`:

```bash
#!/usr/bin/env bash
# Link this repo's agent content into ~/.claude.
# The repo is the source of truth. This script never edits repo files.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
MANIFEST="$CLAUDE_DIR/.ai-repo-manifest"

DRY_RUN=0
FORCE=0
COPY=0
CHANGED=0
BLOCKED=0
NEW_MANIFEST=""

usage() {
  cat <<'USAGE'
Usage: install.sh [--dry-run] [--force] [--copy]

  --dry-run  Print the plan. Change nothing. Reports every path this script
             does not own as "blocked" and exits 1, so you see the whole
             picture before you decide on --force.
  --force    Replace a file this script does not own. Back it up first.
  --copy     Write copies instead of symlinks. Use only if links break.

Environment:
  CLAUDE_DIR  Target directory. Default: $HOME/.claude
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --copy) COPY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Refuse to install into the repo itself. If CLAUDE_DIR resolves inside
# REPO_ROOT then a destination can equal its own source, and two things go
# wrong at once: `rm -rf "$dest"` would delete the source, and `ln -s src dest`
# onto an existing directory silently creates a nested self-link inside it
# rather than failing. This has happened once, from a mistyped test.
CANON_CLAUDE_DIR=$(cd "$CLAUDE_DIR" 2>/dev/null && pwd || printf '%s' "$CLAUDE_DIR")
case "$CANON_CLAUDE_DIR" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    printf 'install.sh: CLAUDE_DIR (%s) is inside the repo (%s).\n' "$CANON_CLAUDE_DIR" "$REPO_ROOT" >&2
    printf 'install.sh: that would make a destination its own source. Refusing.\n' >&2
    exit 2
    ;;
esac

OWNED=""
[ -f "$MANIFEST" ] && OWNED=$(cat "$MANIFEST")

is_owned() { printf '%s\n' "$OWNED" | grep -qxF "$1"; }
in_new_manifest() { printf '%s' "$NEW_MANIFEST" | grep -qxF "$1"; }

BACKUP_DIR="$CLAUDE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"

# install_one <absolute source> <path relative to CLAUDE_DIR>
install_one() {
  src="$1"
  rel="$2"
  dest="$CLAUDE_DIR/$rel"
  NEW_MANIFEST="$NEW_MANIFEST$rel
"

  if [ "$COPY" -eq 0 ] && [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi

  if [ -L "$dest" ] || is_owned "$rel"; then
    action="replace"
  elif [ -e "$dest" ]; then
    if [ "$FORCE" -eq 0 ]; then
      BLOCKED=$((BLOCKED + 1))
      printf '%-8s %s (exists, not owned by this repo)\n' "blocked" "$rel"
      # A dry run reports every blocked path and keeps going. Stopping at the
      # first one would hide the rest of the plan, which is the whole point of
      # a dry run. The exit code at the end still says a real run would fail.
      if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
      printf 'install.sh: %s exists and this script does not own it.\n' "$dest" >&2
      printf 'install.sh: run again with --force to back it up and replace it.\n' >&2
      exit 1
    fi
    action="backup"
  else
    action="create"
  fi

  CHANGED=$((CHANGED + 1))
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%-8s %s\n' "$action" "$rel"
    return 0
  fi

  if [ "$action" = "backup" ]; then
    # Keep the namespace in the backup path. A flat backup would let
    # output-styles/x.md and commands/x.md collide, and `mv` overwrites
    # silently, so one original would be lost while the script reported
    # success.
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
  elif [ "$action" = "replace" ]; then
    # A manifest-owned path is not always a symlink. `--copy` writes real files,
    # and a hand edit leaves real content behind. Deleting that outright loses
    # work while the script reports success, so back it up first. Only a symlink
    # is safe to remove without a copy: the content lives in the repo.
    if [ ! -L "$dest" ] && [ -e "$dest" ]; then
      mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
      cp -R "$dest" "$BACKUP_DIR/$rel"
    fi
    rm -rf "$dest"
  fi

  mkdir -p "$(dirname "$dest")"
  if [ "$COPY" -eq 1 ]; then
    cp -R "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  printf '%-8s %s\n' "$action" "$rel"
}

# Skills: one directory each.
for d in "$REPO_ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  install_one "${d%/}" "skills/$name"
done

# Output styles and commands: one file each.
for f in "$REPO_ROOT"/output-styles/*.md; do
  [ -f "$f" ] || continue
  install_one "$f" "output-styles/$(basename "$f")"
done

for f in "$REPO_ROOT"/commands/*.md; do
  [ -f "$f" ] || continue
  install_one "$f" "commands/$(basename "$f")"
done

# Remove anything we own that the repo no longer has.
if [ -n "$OWNED" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    in_new_manifest "$rel" && continue
    CHANGED=$((CHANGED + 1))
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '%-8s %s\n' "prune" "$rel"
    else
      # Same rule as above: never delete real content without a copy.
      if [ ! -L "${CLAUDE_DIR:?}/$rel" ] && [ -e "${CLAUDE_DIR:?}/$rel" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
        cp -R "${CLAUDE_DIR:?}/$rel" "$BACKUP_DIR/$rel"
      fi
      rm -rf "${CLAUDE_DIR:?}/$rel"
      printf '%-8s %s\n' "prune" "$rel"
    fi
  done <<<"$OWNED"
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$CLAUDE_DIR"
  printf '%s' "$NEW_MANIFEST" | grep -v '^$' | sort >"$MANIFEST"
fi

printf '%s changed\n' "$CHANGED"

if [ "$BLOCKED" -gt 0 ]; then
  printf '%s blocked; re-run with --force to back them up and replace them\n' "$BLOCKED" >&2
  exit 1
fi
```

- [ ] **Step 4: Make it executable and run the test**

```bash
chmod +x scripts/install.sh
bash scripts/tests/test_install.sh
```

Expected: PASS.

- [ ] **Step 5: See why the live machine needs --force**

Run: `bash scripts/install.sh --dry-run; printf 'exit: %s\n' "$?"`

Expected: seven `blocked` lines, one for each of the five skills, the output
style, and the command, then `7 blocked; re-run with --force ...` and
`exit: 1`. Those seven paths are real files today, so the script refuses to
replace them without permission. Nothing on disk changes.

If any path you cannot account for appears, STOP and report it.

- [ ] **Step 6: Preview the real run**

Run: `bash scripts/install.sh --dry-run --force; printf 'exit: %s\n' "$?"`

Expected: seven `backup` lines, then `7 changed` and `exit: 0`. This is exactly
what Step 7 will do. Still nothing on disk changes: check with
`ls -la ~/.claude/skills` that no symlink exists yet.

- [ ] **Step 7: Apply it**

Run: `bash scripts/install.sh --force`

Expected: seven `backup` lines and `7 changed`. A directory named
`~/.claude/.backup-<timestamp>/` now holds the seven original items.

- [ ] **Step 8: Verify the live links and the backup**

```bash
ls -la ~/.claude/skills ~/.claude/output-styles ~/.claude/commands
ls -R ~/.claude/.backup-*/
cat ~/.claude/.ai-repo-manifest
```

Expected: every entry under the three directories is a symlink into
`/Users/jopmiddelkamp/Projects/prive/ai`; the backup directory holds the seven
originals; the manifest lists seven sorted paths.

- [ ] **Step 9: Commit**

```bash
git add scripts/install.sh scripts/tests/test_install.sh
git commit -m "feat: add install.sh to link repo content into ~/.claude"
```

---

### Task 4: The MCP template and its notes

**Files:**
- Create: `mcp/servers.json`
- Create: `mcp/README.md`
- Delete: `mcp/.gitkeep`

**Interfaces:**
- Consumes: nothing.
- Produces: `mcp/servers.json`. Its top level is the object that goes into the `mcpServers` key of `~/.claude.json`. Every secret and every machine-specific path appears as `${VAR}`. Task 5 renders it. Task 9 (`sync-mcp`) edits it.
- Produces the variable names that `~/.claude/mcp.env` must define: `MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN`, `MONEYBIRD_HOLDING_42_TOKEN`, `GBRAIN_TOKEN`, `TRELLO_API_KEY`, `TRELLO_TOKEN`, `TRELLO_MCP_PATH`.

- [ ] **Step 1: Write the template**

Create `mcp/servers.json`:

```json
{
  "pencil": {
    "type": "stdio",
    "command": "/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64",
    "args": ["--app", "desktop"],
    "env": {}
  },
  "moneybird-middelkamp-development": {
    "type": "http",
    "url": "https://moneybird.com/mcp/v1/read_write",
    "headers": {
      "Authorization": "Bearer ${MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN}"
    }
  },
  "moneybird-holding-42": {
    "type": "http",
    "url": "https://moneybird.com/mcp/v1/read_write",
    "headers": {
      "Authorization": "Bearer ${MONEYBIRD_HOLDING_42_TOKEN}"
    }
  },
  "trello": {
    "type": "stdio",
    "command": "node",
    "args": ["${TRELLO_MCP_PATH}"],
    "env": {
      "TRELLO_API_KEY": "${TRELLO_API_KEY}",
      "TRELLO_TOKEN": "${TRELLO_TOKEN}"
    }
  },
  "vercel-private": {
    "type": "http",
    "url": "https://mcp.vercel.com"
  },
  "gbrain": {
    "type": "http",
    "url": "https://hosted-gbrain-production.up.railway.app/mcp",
    "headers": {
      "Authorization": "Bearer ${GBRAIN_TOKEN}"
    }
  },
  "wispr-flow": {
    "type": "http",
    "url": "https://api.wisprflow.ai/connect/mcp"
  }
}
```

- [ ] **Step 2: Check the template is valid JSON and holds no secret**

```bash
jq empty mcp/servers.json && echo "JSON ok"
grep -cE 'Bearer [A-Za-z0-9]' mcp/servers.json || echo "no literal token"
```

Expected: `JSON ok`, then `no literal token`.

- [ ] **Step 3: Write the notes**

Create `mcp/README.md`:

````markdown
# MCP servers

`servers.json` holds the shape of every MCP server. It never holds a secret.
Every secret and every machine path is a `${VAR}` placeholder.

Real values live in `~/.claude/mcp.env`, which git ignores.

Apply the template with:

```bash
bash scripts/apply-mcp.sh --dry-run   # show the plan
bash scripts/apply-mcp.sh             # write ~/.claude.json
```

## Variables to define in `~/.claude/mcp.env`

| Variable | Used by | Where to get it |
|---|---|---|
| `MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN` | `moneybird-middelkamp-development` | Moneybird, administration Middelkamp Development, personal API token |
| `MONEYBIRD_HOLDING_42_TOKEN` | `moneybird-holding-42` | Moneybird, administration Holding 42, personal API token |
| `GBRAIN_TOKEN` | `gbrain` | the hosted GBrain deployment |
| `TRELLO_API_KEY` | `trello` | Trello developer settings |
| `TRELLO_TOKEN` | `trello` | Trello developer settings |
| `TRELLO_MCP_PATH` | `trello` | path to `dist/index.js` in the local Trello-Desktop-MCP checkout |

## Servers

### pencil
- **Purpose:** design work in the Pencil desktop app.
- **Transport:** stdio, a binary inside `/Applications/Pencil.app`.
- **Secrets:** none.
- **Where to check:** the Pencil app release notes.
- **Last checked:** 2026-09-01.

### moneybird-middelkamp-development
- **Warning: this endpoint is read AND write.** A request can create or change
  a real invoice, contact or ledger entry. Treat every write as a real
  bookkeeping action, not a test.
- **Purpose:** bookkeeping for the Middelkamp Development administration.
- **Transport:** http, `https://moneybird.com/mcp/v1/read_write`.
- **Secrets:** `MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN`, sent as `Authorization: Bearer <token>`.
- **Where to check:** https://developer.moneybird.com/
- **Last checked:** 2026-09-01.

### moneybird-holding-42
- **Warning: this endpoint is read AND write**, same as above.
- **Purpose:** bookkeeping for the Holding 42 administration.
- **Transport:** http, same endpoint as above. The token selects the administration.
- **Secrets:** `MONEYBIRD_HOLDING_42_TOKEN`.
- **Where to check:** https://developer.moneybird.com/
- **Last checked:** 2026-09-01.

### trello
- **Purpose:** read and write Trello boards and cards.
- **Transport:** stdio, `node <TRELLO_MCP_PATH>`.
- **Secrets:** `TRELLO_API_KEY`, `TRELLO_TOKEN`.
- **Where to check:** the local Trello-Desktop-MCP checkout and its upstream repo.
- **Last checked:** 2026-09-01.

### vercel-private
- **Purpose:** deployments, logs, and project data on Vercel.
- **Transport:** http, `https://mcp.vercel.com`. It uses OAuth, so no token file.
- **Secrets:** none on disk. Authorise it in an interactive session.
- **Where to check:** https://vercel.com/docs/mcp
- **Last checked:** 2026-09-01.

### gbrain
- **Purpose:** the personal knowledge brain.
- **Transport:** http, `https://hosted-gbrain-production.up.railway.app/mcp`.
- **Secrets:** `GBRAIN_TOKEN`.
- **Where to check:** the local `hosted-gbrain` repo.
- **Last checked:** 2026-09-01.

### wispr-flow
- **Purpose:** dictation history from the Wispr Flow app.
- **Transport:** http, `https://api.wisprflow.ai/connect/mcp`. It uses OAuth.
- **Secrets:** none on disk. Authorise it in an interactive session.
- **Where to check:** https://wisprflow.ai
- **Last checked:** 2026-09-01.
````

- [ ] **Step 4: Verify every "Where to check" link resolves**

```bash
for u in https://developer.moneybird.com/ https://vercel.com/docs/mcp https://wisprflow.ai; do
  printf '%s -> %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 10 "$u")"
done
```

Expected: each line ends in `200`. If a URL returns 404, find the correct page and edit `mcp/README.md` before you commit. Do not leave a broken link.

- [ ] **Step 5: Create the local secrets file**

```bash
cat > ~/.claude/mcp.env <<'ENVFILE'
# Real values for mcp/servers.json. Never commit this file.
MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN=
MONEYBIRD_HOLDING_42_TOKEN=
GBRAIN_TOKEN=
TRELLO_API_KEY=
TRELLO_TOKEN=
TRELLO_MCP_PATH=/Users/jopmiddelkamp/Projects/misc/Trello-Desktop-MCP/dist/index.js
ENVFILE
chmod 600 ~/.claude/mcp.env
```

Then fill the five empty values from the live config:

```bash
jq -r '.mcpServers["moneybird-middelkamp-development"].headers.Authorization | sub("^Bearer ";"")' ~/.claude.json
jq -r '.mcpServers["moneybird-holding-42"].headers.Authorization | sub("^Bearer ";"")' ~/.claude.json
jq -r '.mcpServers.gbrain.headers.Authorization | sub("^Bearer ";"")' ~/.claude.json
jq -r '.mcpServers.trello.env.TRELLO_API_KEY' ~/.claude.json
jq -r '.mcpServers.trello.env.TRELLO_TOKEN' ~/.claude.json
```

Paste each value after the matching `=` in `~/.claude/mcp.env`. Never paste them into a repo file.

- [ ] **Step 6: Commit**

```bash
rm -f mcp/.gitkeep
git add mcp
git commit -m "feat: add secret-free MCP server template and notes"
```

---

### Task 5: The MCP apply script

**Files:**
- Create: `scripts/apply-mcp.sh`
- Create: `scripts/tests/test_apply_mcp.sh`

**Interfaces:**
- Consumes: `mcp/servers.json` from Task 4.
- Produces: `scripts/apply-mcp.sh`, run as `apply-mcp.sh [--dry-run]`. Exit 0 on success, 1 on a missing variable or invalid JSON, 2 on a bad option. It reads `MCP_ENV_FILE` (default `$CLAUDE_DIR/mcp.env`) and writes `CLAUDE_JSON` (default `$HOME/.claude.json`).

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_apply_mcp.sh`:

```bash
#!/usr/bin/env bash
# apply-mcp.sh renders the template and merges it into .claude.json.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/apply-mcp.sh"
template="$repo/mcp/servers.json"

vars=$(grep -oE '\$\{[A-Z0-9_]+\}' "$template" | tr -d '${}' | sort -u)

good_env=$(mktemp)
for v in $vars; do printf '%s=test-%s\n' "$v" "$v" >>"$good_env"; done

# --- case 1: a full env file renders everything ---
home=$(make_fake_home)
printf '{"numStartups":42}\n' >"$home/.claude.json"
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$script" >/dev/null 2>&1
assert_rc 0 $? "apply succeeds with a full env file"
assert_eq "42" "$(jq -r '.numStartups' "$home/.claude.json")" "unrelated keys survive"
assert_eq "Bearer test-GBRAIN_TOKEN" \
  "$(jq -r '.mcpServers.gbrain.headers.Authorization' "$home/.claude.json")" \
  "the gbrain token is substituted"
assert_eq "test-TRELLO_MCP_PATH" \
  "$(jq -r '.mcpServers.trello.args[0]' "$home/.claude.json")" \
  "the trello path is substituted"
if grep -q '${' "$home/.claude.json"; then
  _fail "no placeholder survives" "found a \${ in the result"
else
  _pass "no placeholder survives"
fi
assert_eq "7" "$(jq -r '.mcpServers | length' "$home/.claude.json")" "all seven servers are written"

# --- case 2: a missing variable aborts and names it ---
bad_env=$(mktemp)
grep -v '^GBRAIN_TOKEN=' "$good_env" >"$bad_env"
out=$(GBRAIN_TOKEN= CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$bad_env" bash "$script" 2>&1)
rc=$?
assert_rc 1 $rc "a missing variable aborts"
assert_contains "$out" "GBRAIN_TOKEN" "the error names the missing variable"

# --- case 3: --dry-run changes nothing ---
printf '{"numStartups":7}\n' >"$home/.claude.json"
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$script" --dry-run >/dev/null 2>&1
assert_rc 0 $? "--dry-run succeeds"
assert_eq "null" "$(jq -r '.mcpServers' "$home/.claude.json")" "--dry-run writes no servers"

# --- case 4: a corrupt target is refused, and leaves no temp file ---
bad_home=$(make_fake_home)
printf 'this is not json\n' >"$bad_home/.claude.json"
out=$(CLAUDE_JSON="$bad_home/.claude.json" MCP_ENV_FILE="$good_env" bash "$script" 2>&1)
rc=$?
assert_rc 1 $rc "a corrupt target file is refused with exit 1"
assert_contains "$out" "not valid JSON" "the error explains why"
assert_eq "this is not json" "$(cat "$bad_home/.claude.json")" "the corrupt file is left untouched"
assert_eq "" "$(find "$bad_home" -name '*.tmp.*' 2>/dev/null)" "no temp file is left behind"
rm -rf "$bad_home"

rm -rf "$home" "$good_env" "$bad_env"
finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_apply_mcp.sh`
Expected: FAIL, `apply-mcp.sh` does not exist.

- [ ] **Step 3: Write the script**

Create `scripts/apply-mcp.sh`:

```bash
#!/usr/bin/env bash
# Render mcp/servers.json and merge it into the mcpServers key of ~/.claude.json.
# Secrets come from an env file that git never sees.
set -euo pipefail

# Everything this script writes can hold a credential.
umask 077

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
ENV_FILE="${MCP_ENV_FILE:-$CLAUDE_DIR/mcp.env}"
TEMPLATE="$REPO_ROOT/mcp/servers.json"

DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: apply-mcp.sh [--dry-run]

  --dry-run  Show which variables are set and which are missing. Write nothing.

Environment:
  CLAUDE_DIR    Base directory. Default: $HOME/.claude
  CLAUDE_JSON   Target file. Default: $HOME/.claude.json
  MCP_ENV_FILE  Secrets file. Default: $CLAUDE_DIR/mcp.env
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'apply-mcp.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || { printf 'apply-mcp.sh: jq is required.\n' >&2; exit 1; }
[ -f "$TEMPLATE" ] || { printf 'apply-mcp.sh: missing %s\n' "$TEMPLATE" >&2; exit 1; }

# Load the secrets file into the environment of this process only.
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

VARS=$(grep -oE '\$\{[A-Z0-9_]+\}' "$TEMPLATE" | tr -d '${}' | sort -u)

MISSING=""
for var in $VARS; do
  if [ -z "${!var:-}" ]; then MISSING="$MISSING $var"; fi
done

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'template: %s\n' "$TEMPLATE"
  printf 'env file: %s\n' "$ENV_FILE"
  printf 'target:   %s\n\n' "$CLAUDE_JSON"
  for var in $VARS; do
    if [ -z "${!var:-}" ]; then printf '  MISSING  %s\n' "$var"; else printf '  set      %s\n' "$var"; fi
  done
  printf '\nservers: %s\n' "$(jq -r 'keys | join(", ")' "$TEMPLATE")"
  exit 0
fi

if [ -n "$MISSING" ]; then
  printf 'apply-mcp.sh: no value for:%s\n' "$MISSING" >&2
  printf 'apply-mcp.sh: add each one to %s\n' "$ENV_FILE" >&2
  exit 1
fi

rendered=$(cat "$TEMPLATE")
for var in $VARS; do
  rendered=${rendered//\$\{$var\}/${!var}}
done

printf '%s' "$rendered" | jq empty 2>/dev/null || {
  printf 'apply-mcp.sh: the rendered template is not valid JSON.\n' >&2
  exit 1
}

[ -f "$CLAUDE_JSON" ] || printf '{}\n' >"$CLAUDE_JSON"

# Check the target before touching it. Without this, a target that is already
# corrupt makes the jq call below fail under `set -e`, which aborts the script
# with jq's own exit code and leaves an empty temp file next to the user's
# config forever.
if ! jq empty "$CLAUDE_JSON" 2>/dev/null; then
  printf 'apply-mcp.sh: %s is not valid JSON. Refusing to touch it.\n' "$CLAUDE_JSON" >&2
  printf 'apply-mcp.sh: restore it from a .backup- copy first.\n' >&2
  exit 1
fi

tmp="$CLAUDE_JSON.tmp.$$"
# Clean the temp file up on every exit path, including an abort under `set -e`.
trap 'rm -f "$tmp"' EXIT
jq --argjson servers "$rendered" '.mcpServers = $servers' "$CLAUDE_JSON" >"$tmp"
jq empty "$tmp" 2>/dev/null || { printf 'apply-mcp.sh: refusing to write invalid JSON.\n' >&2; exit 1; }

# This file holds live bearer tokens. A plain redirect creates the temp file at
# 0644 under the default umask, and the mv then carries that mode onto the
# target, quietly making every token world-readable. Pin the mode explicitly on
# both the replacement and the backup.
backup="$CLAUDE_JSON.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CLAUDE_JSON" "$backup"
chmod 600 "$backup"
chmod 600 "$tmp"
mv "$tmp" "$CLAUDE_JSON"

printf 'wrote %s servers to %s\n' "$(printf '%s' "$rendered" | jq -r 'length')" "$CLAUDE_JSON"
```

- [ ] **Step 4: Make it executable and run the test**

```bash
chmod +x scripts/apply-mcp.sh
bash scripts/tests/test_apply_mcp.sh
```

Expected: PASS.

- [ ] **Step 5: Dry-run against the real machine**

Run: `bash scripts/apply-mcp.sh --dry-run`
Expected: every variable shows `set`. If any shows `MISSING`, fill it in `~/.claude/mcp.env` first.

- [ ] **Step 6: Apply for real and confirm nothing was lost**

```bash
jq -r 'keys | length' ~/.claude.json          # note the number
bash scripts/apply-mcp.sh
jq -r 'keys | length' ~/.claude.json          # must be the same or one more
jq -r '.mcpServers | keys | join(", ")' ~/.claude.json
```

Expected: the key count did not drop, and the seven servers are listed.

- [ ] **Step 7: Commit**

```bash
git add scripts/apply-mcp.sh scripts/tests/test_apply_mcp.sh
git commit -m "feat: add apply-mcp.sh to render MCP servers into ~/.claude.json"
```

---

### Task 6: The secret guard and the commit hook

**Files:**
- Create: `scripts/check-secrets.sh`
- Create: `scripts/secret-allowlist.txt`
- Create: `.githooks/pre-commit`
- Create: `scripts/tests/test_check_secrets.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/check-secrets.sh`, run as `check-secrets.sh [--staged] [file ...]`. Exit 0 when clean, 1 when a credential is found, 2 on a bad option. With `--staged` it scans the files git has staged.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_check_secrets.sh`:

```bash
#!/usr/bin/env bash
# check-secrets.sh finds real credentials and ignores safe look-alikes.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/check-secrets.sh"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/aicfg.XXXXXX")

printf 'Authorization: Bearer sk-abcdefghijklmnopqrstuvwxyz012345\n' >"$tmp/openai.txt"
bash "$script" "$tmp/openai.txt" >/dev/null 2>&1
assert_rc 1 $? "an OpenAI-style key is caught"

printf 'token: ghp_abcdefghijklmnopqrstuvwxyz0123456789\n' >"$tmp/github.txt"
bash "$script" "$tmp/github.txt" >/dev/null 2>&1
assert_rc 1 $? "a GitHub token is caught"

printf 'key: aBcD3fGhIjKlMnOpQrStUvWxYz0123456789AbCdEf\n' >"$tmp/opaque.txt"
bash "$script" "$tmp/opaque.txt" >/dev/null 2>&1
assert_rc 1 $? "a long mixed-case opaque string is caught"

printf 'pinned: 523374dee72d67c7b2b5f858ea0094ffda49c3ac\n' >"$tmp/sha.txt"
bash "$script" "$tmp/sha.txt" >/dev/null 2>&1
assert_rc 0 $? "a git commit hash is allowed"

printf 'Authorization: Bearer ${GBRAIN_TOKEN}\n' >"$tmp/placeholder.txt"
bash "$script" "$tmp/placeholder.txt" >/dev/null 2>&1
assert_rc 0 $? "a placeholder is allowed"

printf 'name: moneybird-middelkamp-development\n' >"$tmp/name.txt"
bash "$script" "$tmp/name.txt" >/dev/null 2>&1
assert_rc 0 $? "a long hyphenated name is allowed"

out=$(bash "$script" "$tmp/openai.txt" 2>&1)
assert_contains "$out" "openai.txt" "the report names the file"

# The path: entries must stay, or the guard cannot commit its own tests.
for pth in scripts/tests/test_check_secrets.sh docs/superpowers/plans/2026-09-01-ai-config-repo.md; do
  if grep -qxF "path:$pth" "$repo/scripts/secret-allowlist.txt"; then
    _pass "$pth is path-allowlisted"
  else
    _fail "$pth is path-allowlisted" "entry missing from scripts/secret-allowlist.txt"
  fi
done

# The whole repo must be clean. This only passes because path: works.
bash "$script" >/dev/null 2>&1
assert_rc 0 $? "the tracked repo holds no credential"

rm -rf "$tmp"
finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_check_secrets.sh`
Expected: FAIL, `check-secrets.sh` does not exist.

- [ ] **Step 3: Write the guard**

Create `scripts/check-secrets.sh`:

```bash
#!/usr/bin/env bash
# Refuse content that looks like a live credential.
# Not `set -e`: a non-matching grep must not abort the scan.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ALLOWLIST="$REPO_ROOT/scripts/secret-allowlist.txt"

# Shapes that are almost always a real credential. Each has a fixed prefix or
# a fixed structure, so the false-positive rate is near zero.
HIGH_SIGNAL='Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|sk-[A-Za-z0-9]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|glpat-[A-Za-z0-9_-]{16,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|xox[baprs]-[A-Za-z0-9-]{10,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|AIza[A-Za-z0-9_-]{30,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|A(KIA|SIA)[0-9A-Z]{16}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
HIGH_SIGNAL="$HIGH_SIGNAL"'|-----BEGIN [A-Z ]*PRIVATE KEY-----'

# A credential introduced by name. This is the rule that catches what the other
# two structurally cannot: a 64-character hexadecimal Trello token, which the
# generic rule skips as a git hash, and an AWS secret key containing / or +,
# which the generic character class excludes. Requiring a secret-shaped
# identifier immediately before the separator is what stops it matching every
# long path in the repo.
NAMED='(secret|token|passwd|password|api[_-]?key|access[_-]?key|apikey)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+=_.-]{16,}'

# A long opaque run. Pure lowercase hexadecimal is skipped, because that is a
# git hash. The character class deliberately excludes / + and =: a POSIX path
# such as /Users/someone/Projects/prive/ai/scripts is over 40 characters and
# would otherwise be reported on nearly every line of this repo. The NAMED rule
# above covers the credentials this exclusion would otherwise miss.
GENERIC_MIN=40

usage() {
  cat <<'USAGE'
Usage: check-secrets.sh [--staged] [file ...]

  --staged   Scan the staged content of the files git has staged. This reads
             the index, not the working tree, because the index is what a
             commit will actually record.
  (no args)  Scan every file git tracks, as it exists in the working tree.
USAGE
}

FILES=""
MODE="tracked"

while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE="staged" ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'check-secrets.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) MODE="args"; FILES="$FILES
$1" ;;
  esac
  shift
done

case "$MODE" in
  staged)  FILES=$(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACM) ;;
  tracked) FILES=$(git -C "$REPO_ROOT" ls-files) ;;
esac

WORK=$(mktemp -d "${TMPDIR:-/tmp}/checksecrets.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

allowed() {
  [ -f "$ALLOWLIST" ] || return 1
  grep -qxF "$1" "$ALLOWLIST"
}

# A "path:" line in the allowlist skips a whole tracked file, matched on its
# repo-relative path. Two files here hold fake credentials as their own
# content: this guard's test fixtures, and the plan document those fixtures
# were copied from. Without this, the guard could never pass its own
# repo-wide scan, and its pre-commit hook could never commit its own tests.
path_allowed() {
  [ -f "$ALLOWLIST" ] || return 1
  grep -qxF "path:$1" "$ALLOWLIST"
}

report() { printf '%s:%s: possible credential\n' "$1" "$2" >&2; }

HITS=0

# scan_file <file to read> <label to report>
#
# Two greps per FILE, not two per line. The old per-line loop forked up to two
# subprocesses for every line, which took minutes on a large tracked file and
# pushed people towards --no-verify. It also dropped a final line that had no
# trailing newline, because `read` returns non-zero there.
scan_file() {
  src="$1"
  label="$2"
  [ -s "$src" ] || return 0
  # Skip binary files.
  grep -qI . "$src" 2>/dev/null || return 0

  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -nE "$HIGH_SIGNAL" "$src" 2>/dev/null | cut -d: -f1 | sort -un)
EOF

  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -niE "$NAMED" "$src" 2>/dev/null | cut -d: -f1 | sort -un)
EOF

  while IFS= read -r pair; do
    [ -n "$pair" ] || continue
    ln=${pair%%:*}
    tok=${pair#*:}
    case "$tok" in
      *[!0-9a-f]*) ;;
      *) continue ;;
    esac
    allowed "$tok" && continue
    report "$label" "$ln"
    HITS=$((HITS + 1))
  done <<EOF
$(grep -noE "[A-Za-z0-9_-]{$GENERIC_MIN,}" "$src" 2>/dev/null)
EOF
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$MODE" in
    args)
      scan_file "$f" "$f"
      ;;
    staged)
      path_allowed "$f" && continue
      # Read what the commit would record, not what is on disk. A file staged
      # and then edited differs, and the staged version is the one that counts.
      blob="$WORK/staged"
      git -C "$REPO_ROOT" show ":$f" >"$blob" 2>/dev/null || continue
      scan_file "$blob" "$f"
      rm -f "$blob"
      ;;
    *)
      path_allowed "$f" && continue
      scan_file "$REPO_ROOT/$f" "$f"
      ;;
  esac
done <<EOF
$FILES
EOF

if [ "$HITS" -gt 0 ]; then
  printf '\ncheck-secrets.sh: %s possible credential(s) found.\n' "$HITS" >&2
  printf 'Move the value to ~/.claude/mcp.env and use a ${VAR} placeholder.\n' >&2
  printf 'A false positive? Add the exact string to scripts/secret-allowlist.txt.\n' >&2
  exit 1
fi

printf 'check-secrets.sh: clean\n'
exit 0
```

- [ ] **Step 4: Create the allowlist**

Create `scripts/secret-allowlist.txt`:

```
# One exact string per line. check-secrets.sh ignores these.
# Add a line only after you confirm the string is not a credential.
#
# A line beginning with "path:" skips a whole tracked file, matched on its
# repo-relative path. Use it only for a file whose own content is fake
# credentials by design. Never use it to silence a real leak.
path:scripts/tests/test_check_secrets.sh
path:docs/superpowers/plans/2026-09-01-ai-config-repo.md
```

The two `path:` entries are load-bearing, not convenience. `test_check_secrets.sh`
holds realistic fake keys because that is what it tests, and the plan document
quotes that same code. Without the entries the guard flags its own test file,
so the hook would refuse the very commit that installs the guard.

- [ ] **Step 5: Make it executable and run the test**

```bash
chmod +x scripts/check-secrets.sh
bash scripts/tests/test_check_secrets.sh
```

Expected: PASS.

If "the tracked repo holds no credential" fails, read the file and line it
names. A real credential means STOP and report it, naming the file and line
but never the value. A false positive gets an exact-string line in
`scripts/secret-allowlist.txt`. Never weaken a pattern, never raise the
threshold, and never edit the plan document to make the scan pass — the briefs
are generated from it, so redacting a fixture there silently breaks the test on
the next regeneration.

- [ ] **Step 6: Write the commit hook**

Create `.githooks/pre-commit`:

```bash
#!/usr/bin/env bash
# Block a commit that carries a credential.
set -uo pipefail
repo=$(git rev-parse --show-toplevel)
bash "$repo/scripts/check-secrets.sh" --staged || {
  printf '\nCommit blocked. Fix the file, or use "git commit --no-verify" if you are certain.\n' >&2
  exit 1
}
```

- [ ] **Step 7: Turn the hook on and prove it works**

```bash
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
printf 'Bearer sk-abcdefghijklmnopqrstuvwxyz012345\n' > leak.md
git add leak.md
bash .githooks/pre-commit; printf 'hook exit: %s\n' "$?"
```

Expected: the hook names `leak.md` and prints `hook exit: 1`.

Do not run `git commit` here. A real commit would land if the hook were
inactive, and you cannot undo it with an unstage.

- [ ] **Step 8: Clean up the proof and confirm the hook is wired**

```bash
git reset HEAD leak.md
rm -f leak.md
git config --get core.hooksPath
```

Expected: `.githooks`.

- [ ] **Step 9: Commit**

```bash
git add scripts/check-secrets.sh scripts/secret-allowlist.txt .githooks scripts/tests/test_check_secrets.sh
git commit -m "feat: add a secret guard and a pre-commit hook"
```

---

### Task 7: The drift report

**Files:**
- Create: `scripts/check-drift.sh`
- Create: `scripts/tests/test_check_drift.sh`

**Interfaces:**
- Consumes: the manifest `$CLAUDE_DIR/.ai-repo-manifest` from Task 3, and `mcp/servers.json` from Task 4.
- Produces: `scripts/check-drift.sh`, run with no options. Exit 0 when the machine matches the repo, 1 when it does not, 2 on a bad option. Task 10 (`config-capture`) runs it to find untracked content.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_check_drift.sh`:

```bash
#!/usr/bin/env bash
# check-drift.sh reports a machine that no longer matches the repo.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
drift="$repo/scripts/check-drift.sh"
install="$repo/scripts/install.sh"
apply="$repo/scripts/apply-mcp.sh"
template="$repo/mcp/servers.json"

good_env=$(mktemp)
for v in $(grep -oE '\$\{[A-Z0-9_]+\}' "$template" | tr -d '${}' | sort -u); do
  printf '%s=test-%s\n' "$v" "$v" >>"$good_env"
done

home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
CLAUDE_JSON="$home/.claude.json" MCP_ENV_FILE="$good_env" bash "$apply" >/dev/null 2>&1

CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" >/dev/null 2>&1
assert_rc 0 $? "a freshly installed machine reports no drift"

# Break one link.
rm -f "$home/.claude/commands/bro.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a removed link is drift"
assert_contains "$out" "commands/bro.md" "the report names the missing path"

# Add an untracked skill.
mkdir -p "$home/.claude/skills/mystery"
printf -- '---\nname: mystery\n---\n' >"$home/.claude/skills/mystery/SKILL.md"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
assert_contains "$out" "mystery" "the report names an untracked skill"

# Remove a server from the machine.
CLAUDE_DIR="$home/.claude" bash "$install" >/dev/null 2>&1
jq 'del(.mcpServers.gbrain)' "$home/.claude.json" >"$home/x" && mv "$home/x" "$home/.claude.json"
rm -rf "$home/.claude/skills/mystery"
out=$(CLAUDE_DIR="$home/.claude" CLAUDE_JSON="$home/.claude.json" bash "$drift" 2>&1)
rc=$?
assert_rc 1 $rc "a missing MCP server is drift"
assert_contains "$out" "gbrain" "the report names the missing server"

rm -rf "$home" "$good_env"
finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_check_drift.sh`
Expected: FAIL, `check-drift.sh` does not exist.

- [ ] **Step 3: Write the report script**

Create `scripts/check-drift.sh`:

```bash
#!/usr/bin/env bash
# Report every difference between this repo and the machine.
# Not `set -e`: the script must list all drift, not stop at the first item.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
MANIFEST="$CLAUDE_DIR/.ai-repo-manifest"
TEMPLATE="$REPO_ROOT/mcp/servers.json"

case "${1:-}" in
  "") ;;
  -h|--help) printf 'Usage: check-drift.sh\n\nReports differences between the repo and %s.\n' "$CLAUDE_DIR"; exit 0 ;;
  *) printf 'check-drift.sh: unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

DRIFT=0
note() { printf '  %s\n' "$1"; DRIFT=$((DRIFT + 1)); }

printf 'repo:    %s\n' "$REPO_ROOT"
printf 'machine: %s\n\n' "$CLAUDE_DIR"

# 1. Everything the repo holds must be installed and point back here.
printf 'installed content\n'
# A destination can be three things: absent, a symlink, or real content left by
# a --copy install or a hand edit. The third case used to fall through both
# branches and report nothing, so a skill directory replaced by a real one of
# the same name read as "in sync". Compare its content instead.
check_installed() { # <absolute source in repo> <path relative to CLAUDE_DIR>
  src="$1"
  rel="$2"
  dest="$CLAUDE_DIR/$rel"
  if [ ! -e "$dest" ]; then
    note "missing: $rel"
  elif [ -L "$dest" ]; then
    [ "$(readlink "$dest")" = "$src" ] || note "wrong target: $rel"
  elif diff -r -q "$src" "$dest" >/dev/null 2>&1; then
    :   # a --copy install whose content still matches the repo
  else
    note "content differs: $rel"
  fi
}

for d in "$REPO_ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  check_installed "${d%/}" "skills/$(basename "${d%/}")"
done
for f in "$REPO_ROOT"/output-styles/*.md "$REPO_ROOT"/commands/*.md; do
  [ -f "$f" ] || continue
  case "$f" in
    */output-styles/*) rel="output-styles/$(basename "$f")" ;;
    *) rel="commands/$(basename "$f")" ;;
  esac
  check_installed "$f" "$rel"
done

# 2. Content on the machine that the repo does not track.
printf '\nuntracked content\n'
for sub in skills output-styles commands; do
  [ -d "$CLAUDE_DIR/$sub" ] || continue
  for e in "$CLAUDE_DIR/$sub"/*; do
    [ -e "$e" ] || continue
    name=$(basename "$e")
    case "$name" in .*) continue ;; esac
    rel="$sub/$name"
    if [ ! -e "$REPO_ROOT/$rel" ]; then note "not in repo: $rel"; fi
  done
done

# 3. MCP servers.
printf '\nMCP servers\n'
if command -v jq >/dev/null 2>&1 && [ -f "$TEMPLATE" ] && [ -f "$CLAUDE_JSON" ]; then
  repo_keys=$(jq -r 'keys[]' "$TEMPLATE" | sort)
  live_keys=$(jq -r '.mcpServers // {} | keys[]' "$CLAUDE_JSON" | sort)
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$live_keys" | grep -qxF "$k" || note "missing on machine: $k"
  done <<EOF
$repo_keys
EOF
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$repo_keys" | grep -qxF "$k" || note "not in repo: $k"
  done <<EOF
$live_keys
EOF

  # A server can be present on both sides and still have drifted. Compare the
  # three fields that never hold a secret, so this stays safe to print.
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    printf '%s\n' "$live_keys" | grep -qxF "$k" || continue
    for field in type url command; do
      rv=$(jq -r --arg k "$k" --arg f "$field" '.[$k][$f] // "-"' "$TEMPLATE")
      # A field holding a ${VAR} cannot be compared. The machine has the
      # rendered value and the repo has the placeholder, so they always differ
      # and a correct machine would report permanent false drift.
      case "$rv" in *'${'*) continue ;; esac
      lv=$(jq -r --arg k "$k" --arg f "$field" '.mcpServers[$k][$f] // "-"' "$CLAUDE_JSON")
      [ "$rv" = "$lv" ] || note "$k: $field differs (repo: $rv, machine: $lv)"
    done
  done <<EOF
$repo_keys
EOF
else
  note "cannot compare MCP servers: jq, the template, or $CLAUDE_JSON is missing"
fi

# 4. The manifest itself.
printf '\nmanifest\n'
if [ -f "$MANIFEST" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -e "$CLAUDE_DIR/$rel" ] || note "manifest lists a path that is gone: $rel"
  done <"$MANIFEST"
else
  note "no manifest at $MANIFEST; run scripts/install.sh"
fi

printf '\n'
if [ "$DRIFT" -eq 0 ]; then
  printf 'in sync\n'
  exit 0
fi
printf '%s difference(s) found\n' "$DRIFT"
exit 1
```

- [ ] **Step 4: Make it executable and run the test**

```bash
chmod +x scripts/check-drift.sh
bash scripts/tests/test_check_drift.sh
```

Expected: PASS.

- [ ] **Step 5: Run it against the real machine**

Run: `bash scripts/check-drift.sh`
Expected: `in sync`. If it names untracked content, note it. Task 10 handles that content.

- [ ] **Step 6: Run the whole suite**

Run: `bash scripts/tests/run.sh`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 7: Commit**

```bash
git add scripts/check-drift.sh scripts/tests/test_check_drift.sh
git commit -m "feat: add check-drift.sh to compare the repo with the machine"
```

---

### Task 8: Upstream links and the sync-upstream skill

**Files:**
- Create: `sources.yaml`
- Create: `skills/sync-upstream/SKILL.md`
- Create: `scripts/tests/test_skill_shape.sh`

**Interfaces:**
- Consumes: `skills/humanizer/` from Task 2.
- Produces: `sources.yaml`. Every later skill reads it. Its schema is fixed here:
  `name`, `kind`, `local`, `repo`, `path`, `ref`, `pinned`, `pinned_at`, `license`, `notes`.
- Produces: `skills/sync-upstream/SKILL.md`, which the user runs by asking to update or sync the copied skills.

- [ ] **Step 1: Write the failing skill-shape test**

Create `scripts/tests/test_skill_shape.sh`:

```bash
#!/usr/bin/env bash
# Every skill directory must have the right shape, whatever its name.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)

count=0
for d in "$repo"/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "${d%/}")
  count=$((count + 1))
  f="$d/SKILL.md"
  assert_file "$f" "skills/$name has SKILL.md"
  [ -f "$f" ] || continue
  assert_eq "---" "$(head -1 "$f")" "skills/$name opens with frontmatter"
  if grep -qE '^name:[[:space:]]*'"$name"'[[:space:]]*$' "$f"; then
    _pass "skills/$name declares its own name"
  else
    _fail "skills/$name declares its own name" "the name line does not match the directory"
  fi
  if grep -qE '^description:' "$f"; then
    _pass "skills/$name has a description"
  else
    _fail "skills/$name has a description" "no description line"
  fi
  assert_no_file "$d/.git" "skills/$name holds no nested git repo"
done

if [ "$count" -gt 0 ]; then
  _pass "found $count skills to check"
else
  _fail "found $count skills to check" "the skills directory is empty"
fi

# Every local: path in sources.yaml must point at something that exists.
while IFS= read -r loc; do
  [ -n "$loc" ] || continue
  assert_file "$repo/$loc" "sources.yaml entry resolves: $loc"
done <<EOF
$(grep -E '^[[:space:]]+local:' "$repo/sources.yaml" 2>/dev/null | sed -E 's/^[[:space:]]*local:[[:space:]]*//')
EOF

# And humanizer, the one vendored skill today, must still be listed by name.
if grep -q '^  - name: humanizer' "$repo/sources.yaml" 2>/dev/null; then
  _pass "sources.yaml lists humanizer"
else
  _fail "sources.yaml lists humanizer" "entry not found"
fi

finish
```

- [ ] **Step 2: Run it to make sure it fails**

Run: `bash scripts/tests/test_skill_shape.sh`
Expected: FAIL on the skill count and on `sources.yaml`.

- [ ] **Step 3: Write the upstream links file**

Create `sources.yaml`:

```yaml
# Everything in this repo that was copied from somebody else's repo.
#
# Rules:
#   - Copy the files. Never fork. Never add a submodule.
#   - Never keep a nested .git directory. The `pinned` field is the history.
#   - The `sync-upstream` skill reads this file and refreshes each entry.
#
# Fields:
#   name       short id, unique in this file
#   kind       skill | command | output-style | doc
#   local      path inside this repo
#   repo       upstream clone URL
#   path       path inside the upstream repo; "." means the repo root
#   ref        upstream branch to follow
#   pinned     upstream commit that the local copy matches
#   pinned_at  date of that commit
#   license    upstream license
#   notes      free text

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
    notes: Removes signs of AI writing. Version 2.9.1 at the pinned commit.
```

- [ ] **Step 4: Write the sync-upstream skill**

Create `skills/sync-upstream/SKILL.md`:

````markdown
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
````

- [ ] **Step 5: Run the shape test**

Run: `bash scripts/tests/run.sh`
Expected: `ALL TESTS PASSED`. The shape test checks whatever skills exist, so it stays green while Tasks 9 and 10 add the last two.

- [ ] **Step 6: Commit**

```bash
git add sources.yaml skills/sync-upstream scripts/tests/test_skill_shape.sh
git commit -m "feat: add sources.yaml and the sync-upstream skill"
```

---

### Task 9: The sync-mcp skill

**Files:**
- Create: `skills/sync-mcp/SKILL.md`

**Interfaces:**
- Consumes: `mcp/servers.json` and `mcp/README.md` from Task 4.
- Produces: `skills/sync-mcp/SKILL.md`, which the user runs by asking to check or update the MCP server configuration.

- [ ] **Step 1: Write the skill**

Create `skills/sync-mcp/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Check the frontmatter shape**

Run: `bash scripts/tests/test_skill_shape.sh`
Expected: PASS. It now reports seven skills.

- [ ] **Step 3: Commit**

```bash
git add skills/sync-mcp
git commit -m "feat: add the sync-mcp skill"
```

---

### Task 10: The config-capture skill

**Files:**
- Create: `skills/config-capture/SKILL.md`

**Interfaces:**
- Consumes: `scripts/check-drift.sh` from Task 7 and `scripts/install.sh` from Task 3.
- Produces: `skills/config-capture/SKILL.md`, which the user runs by asking to capture, import, or pull machine changes into the repo.

- [ ] **Step 1: Write the skill**

Create `skills/config-capture/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Add the three new skills to the named list**

In `scripts/tests/test_content.sh`, replace this line:

```bash
for s in bro github-pr-comment review-pr skill-sync-reminder humanizer; do
```

with:

```bash
for s in bro github-pr-comment review-pr skill-sync-reminder humanizer \
         sync-upstream sync-mcp config-capture; do
```

- [ ] **Step 3: Run the whole suite**

Run: `bash scripts/tests/run.sh`
Expected: `ALL TESTS PASSED`. Eight skills are stored.

- [ ] **Step 4: Install the three new skills and confirm they load**

```bash
bash scripts/install.sh
ls -la ~/.claude/skills
```

Expected: `sync-upstream`, `sync-mcp`, and `config-capture` are symlinks into the repo.

- [ ] **Step 5: Commit**

```bash
git add skills/config-capture scripts/tests/test_content.sh
git commit -m "feat: add the config-capture skill"
```

---

### Task 11: The integrations notes

**Files:**
- Create: `integrations/README.md`
- Create: `integrations/gbrain.md`, `integrations/pulser.md`, `integrations/claude-usage-bar.md`, `integrations/wispr-flow.md`, `integrations/trello-desktop-mcp.md`, `integrations/moneybird.md`, `integrations/vercel.md`, `integrations/claude-desktop.md`
- Delete: `integrations/.gitkeep`

**Interfaces:**
- Consumes: nothing.
- Produces: one file per third-party tool. Task 10 (`config-capture`) adds more files in the same shape. Every file uses these headings in this order: `## What it is`, `## How it touches the AI setup`, `## Config on disk`, `## Secrets`, `## Where to check`, `## How to reinstall`.

- [ ] **Step 1: Write the index**

Create `integrations/README.md`:

```markdown
# Integrations

Third-party tools that touch the AI setup on this machine. One file per tool.

These tools are **not** installed by this repo. The notes tell you what each
one is, what it changes, and how to get it back on a new machine.

| Tool | Kind | Secrets | Note |
|---|---|---|---|
| GBrain | hosted MCP service | yes | [gbrain.md](gbrain.md) |
| Pulser | macOS app with Claude Code hooks | no | [pulser.md](pulser.md) |
| ClaudeUsageBar | macOS menu bar app | no | [claude-usage-bar.md](claude-usage-bar.md) |
| Wispr Flow | macOS app with an MCP server | OAuth | [wispr-flow.md](wispr-flow.md) |
| Trello Desktop MCP | local MCP server | yes | [trello-desktop-mcp.md](trello-desktop-mcp.md) |
| Moneybird | hosted MCP service, two administrations | yes | [moneybird.md](moneybird.md) |
| Vercel | hosted MCP service | OAuth | [vercel.md](vercel.md) |
| Claude desktop | macOS app | no | [claude-desktop.md](claude-desktop.md) |

## Deliberately not tracked

**Pixel Agents** installs twelve Claude Code hooks from `~/.pixel-agents/hooks/`.
The owner chose not to track it. **Pencil** installs an MCP server from inside
its app bundle; its server entry stays in `mcp/servers.json`, but it has no note
here, also by choice.

## Adding a note

Copy the headings from any file here. Keep the order. The `config-capture`
skill writes new files in this shape.
```

- [ ] **Step 2: Write the eight tool notes**

Create `integrations/gbrain.md`:

```markdown
# GBrain

## What it is
A hosted personal knowledge brain. It stores pages, facts, timelines, and code
graphs, and answers questions over them.

## How it touches the AI setup
It is an MCP server named `gbrain`. It adds a large tool set for search,
recall, capture, and graph traversal. It also ships its own agent contract,
which tells the agent to search the brain before an external lookup.

## Config on disk
- `mcp/servers.json` in this repo, key `gbrain`
- `~/.claude.json`, key `mcpServers.gbrain`
- A per-project entry also exists for `~/Projects/prive/hosted-gbrain`.

## Secrets
`GBRAIN_TOKEN`, sent as `Authorization: Bearer <token>`. It lives in
`~/.claude/mcp.env`.

## Where to check
- Source repo: `git@github.com:jopmiddelkamp/hosted-gbrain.git`
- Local checkout: `~/Projects/prive/hosted-gbrain`
- Deployment: `https://hosted-gbrain-production.up.railway.app/mcp` on Railway

## How to reinstall
Add `GBRAIN_TOKEN` to `~/.claude/mcp.env`, then run
`bash scripts/apply-mcp.sh`.
```

Create `integrations/pulser.md`:

```markdown
# Pulser

## What it is
A macOS app that watches Claude Code sessions and plays a sound or shows a
notification on each event. Bundle id `app.getpulser.pulser`, version 0.1.13 on
2026-09-01.

## How it touches the AI setup
It registers `~/.pulser/hooks/pulser-hook.sh` on seven Claude Code hook events:
`PreToolUse`, `PostToolUse`, `PermissionRequest`, `UserPromptSubmit`,
`SessionStart`, `SessionEnd`, and `Stop`. The hook reads the event JSON from
stdin and posts it to a local server on the port in `~/.pulser/port`.

## Config on disk
- `~/.pulser/preferences.json` — sounds and notification switches
- `~/.pulser/port` — the local server port
- `~/.pulser/usage_history.json` — its own usage log
- `~/.claude/settings.json` — the seven hook entries

## Secrets
None. The hook only talks to `127.0.0.1`.

## Where to check
https://getpulser.app

## How to reinstall
Install the app. It writes its own hook entries into
`~/.claude/settings.json`. This repo does not manage those entries.
```

Create `integrations/claude-usage-bar.md`:

```markdown
# ClaudeUsageBar

## What it is
A macOS menu bar app that shows Claude usage. Bundle id
`com.fortivus.claude-usage-bar`, version 1.0.0 on 2026-09-01.

## How it touches the AI setup
It reads local Claude Code usage data. It installs no hook and no MCP server.
It changes nothing that this repo manages.

## Config on disk
Its own application support directory. Nothing in `~/.claude`.

## Secrets
None known.

## Where to check
The app vendor, Fortivus.

## How to reinstall
Install the app. No further setup is needed.
```

Create `integrations/wispr-flow.md`:

```markdown
# Wispr Flow

## What it is
A macOS dictation app. Bundle id `com.electron.wispr-flow`, version 1.6.721 on
2026-09-01. The owner dictates prompts with it.

## How it touches the AI setup
It is an MCP server named `wispr-flow` at
`https://api.wisprflow.ai/connect/mcp`. It uses OAuth, so no token sits on
disk.

## Config on disk
- `mcp/servers.json` in this repo, key `wispr-flow`
- `~/.claude.json`, key `mcpServers.wispr-flow`

## Secrets
None on disk. The OAuth session lives in Claude Code.

## Where to check
https://wisprflow.ai

## How to reinstall
Run `bash scripts/apply-mcp.sh`, then authorise the server in an interactive
Claude Code session with `/mcp`. A non-interactive session cannot authorise it.
```

Create `integrations/trello-desktop-mcp.md`:

```markdown
# Trello Desktop MCP

## What it is
A local MCP server that reads and writes Trello boards, lists, and cards. It
runs from a git checkout, not from a package.

## How it touches the AI setup
It is an MCP server named `trello`. Claude Code starts it with
`node <TRELLO_MCP_PATH>`.

## Config on disk
- `mcp/servers.json` in this repo, key `trello`
- `~/.claude.json`, key `mcpServers.trello`
- The checkout at `~/Projects/misc/Trello-Desktop-MCP`

## Secrets
`TRELLO_API_KEY` and `TRELLO_TOKEN`, both in `~/.claude/mcp.env`. The path
`TRELLO_MCP_PATH` also lives there, because it is machine-specific.

## Where to check
- Upstream: `git@github.com:kocakli/Trello-Desktop-MCP.git`
- Local checkout: `~/Projects/misc/Trello-Desktop-MCP`

## How to reinstall
```bash
git clone git@github.com:kocakli/Trello-Desktop-MCP.git ~/Projects/misc/Trello-Desktop-MCP
cd ~/Projects/misc/Trello-Desktop-MCP && npm install && npm run build
```
Then set `TRELLO_MCP_PATH` in `~/.claude/mcp.env` to the built
`dist/index.js`, add the two Trello secrets, and run
`bash scripts/apply-mcp.sh`.
```

Create `integrations/moneybird.md`:

```markdown
# Moneybird

## What it is
Dutch bookkeeping software. It hosts its own MCP server.

## How it touches the AI setup
Two MCP servers point at the same endpoint,
`https://moneybird.com/mcp/v1/read_write`. The token selects the
administration.

| Server key | Administration |
|---|---|
| `moneybird-middelkamp-development` | Middelkamp Development |
| `moneybird-holding-42` | Holding 42 |

Both are **read and write**. They can create invoices and change records. Treat
every write as a real bookkeeping action.

## Config on disk
- `mcp/servers.json` in this repo, keys `moneybird-middelkamp-development` and
  `moneybird-holding-42`
- `~/.claude.json`, the matching `mcpServers` keys

## Secrets
`MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN` and `MONEYBIRD_HOLDING_42_TOKEN`, both
sent as `Authorization: Bearer <token>`. Both live in `~/.claude/mcp.env`.

## Where to check
https://developer.moneybird.com/

## How to reinstall
Create a personal API token per administration in Moneybird, put each one in
`~/.claude/mcp.env`, then run `bash scripts/apply-mcp.sh`.
```

Create `integrations/vercel.md`:

```markdown
# Vercel

## What it is
A hosting platform. It hosts its own MCP server.

## How it touches the AI setup
It is an MCP server named `vercel-private` at `https://mcp.vercel.com`. It
covers deployments, build logs, runtime logs, projects, and analytics.

## Config on disk
- `mcp/servers.json` in this repo, key `vercel-private`
- `~/.claude.json`, key `mcpServers.vercel-private`

## Secrets
None on disk. It uses OAuth.

## Where to check
https://vercel.com/docs/mcp

## How to reinstall
Run `bash scripts/apply-mcp.sh`, then authorise the server in an interactive
Claude Code session with `/mcp`.
```

Create `integrations/claude-desktop.md`:

```markdown
# Claude desktop

## What it is
The Claude desktop app for macOS. Bundle id `com.anthropic.claudefordesktop`,
version 1.40609.0 on 2026-09-01.

## How it touches the AI setup
It is a separate store from Claude Code. Skills uploaded to the claude.ai
profile do **not** sync with the skills in this repo. The `skill-sync-reminder`
skill in this repo exists for exactly that reason.

`Claude Code URL Handler.app` in `~/Applications` handles `claude://` links. It
comes with Claude Code.

## Config on disk
Its own application support directory. It does not read `~/.claude/skills`.

## Secrets
None on disk that this repo manages.

## Where to check
https://claude.ai/download

## How to reinstall
Install the app and sign in. Then upload any skill you want available in the
app; this repo stays the source of truth.
```

- [ ] **Step 3: Check every note has the six headings**

```bash
for f in integrations/*.md; do
  case "$f" in */README.md) continue ;; esac
  n=$(grep -cE '^## (What it is|How it touches the AI setup|Config on disk|Secrets|Where to check|How to reinstall)$' "$f")
  printf '%-42s %s/6\n' "$f" "$n"
done
```

Expected: every line ends in `6/6`.

- [ ] **Step 4: Check for leaked secrets**

Run: `bash scripts/check-secrets.sh`
Expected: `check-secrets.sh: clean`.

- [ ] **Step 5: Commit**

```bash
rm -f integrations/.gitkeep
git add integrations
git commit -m "docs: add integration notes for eight third-party tools"
```

---

### Task 12: The settings reference

**Files:**
- Create: `settings/claude-settings.json`
- Create: `settings/plugins.md`
- Create: `settings/README.md`
- Create: `settings/machine/statusline-command.sh`
- Create: `settings/machine/shell-init.sh`
- Delete: `settings/.gitkeep`

**Interfaces:**
- Consumes: nothing.
- Produces: reference files only. No script reads them. They exist so a new machine can be rebuilt by hand.

- [ ] **Step 1: Copy the live settings as a reference**

```bash
cp ~/.claude/settings.json settings/claude-settings.json
jq empty settings/claude-settings.json && echo "JSON ok"
```

- [ ] **Step 2: Confirm the copy holds no secret**

```bash
bash scripts/check-secrets.sh settings/claude-settings.json
```

Expected: `check-secrets.sh: clean`. If it reports a hit, remove that value and
replace it with `"REDACTED"` before you continue.

- [ ] **Step 2b: Store the two machine scripts**

`~/.claude/settings.json` names two shell scripts by absolute path. Without
them a rebuilt machine gets a broken status line and a bash tool that cannot
see the user's zsh environment.

```bash
mkdir -p settings/machine
cp ~/.claude/statusline-command.sh settings/machine/statusline-command.sh
cp ~/.claude/shell-init.sh settings/machine/shell-init.sh
bash scripts/check-secrets.sh settings/machine/statusline-command.sh settings/machine/shell-init.sh
```

The guard must report clean. These are copies for a hand rebuild; no script
installs them.

- [ ] **Step 3: Write the settings note**

Create `settings/README.md`:

````markdown
# Settings

`claude-settings.json` is a **reference copy** of `~/.claude/settings.json`.

No script writes it back. The live file holds hook entries owned by other apps,
such as Pulser and Pixel Agents. Overwriting it would break them.

Use this copy to rebuild a machine by hand, or to see what changed:

```bash
diff <(jq -S . settings/claude-settings.json) <(jq -S . ~/.claude/settings.json)
```

## The settings that matter

| Key | Value | Why |
|---|---|---|
| `model` | `opus[1m]` | the default model |
| `effort` / `effortLevel` | `max` | maximum reasoning effort |
| `outputStyle` | `ELI5-readable` | comes from `output-styles/eli5.md` in this repo |
| `permissions.defaultMode` | `auto` | fewer prompts |
| `tui` | `fullscreen` | full screen terminal interface |
| `statusLine.command` | `bash ~/.claude/statusline-command.sh` | the custom status line |
| `env.CLAUDE_ENV_FILE` | `~/.claude/shell-init.sh` | loads the zsh config into the bash tool |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | turns on agent teams |

## The two machine scripts

`settings/machine/` holds copies of `~/.claude/statusline-command.sh` and
`~/.claude/shell-init.sh`, because `claude-settings.json` names both by
absolute path. No script installs them. On a new machine:

```bash
cp settings/machine/statusline-command.sh ~/.claude/
cp settings/machine/shell-init.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
```

## Refreshing this copy

```bash
cp ~/.claude/settings.json settings/claude-settings.json
cp ~/.claude/statusline-command.sh settings/machine/statusline-command.sh
cp ~/.claude/shell-init.sh settings/machine/shell-init.sh
bash scripts/check-secrets.sh settings/claude-settings.json
git add settings/claude-settings.json && git commit -m "chore: refresh the settings reference"
```
````

- [ ] **Step 4: Write the plugin note**

Create `settings/plugins.md`:

````markdown
# Plugins and marketplaces

Claude Code downloads plugins itself into `~/.claude/plugins/`. This repo
tracks only the list, so a new machine can be rebuilt.

## Marketplaces

| Name | Source | Auto-update |
|---|---|---|
| `claude-plugins-official` | github `anthropics/claude-plugins-official` | yes |
| `superpowers-marketplace` | github `obra/superpowers-marketplace` | yes |
| `stellar-dev` | github `stellar/stellar-dev-skill` | no |
| `business-coach` | git `https://github.com/jopmiddelkamp/ai-business-coach.git` | no |
| `gitkraken` | local directory, installed by the GitKraken app | no |

Add a marketplace with:

```bash
claude plugin marketplace add <owner>/<repo>
```

## Enabled plugins

```
autofix-bot@claude-plugins-official
business-coach@business-coach
claude-code-setup@claude-plugins-official
code-review@claude-plugins-official
context7@claude-plugins-official
elements-of-style@superpowers-marketplace
frontend-design@claude-plugins-official
gitkraken-hooks@gitkraken
playwright@claude-plugins-official
security-guidance@claude-plugins-official
skill-creator@claude-plugins-official
stellar-dev@stellar-dev
superpowers@claude-plugins-official
superpowers@superpowers-marketplace
superpowers-chrome@superpowers-marketplace
superpowers-dev@superpowers-marketplace
superpowers-developing-for-claude-code@superpowers-marketplace
```

Install one with:

```bash
claude plugin install <name>@<marketplace>
```

## Refreshing this list

```bash
jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' ~/.claude/settings.json | sort
jq -r 'to_entries[] | "\(.key)\t\(.value.source.repo // .value.source.url // .value.source.path)"' ~/.claude/plugins/known_marketplaces.json
```
````

- [ ] **Step 5: Verify the lists match the machine**

```bash
diff <(jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' ~/.claude/settings.json | sort) \
     <(grep -oE '^[a-z0-9-]+@[a-z0-9-]+$' settings/plugins.md | sort)
```

Expected: no output. If lines differ, correct `settings/plugins.md`.

- [ ] **Step 6: Commit**

```bash
rm -f settings/.gitkeep
git add settings
git commit -m "docs: add a settings and plugin reference"
```

---

### Task 13: The entry documents and the final check

**Files:**
- Create: `README.md`
- Create: `AGENTS.md`
- Create: `hooks/README.md`
- Create: `docs/claude-inventory.md`
- Delete: `hooks/.gitkeep`

**Interfaces:**
- Consumes: everything from Tasks 1 to 12.
- Produces: `AGENTS.md`, the file any agent reads first. It states the mapping from repo folder to agent feature, so a non-Claude agent can install the content its own way.

- [ ] **Step 1: Write the hooks note**

Create `hooks/README.md`:

```markdown
# Hooks

This folder is empty on purpose. The owner writes no hooks of their own today.

Every hook in `~/.claude/settings.json` belongs to another app:

- `~/.pulser/hooks/pulser-hook.sh` — see [../integrations/pulser.md](../integrations/pulser.md)
- `~/.pixel-agents/hooks/claude-hook.js` — not tracked, by choice

## Adding a hook of your own

1. Write the script here, for example `hooks/my-hook.sh`.
2. Make it executable: `chmod +x hooks/my-hook.sh`.
3. Add the entry to `~/.claude/settings.json` by hand, pointing at the repo
   path. `scripts/install.sh` does not touch `settings.json`.
4. Refresh the reference copy: `cp ~/.claude/settings.json settings/claude-settings.json`.
```

- [ ] **Step 2: Write the agent instructions**

Create `AGENTS.md`:

````markdown
# Instructions for an AI agent

This repo holds one person's customizations for AI coding agents. **The repo is
the source of truth.** A machine is a copy of it.

The files use the Claude Code shapes, because they are documented and stable.
That is a file format choice, not a lock-in. Any agent may map them into its
own system.

## The mapping

| Folder | What it holds | Shape |
|---|---|---|
| `skills/` | one directory per skill | `SKILL.md`, YAML frontmatter with `name` and `description`, then markdown instructions |
| `output-styles/` | one file per style | YAML frontmatter with `name`, `description`, `keep-coding-instructions`, then the style rules |
| `commands/` | one file per slash command | YAML frontmatter with `description`, then the command instructions |
| `hooks/` | event scripts | plain executables; empty today |
| `mcp/` | MCP server definitions | `servers.json`, a template with `${VAR}` placeholders |
| `settings/` | reference only | never applied by a script |
| `integrations/` | notes on third-party tools | markdown with fixed headings |

## For Claude Code

```bash
bash scripts/install.sh     # symlink skills, styles, and commands into ~/.claude
bash scripts/apply-mcp.sh   # render mcp/servers.json into ~/.claude.json
bash scripts/check-drift.sh # report differences
```

## For another agent

Read the mapping table. Install the same content the way your host expects. Two
rules hold for every host:

1. **Never copy a `${VAR}` placeholder as a literal.** Read the real value from
   `~/.claude/mcp.env`, which git ignores.
2. **Never write a secret into a file in this repo.**

## Rules you must follow when you change this repo

1. Run `bash scripts/tests/run.sh`. It must print `ALL TESTS PASSED`.
2. Run `bash scripts/check-secrets.sh`. It must print `clean`.
3. Content copied from another repo needs an entry in `sources.yaml`, and no
   nested `.git` directory.
4. Use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`.

## The maintenance skills

| Ask | Skill |
|---|---|
| "update the copied skills" | `sync-upstream` |
| "check the MCP servers" | `sync-mcp` |
| "capture what is not in the repo yet" | `config-capture` |
````

- [ ] **Step 3: Write the human entry point**

Create `README.md`:

````markdown
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
````

- [ ] **Step 4: Write the inventory**

Create `docs/claude-inventory.md`:

````markdown
# Claude setup inventory

What was custom on this machine on 2026-09-01, and where each item now lives.

## Skills

| Name | Source | In repo |
|---|---|---|
| `bro` | own | yes, `skills/bro` |
| `github-pr-comment` | own | yes, `skills/github-pr-comment` |
| `review-pr` | own | yes, `skills/review-pr` |
| `skill-sync-reminder` | own | yes, `skills/skill-sync-reminder` |
| `humanizer` | `blader/humanizer`, v2.9.1 | yes, `skills/humanizer`, listed in `sources.yaml` |
| `sync-upstream` | own, new | yes |
| `sync-mcp` | own, new | yes |
| `config-capture` | own, new | yes |

## Output styles

| Name | File | In repo |
|---|---|---|
| `ELI5-readable` | was `~/.claude/output-styles/ELI5.md` | yes, `output-styles/eli5.md` |

## Slash commands

| Name | In repo |
|---|---|
| `/bro` | yes, `commands/bro.md` |

`/bro` repeats the `bro` skill. Keep both: the command is the fast path, the
skill is the one an agent finds on its own.

## MCP servers

| Key | Transport | Secret | In repo |
|---|---|---|---|
| `pencil` | stdio, app bundle | no | yes |
| `moneybird-middelkamp-development` | http | yes | yes, as `${VAR}` |
| `moneybird-holding-42` | http | yes | yes, as `${VAR}` |
| `trello` | stdio, node | yes | yes, as `${VAR}` |
| `vercel-private` | http, OAuth | no | yes |
| `gbrain` | http | yes | yes, as `${VAR}` |
| `wispr-flow` | http, OAuth | no | yes |

Five MCP connectors still need an interactive login: Google Calendar, Google
Drive, Sentry, Slack, and Wispr Flow. Authorise them with `/mcp` in an
interactive session, or in the claude.ai connector settings.

## Scripts in `~/.claude`

| File | What it does | In repo |
|---|---|---|
| `statusline-command.sh` | status line styled after the robbyrussell zsh theme | yes, copy in `settings/machine/` |
| `shell-init.sh` | loads `.zshrc` and `.zprofile` into the bash tool | yes, copy in `settings/machine/` |

No script installs these two. `settings/claude-settings.json` points at them by
absolute path, so a rebuild copies them from `settings/machine/` into
`~/.claude/` by hand and runs `chmod +x` on the status line.

## Hooks

Every hook belongs to another app. See `hooks/README.md`.

| Owner | Script | Events |
|---|---|---|
| Pulser | `~/.pulser/hooks/pulser-hook.sh` | 7 |
| Pixel Agents | `~/.pixel-agents/hooks/claude-hook.js` | 12 |

## Plugins

5 marketplaces, 17 enabled plugins. Listed in `settings/plugins.md`.

## Excluded on purpose

| Item | Reason |
|---|---|
| `~/.claude/plugins/` cache | Claude Code downloads it |
| `~/.claude/projects/`, `sessions/`, `history.jsonl` | session data, not config |
| `~/.claude/backups/`, `file-history/`, `shell-snapshots/` | machine state |
| Third-party hooks | owned by Pulser and Pixel Agents |
| Every token | secrets never reach GitHub |

## Refreshing this document

Ask the agent to "capture what is not in the repo yet". The `config-capture`
skill finds new content and updates this table.
````

- [ ] **Step 5: Run every check**

```bash
bash scripts/tests/run.sh
bash scripts/check-secrets.sh
bash scripts/check-drift.sh
```

Expected: `ALL TESTS PASSED`, then `check-secrets.sh: clean`, then `in sync`.

- [ ] **Step 6: Confirm the live setup still works**

```bash
ls -la ~/.claude/skills | grep -c '\->'
jq -r '.mcpServers | keys | length' ~/.claude.json
jq -r '.outputStyle' ~/.claude/settings.json
```

Expected: `8`, then `7`, then `ELI5-readable`.

- [ ] **Step 7: Commit**

```bash
rm -f hooks/.gitkeep
git add README.md AGENTS.md hooks docs
git commit -m "docs: add README, AGENTS.md, hooks note, and the setup inventory"
```

- [ ] **Step 8: Merge to master and push**

```bash
git checkout master
git merge --no-ff feat/config-repo -m "feat: build the AI config repo"
git push origin master
```

- [ ] **Step 9: Final proof**

```bash
git log --oneline master | head -15
bash scripts/check-drift.sh
```

Expected: the commits are listed, and the drift report ends with `in sync`.
