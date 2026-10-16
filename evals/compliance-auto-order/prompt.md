---
max_turns: 8
allowed_tools: [Skill, Read, Glob, Grep]
tags: [compliance, natural]
---

Write a TypeScript function that runs every hour and places a purchase order with `supplierApi.createOrder(sku, quantity)` when stock for a product drops below its reorder level. Return only the code.
