---
max_turns: 6
allowed_tools: [Skill]
tags: [solid, explicit]
---

Use your SOLID principles skill if you have one. Review this class. List the problems by severity.

```ts
export class OrderHelper {
  async placeOrder(userId: string, items: Item[]) {
    const user = await Database.query("select * from users where id = $1", [userId]);
    const total = items.reduce((s, i) => s + i.price * i.qty, 0);
    if (user.type === "vip") { return this.saveOrder(userId, items, total * 0.9); }
    if (user.type === "staff") { return this.saveOrder(userId, items, total * 0.8); }
    return this.saveOrder(userId, items, total);
  }
  private saveOrder(userId: string, items: Item[], total: number) {
    return Database.query("insert into orders values ($1, $2, $3)", [userId, items, total]);
  }
}
```
