---
name: kiss-principles
description: "Use when writing, reviewing, or refactoring code and a design may be more complex than the current requirements need: an interface with one implementation, an extra layer that only forwards calls, a generic type or config option with one value, a design pattern for a simple case, a class with many constructor dependencies, or a choice between duplicating code and extracting a shared abstraction."
---

# KISS Principle

Reference for the KISS (Keep It Simple, Stupid) principle: over-engineering detection, simplicity heuristics, and complexity calibration.

**The existing codebase wins.** Its conventions, architecture, and style come first. This skill adapts to the project, not the other way round. Use the `// KISS:` and `// KISS-DEVIATION:` marker comments only when the codebase already uses them.

## Existing Code Comes Before KISS

KISS picks the simplest solution among the ones that fit the codebase. It never justifies a new, simpler parallel solution next to an existing one. Work through these steps in order:

1. **Match the existing style.** Write the code the way the codebase already writes this kind of code: structure, patterns, naming, error handling. A consistent solution beats a simpler one that looks different from the rest of the application.
2. **Reuse what exists.** Before writing new code, search the codebase for a component, helper, or service that already solves this problem. If one exists, use it, even when a hand-written version would be shorter.
3. **Make an existing solution reusable.** If a solution for the same problem exists but is locked inside one feature, extract it into a reusable component and use it in both places. Do not write a second copy.
4. **Propose, don't silently simplify.** If you think the existing reusable component could be much simpler, do not rewrite it as part of your task. Use it as it is, then describe the simpler design to the user and ask for approval before you change it.

Steps 2 and 3 apply when the existing code solves the same problem: the same rule or contract, the same reason to change. Code that only looks similar is not the same problem; see Premature Abstraction below.

**Code examples:** `examples/over-engineering.dart`

**Related skills:** `solid-principles` (KISS counterbalances SOLID ceremony), `dry-principles` (KISS prevents premature DRY extraction).

## Core Principle

**The simplest solution that meets current requirements wins.**

Complexity has two dimensions:
1. **Too many parts**: unnecessary classes, interfaces, layers, abstractions
2. **Too many interconnections**: excessive coupling, deep dependency chains, indirect communication paths

## Simplicity Heuristics

Four concrete tests to evaluate whether a solution is too complex:

### Comprehension Test
> "Can someone unfamiliar with this code understand its intent within reasonable onboarding time?"

If the design requires deep context to understand, either the problem genuinely demands that complexity (document the rationale) or the solution has unnecessary indirection. Patterns like CQRS or domain events are not over-engineering when the problem warrants them.

### Necessity Test
> "Is there a simpler way that meets CURRENT requirements?"

Emphasis on current. "We might need it later" is not a current requirement.

### Deletion Test
> "If I deleted this abstraction, what concrete problem reappears?"

If you can't name a specific, present-tense problem, the abstraction isn't earning its keep. If the codebase uses a layered architecture (for example Clean Architecture), its standard layers serve structural consistency and testability; those are present-tense reasons. This test targets extra abstractions *within* or *beyond* those layers.

### Explanation Test
> "Can I explain this design in one sentence without using 'flexible', 'extensible', or 'reusable'?"

If the only justification uses future-tense words, the complexity serves a hypothetical need.

## Over-Engineering Anti-Patterns

### Premature Polymorphism

Creating an interface with a single implementation when no architectural boundary or test isolation requires it.

**Justified single-implementation interfaces:** a layer or module boundary the codebase's architecture requires, test isolation, API contract stability between teams.

**Detection:** Interface + single implementation + no required boundary + no test mock + no cross-team contract = premature polymorphism.

### Lasagna Architecture

Extra layers that add no logic: a facade between controller and service, a wrapper around a wrapper.

**Important:** If the codebase has a standard layer model, this targets layers that don't belong to it, NOT thin-but-structurally-correct standard layers. A thin service is the correct shape for a simple operation.

**Detection:** A class outside the codebase's standard layers where every method delegates to another class with the same signature.

### Premature Abstraction (Wrong-Abstraction Guards)

Extracting a shared abstraction from coincidental similarity: cases that share structure without sharing a meaningful concept.

**Rule (knowledge-based, never count-based):** extract at the SECOND occurrence when the cases share knowledge (same rule or contract, same reason to change) AND the extraction passes three guards: a clean name without "and"/"or", zero boolean flags or mode params at birth, and all callers change for the same reason. Coincidental shape-similarity is never extracted, at any count. One-liners never earn the indirection. For infrastructure concerns the project has already decided on (logging, HTTP, persistence), use the framework or library the codebase already uses from the FIRST occurrence instead of hand-rolling a new mechanism.

**Detection:** a shared abstraction whose name contains "and"/"or", or that needed a flag/mode parameter at birth to serve its callers.

