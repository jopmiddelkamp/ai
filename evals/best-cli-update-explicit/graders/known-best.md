---
type: llm
---

PASS if the recommendation records the path of the developer's existing checkout once (for example `git config --global <prefix>.source "$PWD"` at install time) and builds the release tag in a temporary, detached worktree or an equivalent that leaves the checkout's branch and working tree alone, with no second full clone.
FAIL if the main recommendation is a separate cache clone, a new config file, or anything that checks out the tag in the developer's own working tree.
