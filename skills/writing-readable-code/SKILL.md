---
name: writing-readable-code
description: "Use when writing, editing, refactoring, or generating any source code, script, query, config logic, or test, in any language, including one-line fixes. Triggers on 'implement', 'add', 'fix', 'refactor', 'write a function', 'write a script', 'production quality', and on any task that ends in a code change. Not for prose; not for reviewing someone else's PR (use review-pr)."
---

# Writing readable code

Write for a tired human who opens this file for the first time. Readable code passes two tests:

1. From a name and signature alone, the reader can predict what the function does.
2. The reader can follow the body top to bottom without opening another file.

The evidence behind each rule is in `references/evidence.md`.

## 1. Shape: the main path is obvious

- The happy path runs top to bottom at the lowest indent. Edge cases leave early through guard clauses.
- Nesting is at most 2 levels of control flow (`if`, loops, `try`). A deeper body becomes a named function.
- A condition with 3 or more parts becomes named booleans.
- Conditions are positive where possible: `isPaid`, not `!isUnpaid`.
- Each expression has at most one side effect, and it is the whole statement. No `i++` inside arguments, no assignment used as a value, no nested ternaries.
- A function is split when a part has its own clear name and purpose, never to hit a line count. Tightly related code stays together.
- A variable is declared next to its first use. A file reads in call order: the caller first, then what it calls.
- Lines are short, with few identifiers per line. A blank line separates each logical step.

## 2. Names

- Names use full words: `quantity`, not `qty`; `accumulator`, not `acc`. Exceptions: loop counters (`i`) and abbreviations the domain itself uses (`id`, `url`, `sku`).
- A name says what the value means in the domain: `paidOrders`, `revenueByCustomer`. Not the type (`orderList`), not filler (`data`, `result`, `info`, `item2`, `manager`, `helper`, `util`).
- A number carries its unit when the type does not: `timeoutMs`, `priceCents`.
- A boolean reads as a yes/no question: `isPaid`, `hasItems`.
- One concept has one name in the whole file. No aliases that only pass a value along.
- A function that is hard to name does too much. Split it, then name the parts.

## 3. Comments

- A comment explains why: a reason, a constraint, a trap, a link to an issue or spec.
- When a comment would explain what the code does, rename or extract a variable instead.
- Docstrings describe behavior the signature does not show: units, side effects, the edge-case result. A docstring that repeats the signature gets deleted.
- Finished code has no hedges ("should work", "for now") and no `TODO` stubs.

## 4. Fit in

- Style follows the surrounding code: naming case, error style, idioms, comment density, test layout.
- Run the project's formatter and linter when the project has them.
- Dead code, unused imports, debug prints, and scratch files get deleted.

## Final pass before you say "done"

Reread your own diff as a strict reviewer. Fix or delete each of these:

1. A name with an abbreviation or a filler word.
2. A comment that repeats the code.
3. Nesting deeper than 2 levels, or a condition with 3 or more unnamed parts.
4. A function with one caller that only wraps another call.

## Example

Before: abbreviations and a packed condition.

```ts
for (const [sku, qty] of skuQty) {
  if (qty > topSkuQuantity || (qty === topSkuQuantity && topSku !== null && sku < topSku)) {
    topSku = sku;
    topSkuQuantity = qty;
  }
}
```

After: full names and one named condition. The tie rule is a comment because it is a decision, not a fact the code shows.

```ts
for (const [sku, quantity] of quantityBySku) {
  // Ties go to the alphabetically first SKU, so the output is stable.
  const winsTie = quantity === topQuantity && sku < topSku;
  if (quantity > topQuantity || winsTie) {
    topSku = sku;
    topQuantity = quantity;
  }
}
```

## When rules conflict

- The user's explicit request beats this skill.
- The codebase's convention beats this skill for style: casing, layout, comment density.
- This skill beats the codebase's convention for narrating comments.
