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

printf 'aws_access_key_id: AKIAIOSFODNN7EXAMPLE\n' >"$tmp/awskey.txt"
bash "$script" "$tmp/awskey.txt" >/dev/null 2>&1
assert_rc 1 $? "an AWS access key id is caught"

printf 'token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c\n' >"$tmp/jwt.txt"
bash "$script" "$tmp/jwt.txt" >/dev/null 2>&1
assert_rc 1 $? "a JWT-shaped string is caught"

printf 'pinned: 523374dee72d67c7b2b5f858ea0094ffda49c3ac\n' >"$tmp/sha2.txt"
bash "$script" "$tmp/sha2.txt" >/dev/null 2>&1
assert_rc 0 $? "a 40-character lowercase git hash is still allowed"

printf 'Authorization: Bearer sk-abcdefghijklmnopqrstuvwxyz012345' >"$tmp/nonewline.txt"
bash "$script" "$tmp/nonewline.txt" >/dev/null 2>&1
assert_rc 1 $? "an unterminated last line is still scanned"

# --staged must read the index, not the working tree. Stage a fake key in a
# throwaway repo, then overwrite the working copy without re-staging.
stage_repo=$(mktemp -d "${TMPDIR:-/tmp}/aicfg.XXXXXX")
mkdir -p "$stage_repo/scripts"
cp "$script" "$stage_repo/scripts/check-secrets.sh"
git -C "$stage_repo" init -q
git -C "$stage_repo" config user.email "test@example.com"
git -C "$stage_repo" config user.name "Test"
printf 'token: ghp_abcdefghijklmnopqrstuvwxyz0123456789\n' >"$stage_repo/leak.txt"
git -C "$stage_repo" add leak.txt
printf 'nothing to see here\n' >"$stage_repo/leak.txt"
bash "$stage_repo/scripts/check-secrets.sh" --staged >/dev/null 2>&1
assert_rc 1 $? "--staged reads the index, not the working tree"
rm -rf "$stage_repo"

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
