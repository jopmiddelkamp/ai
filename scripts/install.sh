#!/usr/bin/env bash
# Link this repo's global memory into ~/.claude/CLAUDE.md.
# Skills and output styles are NOT linked: the repo is a Claude Code plugin,
# and the plugin delivers skills/ and output-styles/ (see
# .claude-plugin/plugin.json and settings/plugins.md).
# The repo is the source of truth. This script never edits repo files.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SRC="$REPO_ROOT/memory/CLAUDE.md"
DEST="$CLAUDE_DIR/CLAUDE.md"

DRY_RUN=0
FORCE=0

usage() {
  cat <<'USAGE'
Usage: install.sh [--dry-run] [--force]

  --dry-run  Print the plan. Change nothing. Exits 1 when a real file blocks
             the link.
  --force    Replace a real file. Back it up first.

Environment:
  CLAUDE_DIR  Target directory. Default: $HOME/.claude
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Refuse to install into the repo itself. Then the destination could equal its
# own source, and the `rm` below would delete it. This has happened once, from
# a mistyped test.
CANON_CLAUDE_DIR=$(cd "$CLAUDE_DIR" 2>/dev/null && pwd || printf '%s' "$CLAUDE_DIR")
case "$CANON_CLAUDE_DIR" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    printf 'install.sh: CLAUDE_DIR (%s) is inside the repo (%s).\n' "$CANON_CLAUDE_DIR" "$REPO_ROOT" >&2
    printf 'install.sh: that would make a destination its own source. Refusing.\n' >&2
    exit 2
    ;;
esac

if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
  printf '0 changed\n'
  exit 0
fi

if [ -L "$DEST" ]; then
  action="replace"
elif [ -e "$DEST" ]; then
  if [ "$FORCE" -eq 0 ]; then
    printf '%-8s %s (exists, not a link to this repo)\n' "blocked" "CLAUDE.md"
    printf 'install.sh: run again with --force to back it up and replace it.\n' >&2
    exit 1
  fi
  action="backup"
else
  action="create"
fi

printf '%-8s %s\n' "$action" "CLAUDE.md"
[ "$DRY_RUN" -eq 1 ] && exit 0

if [ "$action" = "backup" ]; then
  backup_dir="$CLAUDE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  mv "$DEST" "$backup_dir/CLAUDE.md"
elif [ "$action" = "replace" ]; then
  rm -f "$DEST"
fi

mkdir -p "$CLAUDE_DIR"
ln -s "$SRC" "$DEST"
printf '1 changed\n'
