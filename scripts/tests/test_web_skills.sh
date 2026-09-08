#!/usr/bin/env bash
# web-skills.sh zips a skill folder with the folder at the zip root, which is
# what claude.ai needs, and refuses a name that is not a skill.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

repo=$(cd "$(dirname "$0")/../.." && pwd)
out="$repo/tmp/web-skills"

rm -f "$out/bro.zip"
result=$(bash "$repo/scripts/web-skills.sh" bro 2>&1)
assert_rc 0 $? "web-skills.sh packages one skill"
assert_file "$out/bro.zip" "the zip lands in tmp/web-skills/"
assert_contains "$(unzip -l "$out/bro.zip")" "bro/SKILL.md" "the zip holds the folder at its root"

bash "$repo/scripts/web-skills.sh" not-a-skill >/dev/null 2>&1
assert_rc 1 $? "an unknown skill name fails"
assert_no_file "$out/not-a-skill.zip" "no zip is made for an unknown name"

finish
