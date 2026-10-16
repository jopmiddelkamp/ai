---
type: llm
---

PASS if the reply recommends deleting or replacing the 'Double-check all your work' line, because the model already checks its work or because a runnable check (such as `pnpm test`) should replace it.
FAIL if it keeps that line as is.
