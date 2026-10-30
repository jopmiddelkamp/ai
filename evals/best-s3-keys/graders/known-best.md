---
type: llm
---

PASS if the reply says the keys need no lasting copy outside the server, because lost keys can be revoked and new ones created without losing data; it keeps them only briefly (or recommends creating them right before writing `.env`) and puts them in `.env` with restricted permissions.
FAIL if the main recommendation is to store a lasting copy in a password manager, a vault, or a notes file.
