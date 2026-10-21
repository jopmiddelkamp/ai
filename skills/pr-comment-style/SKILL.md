---
name: pr-comment-style
description: Use when writing or replying to a pull request comment, review comment, or review summary on GitHub, GitLab, Bitbucket, or Azure DevOps, or when a review flow needs findings posted to a PR. Triggers on "PR comment", "review comment", "reply in the thread", "post this on the PR", "draft a review summary", "write a nit".
---

# PR comment style

Two rules for every PR comment.

1. **Write it in the ELI5 output style.** Read `../../output-styles/eli5.md`, relative to this skill's base directory, and apply its rules to the comment. Its line "a skill that sets its own format wins" does not apply here: this skill picks that style.
2. **Run the humanizer skill on the draft.** Always, before you output or post the comment.

## Merge decision

Write these lines word for word, so the reader learns them once.

- A comment that blocks the merge ends with: `This blocks the merge.`
- A suggestion ends with: `This is just a suggestion. If you disagree, resolve this comment yourself.`
- A batched review body opens with: `Comments here block the merge unless the comment says it is a suggestion.` Comments in that review that block the merge then need no closing line.

## Output

- A comment the user pastes: one ```text block, or one ```markdown block when it holds a Mermaid diagram. Outside the block, write at most one line.
- A comment you post yourself with gh or the API: the raw text, no fence.
