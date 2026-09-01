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
finish
