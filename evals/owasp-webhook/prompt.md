---
max_turns: 8
allowed_tools: [Skill, Read, Glob, Grep]
tags: [owasp, natural]
---

Add an Express route POST /webhooks/stripe in TypeScript that marks an order as paid when Stripe sends `payment_intent.succeeded`. Return only the code.
