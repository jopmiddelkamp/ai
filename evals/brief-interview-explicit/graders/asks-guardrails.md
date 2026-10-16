---
type: llm
---

PASS if the reply asks the user for the guardrails of the task and offers 3 or 4 suggested guardrails, each naming a concrete action or object that someone could check was broken (for example: do not email the client, do not change the report template).
FAIL if it offers no suggestions, offers only generic care such as 'be careful' or 'follow best practices', or does not ask about guardrails.
