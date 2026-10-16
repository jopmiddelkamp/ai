#!/usr/bin/env bash
# The one done-check for this repo: the test suite plus the secret scan.
# Passes only when it prints "ALL TESTS PASSED" and "clean".
set -uo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
bash "$repo/scripts/tests/run.sh" || exit 1
bash "$repo/scripts/check-secrets.sh" || exit 1
