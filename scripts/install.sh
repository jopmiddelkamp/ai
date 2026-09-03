#!/usr/bin/env bash
# Link this repo's agent content into ~/.claude.
# The repo is the source of truth. This script never edits repo files.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
MANIFEST="$CLAUDE_DIR/.ai-repo-manifest"

DRY_RUN=0
FORCE=0
COPY=0
CHANGED=0
BLOCKED=0
NEW_MANIFEST=""

usage() {
  cat <<'USAGE'
Usage: install.sh [--dry-run] [--force] [--copy]

  --dry-run  Print the plan. Change nothing. Reports every path this script
             does not own as "blocked" and exits 1, so you see the whole
             picture before you decide on --force.
  --force    Replace a file this script does not own. Back it up first.
  --copy     Write copies instead of symlinks. Use only if links break.

Environment:
  CLAUDE_DIR  Target directory. Default: $HOME/.claude
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --copy) COPY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Refuse to install into the repo itself. If CLAUDE_DIR resolves inside
# REPO_ROOT then a destination can equal its own source, and two things go
# wrong at once: `rm -rf "$dest"` would delete the source, and `ln -s src dest`
# onto an existing directory silently creates a nested self-link inside it
# rather than failing. This has happened once, from a mistyped test.
CANON_CLAUDE_DIR=$(cd "$CLAUDE_DIR" 2>/dev/null && pwd || printf '%s' "$CLAUDE_DIR")
case "$CANON_CLAUDE_DIR" in
  "$REPO_ROOT"|"$REPO_ROOT"/*)
    printf 'install.sh: CLAUDE_DIR (%s) is inside the repo (%s).\n' "$CANON_CLAUDE_DIR" "$REPO_ROOT" >&2
    printf 'install.sh: that would make a destination its own source. Refusing.\n' >&2
    exit 2
    ;;
esac

OWNED=""
[ -f "$MANIFEST" ] && OWNED=$(cat "$MANIFEST")

is_owned() { printf '%s\n' "$OWNED" | grep -qxF "$1"; }
in_new_manifest() { printf '%s' "$NEW_MANIFEST" | grep -qxF "$1"; }

BACKUP_DIR="$CLAUDE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"

# install_one <absolute source> <path relative to CLAUDE_DIR>
install_one() {
  src="$1"
  rel="$2"
  dest="$CLAUDE_DIR/$rel"
  NEW_MANIFEST="$NEW_MANIFEST$rel
"

  if [ "$COPY" -eq 0 ] && [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi

  if [ -L "$dest" ] || is_owned "$rel"; then
    action="replace"
  elif [ -e "$dest" ]; then
    if [ "$FORCE" -eq 0 ]; then
      BLOCKED=$((BLOCKED + 1))
      printf '%-8s %s (exists, not owned by this repo)\n' "blocked" "$rel"
      # A dry run reports every blocked path and keeps going. Stopping at the
      # first one would hide the rest of the plan, which is the whole point of
      # a dry run. The exit code at the end still says a real run would fail.
      if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
      printf 'install.sh: %s exists and this script does not own it.\n' "$dest" >&2
      printf 'install.sh: run again with --force to back it up and replace it.\n' >&2
      exit 1
    fi
    action="backup"
  else
    action="create"
  fi

  CHANGED=$((CHANGED + 1))
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%-8s %s\n' "$action" "$rel"
    return 0
  fi

  if [ "$action" = "backup" ]; then
    # Keep the namespace in the backup path. A flat backup would let
    # output-styles/x.md and commands/x.md collide, and `mv` overwrites
    # silently, so one original would be lost while the script reported
    # success.
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
  elif [ "$action" = "replace" ]; then
    # A manifest-owned path is not always a symlink. `--copy` writes real files,
    # and a hand edit leaves real content behind. Deleting that outright loses
    # work while the script reports success, so back it up first. Only a symlink
    # is safe to remove without a copy: the content lives in the repo.
    if [ ! -L "$dest" ] && [ -e "$dest" ]; then
      mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
      cp -R "$dest" "$BACKUP_DIR/$rel"
    fi
    rm -rf "$dest"
  fi

  mkdir -p "$(dirname "$dest")"
  if [ "$COPY" -eq 1 ]; then
    cp -R "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  printf '%-8s %s\n' "$action" "$rel"
}

# Skills: one directory each.
for d in "$REPO_ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  install_one "${d%/}" "skills/$name"
done

# Output styles and commands: one file each.
for f in "$REPO_ROOT"/output-styles/*.md; do
  [ -f "$f" ] || continue
  install_one "$f" "output-styles/$(basename "$f")"
done

for f in "$REPO_ROOT"/commands/*.md; do
  [ -f "$f" ] || continue
  install_one "$f" "commands/$(basename "$f")"
done

# The global user memory: one file at the root of CLAUDE_DIR. Claude Code
# loads it in every session, no matter which output style is active.
if [ -f "$REPO_ROOT/memory/CLAUDE.md" ]; then
  install_one "$REPO_ROOT/memory/CLAUDE.md" "CLAUDE.md"
fi

# Remove anything we own that the repo no longer has.
if [ -n "$OWNED" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    in_new_manifest "$rel" && continue
    CHANGED=$((CHANGED + 1))
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '%-8s %s\n' "prune" "$rel"
    else
      # Same rule as above: never delete real content without a copy.
      if [ ! -L "${CLAUDE_DIR:?}/$rel" ] && [ -e "${CLAUDE_DIR:?}/$rel" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
        cp -R "${CLAUDE_DIR:?}/$rel" "$BACKUP_DIR/$rel"
      fi
      rm -rf "${CLAUDE_DIR:?}/$rel"
      printf '%-8s %s\n' "prune" "$rel"
    fi
  done <<<"$OWNED"
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$CLAUDE_DIR"
  printf '%s' "$NEW_MANIFEST" | grep -v '^$' | sort >"$MANIFEST"
fi

printf '%s changed\n' "$CHANGED"

if [ "$BLOCKED" -gt 0 ]; then
  printf '%s blocked; re-run with --force to back them up and replace them\n' "$BLOCKED" >&2
  exit 1
fi
