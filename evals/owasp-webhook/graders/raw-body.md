---
type: llm
---

PASS if the route verifies the Stripe signature on the raw request body before it trusts or parses the event.
FAIL if it parses JSON and acts on the event without verifying the signature first.
