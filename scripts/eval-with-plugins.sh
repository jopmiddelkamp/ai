#!/usr/bin/env bash
# Run eval cases with other installed plugins loaded next to the ai plugin.
# `claude plugin eval` loads only the plugin under test, so a skill that calls
# another plugin's skill (pr-comment-style calls humanizer) cannot show that
# call in evals/. This script copies the cases into evals-with.local/, which
# git ignores. Each copy gets a minimal ai plugin, a copy of each named
# plugin, and one grader per named plugin that checks one of its skills ran.
# The copies never reach git, so the repo still stores no skill from another
# repo.
#
# Usage:
#   bash scripts/eval-with-plugins.sh <case glob> <plugin@marketplace>... [-- <eval args>]
#   bash scripts/eval-with-plugins.sh --build-only <dir> <case glob> <plugin@marketplace>...
# Example:
#   bash scripts/eval-with-plugins.sh 'prcs-*' humanizer@humanizer -- --runs 3 -j 4
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR=${CLAUDE_DIR:-$HOME/.claude}
INSTALLED="$CLAUDE_DIR/plugins/installed_plugins.json"
EVAL_DIR=evals-with.local

die() { printf 'eval-with-plugins: %s\n' "$1" >&2; exit 1; }

out="$REPO_ROOT/$EVAL_DIR"
build_only=0
if [ "${1:-}" = "--build-only" ]; then
  [ $# -ge 2 ] || die "--build-only needs a directory"
  out=$2 build_only=1
  shift 2
fi
[ $# -ge 2 ] || die "usage: eval-with-plugins.sh <case glob> <plugin@marketplace>... [-- <eval args>]"
glob=$1
shift

ids=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do ids+=("$1"); shift; done
[ "${1:-}" = "--" ] && shift
[ "${#ids[@]}" -gt 0 ] || die "name at least one plugin, such as humanizer@humanizer"

command -v jq >/dev/null 2>&1 || die "jq is required"
[ -f "$INSTALLED" ] || die "$INSTALLED does not exist"

# Prefer the user-scope install; a project-scope one points at the same cache.
install_path() {
  jq -r --arg id "$1" \
    '(.plugins[$id] // []) | (map(select(.scope == "user")) + .) | .[0].installPath // empty' \
    "$INSTALLED"
}

names=()
paths=()
for id in "${ids[@]}"; do
  path=$(install_path "$id")
  [ -n "$path" ] && [ -d "$path" ] || die "$id is not installed"
  names+=("${id%@*}")
  paths+=("$path")
done

# Keep earlier results; rebuild only the cases.
mkdir -p "$out"
find "$out" -mindepth 1 -maxdepth 1 ! -name results -exec rm -rf {} +

entries='"ai-plugin"'
for name in "${names[@]}"; do entries="$entries, \"$name-plugin\""; done
extra_turns=$((2 * ${#names[@]}))

built=0
for src in "$REPO_ROOT"/evals/$glob/; do
  [ -d "$src" ] || continue
  case_name=$(basename "$src")
  prompt="$src/prompt.md"
  [ -f "$prompt" ] || die "$case_name has no prompt.md; only prose cases are supported"
  grep -q '^plugins:' "$prompt" && die "$case_name already sets plugins:"

  dest="$out/$case_name"
  cp -R "$src" "$dest"
  mkdir -p "$dest/ai-plugin"
  cp -R "$REPO_ROOT/.claude-plugin" "$REPO_ROOT/skills" "$REPO_ROOT/output-styles" "$dest/ai-plugin/"

  for i in "${!names[@]}"; do
    cp -R "${paths[$i]}" "$dest/${names[$i]}-plugin"
    printf -- '---\ntype: tool_used\ntool: Skill\ninput_match: %s\narm: with-only\n---\n' \
      "'\"skill\"\\s*:\\s*\"${names[$i]}:'" >"$dest/graders/${names[$i]}-fired.md"
  done

  # Each extra plugin's skill call costs turns, so raise max_turns to match.
  awk -v entries="$entries" -v extra="$extra_turns" '
    NR == 1 && $0 == "---" { print; print "plugins: [" entries "]"; fm = 1; next }
    fm && $0 == "---" { fm = 0 }
    fm && /^max_turns:/ { print "max_turns: " $2 + extra; next }
    { print }
  ' "$prompt" >"$dest/prompt.md"
  built=$((built + 1))
done
[ "$built" -gt 0 ] || die "no case in evals/ matches '$glob'"

if [ "$build_only" -eq 1 ]; then
  printf 'Built %s cases in %s\n' "$built" "$out"
  exit 0
fi
exec claude plugin eval "$REPO_ROOT" --eval-dir "$EVAL_DIR" "$@"
