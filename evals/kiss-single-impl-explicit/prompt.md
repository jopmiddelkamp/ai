---
max_turns: 6
allowed_tools: [Skill]
tags: [kiss, explicit]
---

Use your KISS principles skill if you have one. Review this design before I merge it. There is one formatter today, and no test mocks it.

```ts
export interface IUserNameFormatter { format(first: string, last: string): string }

export class DefaultUserNameFormatter implements IUserNameFormatter {
  format(first: string, last: string) { return `${first} ${last}`; }
}

export class UserNameFormatterFactory {
  static create(kind: "default" = "default"): IUserNameFormatter {
    switch (kind) { case "default": return new DefaultUserNameFormatter(); }
  }
}

// only caller
const name = UserNameFormatterFactory.create().format(user.first, user.last);
```
