#!/usr/bin/env bash
# Build the claude.ai preferences text: memory/CLAUDE.md first, then the
# output-style body. claude.ai has no API for preferences, so the last step
# stays manual: paste the clipboard into Settings -> Profile -> Preferences.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Print a file without its opening YAML frontmatter block.
strip_frontmatter() {
  awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm' "$1"
}

build() {
  cat "$REPO_ROOT/memory/CLAUDE.md"
  printf '\n'
  strip_frontmatter "$REPO_ROOT/output-styles/eli5.md"
}

# Piped or redirected output gets the raw text, so tests and files work.
if [ -t 1 ] && command -v pbcopy >/dev/null 2>&1; then
  build | pbcopy
  printf 'Copied %s characters to the clipboard.\n' "$(build | wc -c | tr -d ' ')"
  printf 'Paste into claude.ai -> Settings -> Profile -> Preferences.\n'
else
  build
fi
