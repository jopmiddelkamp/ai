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
