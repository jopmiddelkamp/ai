#!/usr/bin/env bash
# Zip each skill folder so you can upload it to claude.ai. claude.ai has no
# API for profile skills, so the last step stays manual: drag the zip into
# Settings -> Capabilities -> Skills.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SKILLS_DIR="$REPO_ROOT/skills"
OUT_DIR="$REPO_ROOT/tmp/web-skills"

usage() {
  cat <<'USAGE'
Usage: bash scripts/web-skills.sh [skill-name ...]

With no name it packages every skill in skills/. Each zip holds the skill
folder at its root, which is what claude.ai expects.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

command -v zip >/dev/null 2>&1 || { printf 'zip is not installed.\n' >&2; exit 1; }

names=()
if [ "$#" -gt 0 ]; then
  names=("$@")
else
  while IFS= read -r d; do names+=("$(basename "$d")"); done \
    < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi

rc=0
for name in "${names[@]}"; do
  if [ ! -f "$SKILLS_DIR/$name/SKILL.md" ]; then
    printf 'skip %s: no skills/%s/SKILL.md\n' "$name" "$name" >&2
    rc=1
    continue
  fi
  mkdir -p "$OUT_DIR"
  rm -f "$OUT_DIR/$name.zip"
  (cd "$SKILLS_DIR" && zip -qr "$OUT_DIR/$name.zip" "$name" -x '*.DS_Store')
  printf 'packaged %s\n' "$OUT_DIR/$name.zip"
done

printf '\nUpload these in claude.ai -> Settings -> Capabilities -> Skills.\n'
printf 'Replace the old version of a skill you already uploaded.\n'
exit "$rc"
