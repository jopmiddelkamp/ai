#!/usr/bin/env bash
# Claude Code status line — styled after Oh My Zsh robbyrussell theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Current directory basename (cyan, bold)
dir_part=""
if [ -n "$cwd" ]; then
  basename_dir=$(basename "$cwd")
  dir_part=$(printf '\033[1;36m%s\033[0m' "$basename_dir")
fi

# Git branch (blue/red styled like robbyrussell)
git_part=""
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty=$(printf ' \033[0;33m✗\033[0m')
  fi
  git_part=$(printf ' \033[1;34mgit:(\033[0;31m%s\033[1;34m)%s\033[0m' "$branch" "$dirty")
fi

# Model name (dimmed)
model_part=""
if [ -n "$model" ]; then
  model_part=$(printf ' \033[2m%s\033[0m' "$model")
fi

# Context usage
ctx_part=""
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  ctx_part=$(printf ' \033[2mctx:%s%%\033[0m' "$used_int")
fi

printf '%s%s%s%s' "$dir_part" "$git_part" "$model_part" "$ctx_part"
