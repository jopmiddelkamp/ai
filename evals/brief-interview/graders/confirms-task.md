---
type: llm
---

PASS if the reply restates the task as "As I understood, you want ..." (or very close wording) and asks the user to confirm it, for example with "Right?".
FAIL if it does not restate the task, or goes on to the guardrails without asking the user to confirm the task first.
