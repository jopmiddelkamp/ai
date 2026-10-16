---
max_turns: 6
allowed_tools: [Skill]
tags: [dry, natural]
---

Our fee rule is copied in two services. Finance owns it, and whenever it changes, both places must change on the same day. What should I do?

```ts
// payment-service.ts
const fee = Math.max(0.5, amount * 0.029 + 0.3);

// transfer-service.ts
const transferFee = Math.max(0.5, amount * 0.029 + 0.3);
```
