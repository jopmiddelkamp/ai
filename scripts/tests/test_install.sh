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
assert_file "$found/bro/SKILL.md" "the backup holds the old file"
rm -rf "$home"

# --- case 5: --dry-run changes nothing ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --dry-run >/dev/null 2>&1
assert_rc 0 $? "--dry-run succeeds"
assert_no_file "$home/.claude/skills/bro" "--dry-run creates no link"
assert_no_file "$home/.claude/.ai-repo-manifest" "--dry-run writes no manifest"
rm -rf "$home"

# --- case 6: --dry-run reports every blocked path and exits 1 ---
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

# --- case 7: --dry-run --force previews the backup and still changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run --force 2>&1)
rc=$?
assert_rc 0 $rc "--dry-run --force exits 0"
assert_contains "$out" "backup" "--dry-run --force previews the backup"
assert_eq "mine" "$(cat "$home/.claude/skills/bro/SKILL.md")" "--dry-run --force changes nothing"
assert_eq "" "$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d)" "--dry-run --force creates no backup directory"
rm -rf "$home"

# --- case 8: --copy writes real files, and is safe to repeat ---
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

# --- case 9: a bad option exits 2 ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --nope >/dev/null 2>&1
assert_rc 2 $? "an unknown option exits 2"
rm -rf "$home"

finish
