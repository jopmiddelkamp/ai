---
max_turns: 8
allowed_tools: [Skill, Read]
tags: [pr-comment-style, natural]
---

Write a PR comment for this: the retry loop in sync.ts has no maximum number of attempts, so when the server is down it retries forever. It does not block the merge; it is only a suggestion.
