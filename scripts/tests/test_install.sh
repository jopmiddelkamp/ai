#!/usr/bin/env bash
# install.sh links the global memory into a fake ~/.claude. Skills and output
# styles are not linked: the ai plugin delivers them.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo/scripts/install.sh"

# --- case 1: empty home gets the link ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 0 $? "install succeeds on an empty home"
assert_symlink_to "$home/.claude/CLAUDE.md" "$repo/memory/CLAUDE.md" "the global CLAUDE.md is linked"

# --- case 2: running twice changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" 2>&1)
assert_rc 0 $? "a second run succeeds"
assert_contains "$out" "0 changed" "a second run reports no change"
rm -rf "$home"

# --- case 3: a real file blocks the install ---
home=$(make_fake_home)
printf 'mine\n' >"$home/.claude/CLAUDE.md"
CLAUDE_DIR="$home/.claude" bash "$script" >/dev/null 2>&1
assert_rc 1 $? "a real file blocks the install"
assert_eq "mine" "$(cat "$home/.claude/CLAUDE.md")" "the real file is untouched"

# --- case 4: --dry-run reports the block and changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run 2>&1)
assert_rc 1 $? "--dry-run exits 1 when the path is blocked"
assert_contains "$out" "blocked  CLAUDE.md" "--dry-run names the blocked path"
assert_eq "mine" "$(cat "$home/.claude/CLAUDE.md")" "--dry-run leaves the real file alone"

# --- case 5: --dry-run --force previews the backup and changes nothing ---
out=$(CLAUDE_DIR="$home/.claude" bash "$script" --dry-run --force 2>&1)
assert_rc 0 $? "--dry-run --force exits 0"
assert_contains "$out" "backup" "--dry-run --force previews the backup"
assert_eq "mine" "$(cat "$home/.claude/CLAUDE.md")" "--dry-run --force changes nothing"
assert_eq "" "$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d)" "--dry-run --force creates no backup directory"

# --- case 6: --force backs the real file up ---
CLAUDE_DIR="$home/.claude" bash "$script" --force >/dev/null 2>&1
assert_rc 0 $? "--force succeeds"
assert_symlink_to "$home/.claude/CLAUDE.md" "$repo/memory/CLAUDE.md" "--force installs the link"
found=$(find "$home/.claude" -maxdepth 1 -name '.backup-*' -type d | head -1)
assert_eq "mine" "$(cat "$found/CLAUDE.md" 2>/dev/null)" "the backup keeps the old file"
rm -rf "$home"

# --- case 7: --dry-run on an empty home changes nothing ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --dry-run >/dev/null 2>&1
assert_rc 0 $? "--dry-run succeeds"
assert_no_file "$home/.claude/CLAUDE.md" "--dry-run creates no link"
rm -rf "$home"

# --- case 8: refuse to install into the repo itself ---
out=$(CLAUDE_DIR="$repo" bash "$script" --dry-run 2>&1)
assert_rc 2 $? "CLAUDE_DIR inside the repo exits 2"
assert_contains "$out" "inside the repo" "the error says why"
assert_eq "" "$(find "$repo/memory" -type l 2>/dev/null)" "no self-link was created in the repo"

# --- case 9: a bad option exits 2 ---
home=$(make_fake_home)
CLAUDE_DIR="$home/.claude" bash "$script" --nope >/dev/null 2>&1
assert_rc 2 $? "an unknown option exits 2"
rm -rf "$home"

finish
