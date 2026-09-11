#!/usr/bin/env bash
# install.sh links repo content into a fake ~/.claude. Skills are not linked:
# the ai plugin delivers them.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/install.sh"

# --- case 1: empty home gets the links ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 0 $? "install succeeds on an empty home"
assert_symlink_to "$home/.claude/output-styles/eli5.md" "$repo/output-styles/eli5.md" "the output style is linked"
assert_symlink_to "$home/.claude/commands/bro.md" "$repo/commands/bro.md" "the command is linked"
assert_symlink_to "$home/.claude/CLAUDE.md" "$repo/memory/CLAUDE.md" "the global CLAUDE.md is linked"
assert_no_file "$home/.claude/skills/bro" "skills are not linked; the plugin delivers them"
assert_file "$home/.claude/.ai-repo-manifest" "the manifest is written"
if grep -qx 'commands/bro.md' "$home/.claude/.ai-repo-manifest"; then
  _pass "the manifest lists commands/bro.md"
else
  _fail "the manifest lists commands/bro.md" "line not found"
fi
if grep -q '^skills/' "$home/.claude/.ai-repo-manifest"; then
  _fail "the manifest lists no skills" "a skills/ line is present"
else
  _pass "the manifest lists no skills"
fi

# --- case 2: running twice changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" 2>&1)
assert_rc 0 $? "a second run succeeds"
assert_contains "$out" "0 changed" "a second run reports no change"
rm -rf "$home"

# --- case 3: a real file blocks the install ---
home=$(make_fake_home)
printf 'mine\n' >"$home/.claude/output-styles/eli5.md"
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 1 $? "a real file blocks the install"
assert_eq "mine" "$(cat "$home/.claude/output-styles/eli5.md")" "the real file is untouched"

# --- case 4: --force backs the real file up ---
CLAUDE_DIR="$home/.claude" bash "$script" --force >/dev/null 2>&1
assert_rc 0 $? "--force succeeds"
assert_symlink_to "$home/.claude/output-styles/eli5.md" "$repo/output-styles/eli5.md" "--force installs the link"
found=$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d | head -1)
assert_contains "$found" ".backup-" "--force creates a backup directory"
assert_file "$found/output-styles/eli5.md" "the backup keeps the old file under its namespace"
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
assert_no_file "$home/.claude/commands/bro.md" "--dry-run creates no link"
assert_no_file "$home/.claude/.ai-repo-manifest" "--dry-run writes no manifest"
rm -rf "$home"

# --- case 7: --dry-run reports every blocked path and exits 1 ---
home=$(make_fake_home)
printf 'mine\n' >"$home/.claude/output-styles/eli5.md"
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run 2>&1)
rc=$?
assert_rc 1 $rc "--dry-run exits 1 when a path is blocked"
assert_contains "$out" "blocked" "--dry-run reports the block"
assert_contains "$out" "output-styles/eli5.md" "--dry-run names the blocked path"
assert_contains "$out" "commands/bro.md" "--dry-run keeps going past the block"
assert_eq "mine" "$(cat "$home/.claude/output-styles/eli5.md")" "--dry-run leaves the real file alone"
assert_no_file "$home/.claude/.ai-repo-manifest" "--dry-run writes no manifest when blocked"

# --- case 8: --dry-run --force previews the backup and still changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run --force 2>&1)
rc=$?
assert_rc 0 $rc "--dry-run --force exits 0"
assert_contains "$out" "backup" "--dry-run --force previews the backup"
assert_eq "mine" "$(cat "$home/.claude/output-styles/eli5.md")" "--dry-run --force changes nothing"
assert_eq "" "$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d)" "--dry-run --force creates no backup directory"
rm -rf "$home"

# --- case 9: --copy writes real files, and is safe to repeat ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --copy >/dev/null 2>&1
assert_rc 0 $? "--copy succeeds"
assert_file "$home/.claude/commands/bro.md" "--copy writes a real file"
if [ -L "$home/.claude/commands/bro.md" ]; then
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
assert_eq "" "$(find "$repo/output-styles" "$repo/commands" -type l 2>/dev/null)" "no self-link was created in the repo"

# --- case 11: a bad option exits 2 ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --nope >/dev/null 2>&1
assert_rc 2 $? "an unknown option exits 2"
rm -rf "$home"

# --- case 12: skill links from before the plugin are pruned ---
# A machine installed before the plugin existed has skills/<name> symlinks and
# a manifest that lists them. The plugin now loads those skills, so the links
# must go, or every skill registers twice.
home=$(make_fake_home)
ln -s "$repo/skills/bro" "$home/.claude/skills/bro"
printf 'skills/bro\n' >"$home/.claude/.ai-repo-manifest"
out=$(CLAUDE_DIR="$home/.claude" bash "$script" 2>&1)
assert_rc 0 $? "install succeeds on a pre-plugin machine"
assert_contains "$out" "prune" "the old skill link is reported as pruned"
assert_no_file "$home/.claude/skills/bro" "the old skill link is gone"
if grep -q '^skills/' "$home/.claude/.ai-repo-manifest"; then
  _fail "the manifest no longer lists the skill" "a skills/ line is still present"
else
  _pass "the manifest no longer lists the skill"
fi
rm -rf "$home"

finish
