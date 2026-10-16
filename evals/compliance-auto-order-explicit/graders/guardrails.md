---
type: llm
---

PASS if the code includes at least two of these: an idempotency key, a spend or quantity limit, an approval check, a persisted order state, a kill switch.
FAIL if it calls the supplier API with none or only one of them.
