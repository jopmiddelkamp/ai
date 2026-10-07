---
name: dry-principles
description: "Use when writing, refactoring, or reviewing code that duplicates logic, rules, constants, or models; when deciding whether to extract shared code or keep copies; when shared code grows boolean flags or conditionals; when client and server validation may drift; or when test setup feels repetitive or over-shared."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# DRY: one home for each piece of knowledge

DRY is about knowledge, not code. Two identical-looking blocks are not always a violation. Two different-looking blocks are a violation when they encode the same business rule. The test: **if this rule changes, how many places must I update?** More than one is a DRY violation, whether or not the code looks alike.

**The codebase comes first.** Its conventions, structure, and style win. Before writing new code, look for an existing reusable solution in the codebase and use it. Use `// DRY:` or `// DRY-DEVIATION:` marker comments only when the codebase already uses them; otherwise explain the decision in a normal comment or the PR description, and leave the markers out of your answer.

**When you review or advise on code,** label each finding with its severity from the review checklist below and list the most severe first. Explain each finding by the principle and its reason, not by this skill or its tables, because the reader has not seen them. Keep the answer to the findings, each stated once: what, severity, why, and the fix. Stay inside the code shown and the question asked: no sections on topics outside this principle, no redesign sketch or target-shape code, and no findings about code that does not exist yet. State as fact only what the code or the user shows; call anything else an assumption.

Related skills: `kiss-principles` (extraction timing and the wrong-abstraction guards) and `solid-principles` (the SRP-DRY tension). Code examples, language illustrative only: `examples/real-vs-coincidental.dart`, `examples/wrong-abstraction.dart`, `examples/violations.md`, `examples/damp-tests.dart`.

## Do these change for the same reason?

| Kind | How to recognize it | Action |
|---|---|---|
| Knowledge duplication | The same business rule. The copies change for the same reason at the same time. Example: one fee calculation in both the payment flow and the transfer flow. | Extract |
| Coincidental similarity | Looks alike, but different concepts that change for different reasons or at different times. Example: `CreatePaymentInput` and `CreateTransferInput` both have `amount`, `currency`, and `description`, but their validation evolves independently. | Keep separate |
| Structural similarity | A repeated convention, such as constructor injection in every service. It changes only when the pattern itself changes. | Document the pattern; do not abstract the instances |

Name the shared concept before you extract. If the best name is `SharedHelper`, `CommonUtils`, or `BaseProcessor`, you have not found the abstraction yet. A good name describes the knowledge being shared, not the code structure.

## When duplication is correct

The coupling cost of sharing can exceed the duplication cost:

- **Across architectural layers.** A domain `Payment`, an application `PaymentDto`, an API `PaymentResponse`, and a UI `PaymentViewState` are four correct representations, not duplication. Mapper code between them is structural; do not extract a generic mapper, because each boundary evolves on its own.
- **Across bounded contexts or separately deployed services.** Each owns its own models. A shared model library creates a deployment dependency and a version-sync burden that cost more than the duplication.
- **When the actors differ (DRY vs SRP).** The same logic serving different stakeholders is coincidental. Example: fees for customer-facing payments and fees for internal reconciliation share a formula today, but promotions will change one and not the other. SRP wins.

| Scope | Action | Coupling cost |
|---|---|---|
| Within a class | Extract a method | None |
| Within a module or feature | Extract a shared class in the same module | Low |
| Across features in one product | Shared module with clear ownership; worth it for business rules | Medium |
| Across separately deployed services | Keep duplicated | High |
| Across bounded contexts | Keep duplicated | Very high |

## Within one product: one source of truth

Within one product, shared constants and business rules have one authoritative home. With a backend and one or more clients (web, mobile, portal), the API contract is the source of truth. If the codebase already generates types or validation schemas from it (a database schema, an OpenAPI spec, a shared schema package), use the generated artifacts. Server validation is authoritative; client validation is advisory and exists for UX. A client must not hand-write its own model or validation of a server concept: when client and server rules differ, that is a DRY violation. See `examples/violations.md` for validation drift.

## The wrong abstraction

"Duplication is far cheaper than the wrong abstraction" (Sandi Metz). These signals mean shared code now serves several concepts:

| Signal | What it means |
|---|---|
| Boolean or mode parameters that control behavior | The abstraction serves several concepts |
| Growing conditional chains inside shared code | The cases are diverging, not converging |
| Callers pass `null` or empty values for unused parameters | The interface is too broad for some callers |
| "I need to understand all callers to change this" | Coupling exceeds the value of sharing |
| A base class whose subclasses override most methods | Inheritance serves code reuse, not "is-a" |
| Comments like `// only used by X` inside shared code | The sharing is no longer symmetric |

The fix is **inline and re-extract**: inline the shared code back into each caller, accept the temporary duplication, let the natural groupings appear, then re-extract only the knowledge that is truly shared. Adding more parameters or conditionals makes it worse. When other code depends on the abstraction, propose the change and get approval first instead of restructuring it silently. See `examples/wrong-abstraction.dart`.

## Tests: DAMP, not DRY

DAMP means descriptive and meaningful phrases. In test code, share the "how" and keep the "what" explicit:

- **Share:** builders, factories, fixtures, setup helpers, custom matchers for domain checks, common mock setup.
- **Keep explicit:** each test scenario tells its whole story, with visible arrange and assert sections.

Optimize for the readability of one test, not for fewer total lines. Follow the test style the codebase already uses. See `examples/damp-tests.dart`.

## Review checklist

| # | Check | Severity |
|---|---|---|
| 1 | The same business rule in several places, so one rule change touches many files | High |
| 2 | New code that duplicates an existing reusable solution in the codebase | High |
| 3 | Growing conditionals in shared code | High |
| 4 | Frontend and backend validation drift | High |
| 5 | Magic numbers for one business decision without a named constant, such as `3600` (token expiry), `0.015` (fee), `3` (max retries) in several files | Medium |
| 6 | Copy-paste with incidental, not intentional, differences | Medium |
| 7 | Boolean parameters on shared methods | Medium |
| 8 | A shared library between separately deployed services | Medium |

Also watch for parallel class hierarchies that mirror each other and must change in lockstep.

## Marker comments

Only when the codebase already uses them:

```
// DRY: Coincidental similarity — payments and transfers evolve independently
// DRY: Separate bounded contexts — duplication accepted over shared library coupling
// DRY-DEVIATION: Fee calculation duplicated in reconciliation job — scheduled for extraction
// DRY-DEVIATION: Validation rules duplicated client/server — contract generation not yet available
```
