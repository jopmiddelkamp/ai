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
