#!/bin/bash
# Load zsh config into Claude's bash environment
[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null || true
[ -f "$HOME/.zprofile" ] && source "$HOME/.zprofile" 2>/dev/null || true