### Configuration Ceremony

Making things configurable that will never be configured. Adding options, flags, and parameters for hypothetical flexibility.

**Detection:** Configuration parameters that have only ever had one value. Generic type parameters instantiated at one concrete type.

### Pattern Worship

Applying a design pattern where a simpler construct suffices. A Strategy pattern for two stable variants. A full state-management class with immutable state objects and code generation for a single boolean toggle.

**Detection:** The pattern's structural overhead exceeds the logic it contains.

## The KISS-DRY Tension

When KISS and DRY conflict, **prefer KISS until the duplication becomes a maintenance risk**. For wrong abstraction detection and recovery, see the `dry-principles` skill.

### Decision Table

| Situation | Action |
|-----------|--------|
| An existing solution already solves this problem | Reuse it; make it reusable first if it is locked inside one feature |
| 2+ blocks that share knowledge (same rule, same reason to change) | Extract, if the extraction passes the wrong-abstraction guards above |
| 2 blocks that only look similar | Duplicate — too early to know if they share a concept |
| Similar structure, different business reasons | Duplicate — they will diverge (see `dry-principles` for coincidental similarity) |
| Varies by multiple dimensions | Duplicate — shared abstraction becomes configuration nightmare |

## The KISS-SOLID Balance

SOLID ceremony is justified when the problem demands it. It's over-engineering when it exceeds the problem's complexity. See `solid-principles` for when deviation from specific SOLID principles is acceptable.

### The Balance Point
> "Is there a concrete, present-tense reason for this abstraction?"

- **Yes, a boundary the architecture requires** (for example the Dependency Rule in a layered codebase) → add the interface
- **Yes, test isolation** → add the interface
- **Yes, API contract stability** → add the interface
- **Yes, 3+ implementations exist** → add the interface
- **No, maybe someday** → don't add it (KISS wins over speculative SOLID)

## KISS Applied to Architecture

### Constructor Dependencies as Complexity Signal

If the codebase uses constructor injection:

- **0-5 dependencies**: healthy
- **6-7 dependencies**: review whether responsibilities should split
- **8+ dependencies**: almost certainly an SRP violation

### Choosing the Right Level of Ceremony

If the codebase uses a layered architecture, keep its standard layers. KISS applies to how much logic lives *within* each layer:

| Complexity | Service Shape |
|-----------|----------|
| Simple CRUD, no business rules | Thin pass-through that delegates to the data layer. Still present when the codebase's layering expects it, for consistency and as a seam. |
| One business rule | Thin service with the rule inline |
| Orchestration across multiple concerns | Full service with injected dependencies |
| Cross-aggregate coordination | Domain events, if the codebase already uses them |

If the codebase has no such layering, do not introduce it for a simple feature.

### Start Simple Within the Structure

Keep implementations simple and add ceremony as complexity grows. A service method that starts as 3 lines of delegation is fine: it's a placeholder in the right place.

## Red Flags Checklist

| # | Red Flag | Likely Anti-Pattern |
|---|----------|-------------------|
| 1 | Interface with exactly one implementation (no required boundary, no test mock) | Premature Polymorphism |
| 2 | Generic type parameter instantiated at one concrete type | Configuration Ceremony |
| 3 | Abstract base class with one subclass | Premature Abstraction |
| 4 | Extra layer where every method delegates to another class | Lasagna Architecture |
| 5 | Design pattern where a conditional or direct call suffices | Pattern Worship |
| 6 | Configuration parameter that has only ever had one value | Configuration Ceremony |
| 7 | Generic base class shared by 2 unrelated concepts | Wrong Abstraction (see `dry-principles`) |
| 8 | Heavy state-management machinery (state class, immutable state object, code generation) for a single boolean | Pattern Worship |
| 9 | 8+ constructor dependencies | Complexity signal (see `solid-principles` SRP) |

## Severity Classification

### High (Should fix before merge)
- Extra forwarding-only layer, outside the codebase's standard structure, that adds zero logic

### Medium (Fix soon)
- Premature abstraction with single usage and no justification
- Design pattern where a conditional suffices
- Wrong abstraction forcing unrelated concerns through shared base

### Low / Suggestions
- Configuration parameter with a single known value
- Opportunity to simplify logic within an existing layer

## Documentation Convention

Only when the codebase already uses these markers. Otherwise follow its existing comment style.

**`// KISS:` (applying simplicity):**
```
// KISS: Single implementation, no required boundary — concrete class sufficient
// KISS: 2 stable variants, switch preferred over Strategy pattern
```

**`// KISS-DEVIATION:` (knowingly adding complexity):**
```
// KISS-DEVIATION: Full Strategy pattern justified — 4 payment providers with different auth flows
// KISS-DEVIATION: Generic base class needed — 5 list views share identical pagination logic
```
