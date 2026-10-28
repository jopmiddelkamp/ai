---
type: llm
---

Judge only the PR comment text in the reply, not any chat lines around it.

PASS if the comment is written in Dutch, and keeps the technical terms in English the way Dutch developers say them (for example rebase, merge, commit, branch, merge conflict, pipeline), and conjugates any English verb by Dutch rules (for example gerebased or gemerged, never a bare English "rebased" inside a Dutch sentence).
FAIL if the comment is not in Dutch, or translates a technical term into a Dutch word that Dutch developers do not use, or uses an English verb form inside a Dutch sentence. Name the problem.
