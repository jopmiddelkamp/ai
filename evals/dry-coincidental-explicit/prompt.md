---
max_turns: 6
allowed_tools: [Skill]
tags: [dry, explicit]
---

Use your DRY principles skill if you have one. These two input types in our payments service look duplicated. Should I extract a shared base type for them? Payments and transfers are owned by different teams, and transfer limits are about to get a new compliance rule.

```ts
export interface CreatePaymentInput { amount: number; currency: string; description: string }
export function validatePayment(i: CreatePaymentInput) {
  if (i.amount <= 0) throw new Error("amount");
  if (i.description.length > 140) throw new Error("description");
}

export interface CreateTransferInput { amount: number; currency: string; description: string }
export function validateTransfer(i: CreateTransferInput) {
  if (i.amount <= 0) throw new Error("amount");
  if (i.description.length > 140) throw new Error("description");
}
```
