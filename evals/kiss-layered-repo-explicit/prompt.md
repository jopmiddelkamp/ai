---
max_turns: 6
allowed_tools: [Skill]
tags: [kiss, explicit]
---

Use your KISS principles skill if you have one. Review this new feature for over-engineering. It lives in our Clean Architecture codebase: every feature has a domain repository interface and a data-layer implementation, and the use-case tests mock the interface.

```ts
// domain/invoice-repository.ts
export interface InvoiceRepository { findOverdue(today: Date): Promise<Invoice[]> }

// data/invoice-repository-impl.ts
export class InvoiceRepositoryImpl implements InvoiceRepository {
  constructor(private db: Db) {}
  findOverdue(today: Date) { return this.db.invoices.where("dueDate", "<", today).toArray(); }
}

// domain/send-overdue-reminders.ts
export class SendOverdueReminders {
  constructor(private invoices: InvoiceRepository, private mailer: Mailer) {}
  async run(today: Date) {
    for (const inv of await this.invoices.findOverdue(today)) await this.mailer.remind(inv);
  }
}
```
