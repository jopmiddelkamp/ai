---
max_turns: 8
allowed_tools: [Skill, Read]
tags: [pr-comment-style, natural]
---

Reply in the PR thread. The author asked: "Is the null check in getProfile really needed?" It is: getUser returns null for deleted users, and then the profile page crashes. This must block the merge.
