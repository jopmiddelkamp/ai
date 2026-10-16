---
max_turns: 8
allowed_tools: [Skill]
tags: [writing-readable-code, natural]
---

Fix this function: it must also skip orders with status "cancelled". Return only the changed function.

```ts
export function calc(o: Order[]) {
  let t = 0;
  for (const x of o) {
    if (x.status !== "refunded") { t += x.amt * x.qty; }
  }
  return t;
}
```
