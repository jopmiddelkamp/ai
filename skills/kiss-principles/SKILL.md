---
name: kiss-principles
description: "Use when writing, reviewing, or refactoring code and a design may be more complex than the current requirements need: an interface with one implementation, an extra layer that only forwards calls, a generic type or config option with one value, a design pattern for a simple case, a class with many constructor dependencies, or a choice between duplicating code and extracting a shared abstraction."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# KISS: keep it simple

How to tell when an abstraction earns its place. The simplest solution that meets the current requirements wins. "We might need it later" is not a current requirement.

**When you review or advise on code,** label each finding with its severity from the red-flags table below and list the most severe first. Explain each finding by the principle and its reason, not by this skill or its tables, because the reader has not seen them. Keep the answer to the findings, each stated once: what, severity, why, and the fix. Stay inside the code shown and the question asked: no sections on topics outside this principle, no redesign sketch or target-shape code, and no findings about code that does not exist yet. State as fact only what the code or the user shows; call anything else an assumption.

## The codebase comes first

KISS picks the simplest solution among the ones that fit the codebase. It never justifies a second, simpler solution next to an existing one. Work in this order:

1. **Match the existing style:** structure, patterns, naming, error handling. A consistent solution beats a simpler one that looks different from the rest of the application.
2. **Reuse what exists.** Search for a component, helper, or service that already solves this problem, and use it, even when a hand-written version would be shorter.
3. **Make an existing solution reusable** when it is locked inside one feature. Extract it and use it in both places instead of writing a second copy.
4. **Propose, do not silently simplify.** If an existing component could be much simpler, use it as it is in your task. Then describe the simpler design to the user and ask for approval before you change it.

Steps 2 and 3 apply only to the same problem: the same rule or contract, the same reason to change. Code that only looks similar is a different problem.

Use `// KISS:` and `// KISS-DEVIATION:` marker comments only when the codebase already uses them. Related skills: `solid-principles` (KISS counterbalances SOLID ceremony) and `dry-principles` (KISS prevents premature extraction). Code examples: `examples/over-engineering.dart`.

## Four tests for a design

- **Necessity:** is there a simpler way that meets the current requirements?
- **Deletion:** if I delete this abstraction, which concrete, present-tense problem comes back? The standard layers of a layered codebase (for example Clean Architecture) pass this test through consistency and testability. The test targets extra abstractions within or beyond those layers.
- **Explanation:** can I explain the design in one sentence without "flexible", "extensible", or "reusable"? Future-tense words point at a hypothetical need.
- **Comprehension:** can someone new to the code understand its intent in normal onboarding time? CQRS or domain events are not over-engineering when the problem needs them; then document why.

## When an abstraction is justified

Add an interface or abstraction only for a concrete, present-tense reason:

- a boundary the architecture requires, such as the Dependency Rule in a layered codebase
- test isolation: a test uses a mock or fake through it
- API contract stability between teams
- 3 or more implementations exist

"Maybe someday" is not a reason. KISS wins over speculative SOLID.

**Extraction is knowledge-based, never count-based.** Extract at the second occurrence when the cases share knowledge (the same rule or contract, the same reason to change) and the extraction passes three guards:

1. a clean name without "and" or "or"
2. no boolean flag or mode parameter at birth
3. all callers change for the same reason

Never extract coincidental shape similarity, at any count. A one-liner never earns the indirection. For infrastructure the project has already decided on (logging, HTTP, persistence), use its existing framework or library from the first occurrence instead of hand-rolling a new mechanism.

| Situation | Action |
|---|---|
| An existing solution already solves this problem | Reuse it. Make it reusable first if it is locked inside one feature. |
| 2 or more blocks share knowledge | Extract, if the extraction passes the three guards |
| 2 blocks only look similar | Duplicate: it is too early to know if they share a concept |
| Similar structure, different business reasons | Duplicate: they will diverge |
| Variation along several dimensions | Duplicate: a shared abstraction becomes a configuration nightmare |

Prefer KISS over DRY until the duplication becomes a maintenance risk. For wrong-abstraction recovery, see `dry-principles`.

## Red flags

| Red flag | Anti-pattern | Severity |
|---|---|---|
| A class outside the codebase's standard layers where every method forwards to another class with the same signature | Lasagna architecture | High: fix before merge |
| Interface with one implementation, and no required boundary, no test mock, no cross-team contract | Premature polymorphism | Medium |
| Abstraction with one usage and no justification; abstract base class with one subclass | Premature abstraction | Medium |
| Shared abstraction whose name contains "and" or "or", or that needed a flag or mode parameter at birth | Premature abstraction | Medium |
| Design pattern where a conditional or direct call suffices: a Strategy for 2 stable variants, a state class with immutable state and code generation for one boolean | Pattern worship | Medium |
| Generic base class shared by 2 unrelated concepts | Wrong abstraction (see `dry-principles`) | Medium |
| Configuration parameter that has only ever had one value; generic type parameter used with one concrete type | Configuration ceremony | Low |
| Logic inside an existing layer that could be simpler | Simplification opportunity | Low |

**Constructor dependencies**, when the codebase uses constructor injection: 0-5 is healthy, 6-7 means review whether responsibilities should split, 8 or more is almost certainly an SRP violation (see `solid-principles`).

A thin layer that only delegates is not lasagna when the codebase's layer model expects that layer. A thin service is the correct shape for a simple operation.

## Ceremony per complexity

If the codebase has a layered architecture, keep its standard layers. KISS decides how much logic lives inside each layer:

| Complexity | Service shape |
|---|---|
| Simple CRUD, no business rules | Thin pass-through to the data layer, kept for consistency and as a seam when the layering expects it |
| One business rule | Thin service with the rule inline |
| Orchestration across several concerns | Full service with injected dependencies |
| Cross-aggregate coordination | Domain events, if the codebase already uses them |

If the codebase has no such layering, do not introduce it for a simple feature. Start simple inside the structure and add ceremony as complexity arrives. A service method that starts as 3 lines of delegation is a placeholder in the right place.

## Marker comments

Only when the codebase already uses them. Otherwise follow its existing comment style.

```
// KISS: Single implementation, no required boundary — concrete class sufficient
// KISS: 2 stable variants, switch preferred over Strategy pattern
// KISS-DEVIATION: Full Strategy pattern justified — 4 payment providers with different auth flows
// KISS-DEVIATION: Generic base class needed — 5 list views share identical pagination logic
```
