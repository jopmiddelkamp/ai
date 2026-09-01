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
