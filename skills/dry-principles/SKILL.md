---
name: dry-principles
description: "Use when writing, refactoring, or reviewing code that duplicates logic, rules, constants, or models; when deciding whether to extract shared code or keep copies; when shared code grows boolean flags or conditionals; when client and server validation may drift; or when test setup feels repetitive or over-shared."
---

# DRY Principles

Reference for the DRY principle. Defines knowledge duplication vs coincidental similarity, when duplication is correct, the Wrong Abstraction lifecycle, and DAMP testing.

**The codebase comes first.** The existing project's conventions, structure, and style win. This skill adapts to the project, not the other way round. Before writing new code, look for an existing reusable solution in the codebase and use it. Only add marker comments such as `// DRY:` or `// DRY-DEVIATION:` when the codebase already uses them.

**Code examples:** `examples/real-vs-coincidental.dart`, `examples/wrong-abstraction.dart`, `examples/violations.md`, `examples/damp-tests.dart`. The language and framework in the examples are illustrative only.

**Related skills:** `solid-principles` (SRP-DRY tension when actors differ), `kiss-principles` (counterforce to premature extraction; see it for knowledge-based extraction guards and timing).

## The DRY Principle, Correctly Defined

> "Every piece of **knowledge** must have a single, unambiguous, authoritative representation within a system." — *The Pragmatic Programmer*, Hunt & Thomas

DRY is about **knowledge**, not **code**. Two identical-looking code blocks are not necessarily a DRY violation. Two different-looking code blocks can be a DRY violation if they encode the same business rule.

The key question: **"If this business rule changes, how many places do I need to update?"** If the answer is more than one, you have a DRY violation, whether or not the code looks similar.

## Three Types of Similarity

### 1. Knowledge Duplication (Semantic: Extract)

The same business rule or decision encoded in multiple places. When the rule changes, all copies must change together.

**Heuristic:** These change for the **same reason** at the **same time**.

**Example:** The same fee calculation in both a payment flow and a transfer flow. When the fee structure changes, both must update. This is one piece of knowledge in two places.

### 2. Coincidental Similarity (Syntactic: Keep Separate)

Code that looks similar today but represents different business concepts. It will diverge as requirements evolve.

**Heuristic:** These change for **different reasons** or at **different times**.

**Example:** A `CreatePaymentInput` and a `CreateTransferInput` both have `amount`, `currency`, and `description` fields. They look identical, but payments and transfers are different concepts with different validation rules that evolve independently.

### 3. Structural Similarity (Pattern: Document)

Repeated code structure that follows a convention or pattern (for example, every service class uses the same constructor injection). This is intentional consistency, not duplication.

**Heuristic:** These change when the **pattern itself** changes, not when individual business rules change.

### The Decision Heuristic

> **"Do these change for the same reason?"**

| Answer | Action |
|--------|--------|
| Yes, same business rule | Extract: this is knowledge duplication |
| No, different business concepts | Keep separate: this is coincidental similarity |
| Same pattern or convention | Document the pattern, don't abstract the instances |

See `examples/real-vs-coincidental.dart` for concrete scenarios.

## When Duplication Is Correct

Duplication is not always wrong. In these cases, the coupling cost of sharing exceeds the duplication cost.

### Across Architectural Layers

If the codebase uses layered architecture, DTOs, entities, and view models may have similar fields but serve different layers. Merging them couples the layers.

**Example:** A domain `Payment` entity, an application-layer `PaymentDto`, an API `PaymentResponse`, and a UI `PaymentViewState` are four correct representations of "payment", not duplication.

**Mapper code between these representations is structural, not duplicative.** Don't extract a generic mapper; each boundary has its own evolution path.

### Across Bounded Contexts or Separate Services

If the system has separate bounded contexts or separately deployed services, each owns its own models. Sharing models between them creates coupling that is worse than duplication.

### When Coupling Cost Exceeds Duplication Cost

Small-scale duplication within one module is sometimes preferable to a shared abstraction that couples unrelated features. See `kiss-principles` for extraction timing (knowledge-based, with wrong-abstraction guards) and the KISS-DRY decision table.

### Naming the Concept (Before Extracting)

If you can't name the shared concept better than "SharedHelper", "CommonUtils", or "BaseProcessor", you haven't found the abstraction yet. A good extraction has a name that describes the **knowledge** being shared, not the **code structure**.

## The Wrong Abstraction

> "Duplication is far cheaper than the wrong abstraction." — Sandi Metz

### The Lifecycle of Abstraction Decay

1. **Two similar cases appear.** A developer extracts shared code. Feels good.
2. **A third case is slightly different.** Add a boolean parameter. Manageable.
3. **A fourth case needs another variation.** Add another parameter. Getting complex.
4. **A fifth case is an edge case.** Add a conditional branch. Now the shared code is harder to understand than the duplication was.
5. **Nobody dares touch it.** The abstraction is load-bearing: everyone depends on it, nobody understands it.

### Red Flags of a Wrong Abstraction

| Signal | What It Means |
|--------|---------------|
| Boolean parameters controlling behavior | The abstraction serves multiple concepts |
| Growing conditional chains inside shared code | Cases are diverging, not converging |
| Callers passing `null` or empty values for unused parameters | The interface is too broad for some callers |
| "I need to understand all callers to change this" | Coupling exceeds the value of sharing |
| Shared base class where subclasses override most methods | Inheritance serves code reuse, not "is-a" |
| Comments like "// only used by X" inside shared code | The sharing is no longer symmetric |

### The Fix: Inline and Re-Extract

1. **Inline** the shared code back into each caller.
2. **Accept the temporary duplication.** This is a healthy intermediate state.
3. **Let the natural groupings emerge.** With all code visible, the real abstractions become clear.
4. **Re-extract** only the genuinely shared knowledge, if any exists.

Do NOT try to fix a wrong abstraction by adding more parameters or conditionals.

If the wrong abstraction is an existing shared component that other code depends on, propose the inline-and-re-extract change and get approval first. Don't restructure it silently.

See `examples/wrong-abstraction.dart` for a detailed lifecycle example.

## DRY Violations to Watch For

### Shotgun Surgery
A single business rule change requires modifying multiple files. The knowledge is scattered.

### Business Rules in Multiple Places
The same validation, calculation, or business decision implemented in more than one location.

### Magic Numbers
Literal values scattered through the codebase that represent one business decision. `3600` (token expiry), `0.015` (fee percentage), `3` (max retries) appearing in multiple files without a named constant.

### Copy-Paste with Minor Variations
Nearly identical blocks of code where the differences are incidental, not intentional.

### Parallel Hierarchies
Two class hierarchies that mirror each other and must be updated in lockstep.

## DRY vs SRP Tension

When DRY and SRP conflict, **SRP wins when actors differ**.

The same logic serving different stakeholders is coincidental similarity, not knowledge duplication. Even if the code is identical today, different stakeholders will drive divergence.

**Example:** Fee calculation for customer-facing payments vs fee calculation for internal reconciliation reports. Same formula today, but the customer-facing calculation might add promotional discounts while reconciliation stays on raw fees.

Cross-reference: `solid-principles`, SRP section.

## DRY vs Loose Coupling

| Scope | Action | Rationale |
|-------|--------|-----------|
| Within a class | Extract method | Zero coupling cost |
| Within a module or feature | Extract to a shared class in the same module | Low coupling cost |
| Across features in the same product | Shared module with clear ownership | Medium coupling cost; worth it for business rules |
| Across separately deployed services | **Keep duplicated** | High coupling cost; a shared library creates a deployment dependency |
| Across bounded contexts | **Keep duplicated** | Very high coupling cost; different models, different evolution |

## DRY Across Services and Clients

### Separate Products: Accept Duplication

Separately deployed services or products with independent bounded contexts should accept duplication. Sharing models between them creates deployment coupling and a version synchronization burden.

### Within One Product: Single Source of Truth

Within a single product, shared constants and business rules have one authoritative source.

### Frontend-Backend Contract Sync

If one product has a backend and one or more clients (web, mobile, portal), the API contract is the **single source of truth**. If the codebase already generates types or validation schemas from that contract (for example, from a database schema, an OpenAPI spec, or a shared schema package), use the generated artifacts. Server validation is authoritative; client validation is advisory and exists for UX. Clients should not hand-write their own model or validation of a server concept. When client and server rules differ, that is a DRY violation.

See `examples/violations.md` for validation drift examples.

## DAMP in Tests

> DAMP: Descriptive And Meaningful Phrases

In test code, **DRY the "how" (infrastructure), allow duplication in the "what" (scenarios)**.

### What to DRY in Tests
- Test infrastructure: builders, factories, fixtures, setup helpers
- Assertion helpers: custom matchers for domain-specific checks
- Mock configuration: shared mock setups for common dependencies

### What to Allow Duplication In
- Test scenarios: each test tells a complete story
- Arrange sections: explicit setup makes preconditions visible
- Assert sections: explicit assertions make the expected outcome visible

Test code optimizes for **readability at the individual test level**, not for minimizing total lines. Follow the test style the codebase already uses.

See `examples/damp-tests.dart` for DAMP testing examples.

## DRY Code Review Checklist

| # | Check | Severity |
|---|-------|----------|
| 1 | Same business rule in multiple places | High |
| 2 | New code that duplicates an existing reusable solution in the codebase | High |
| 3 | Magic numbers without named constants | Medium |
| 4 | Copy-paste with minor variations | Medium |
| 5 | Growing conditionals in shared code | High |
| 6 | Boolean parameters on shared methods | Medium |
| 7 | Frontend/backend validation drift | High |
| 8 | Shared library between separately deployed services | Medium |

## Documentation Convention (Only If the Codebase Uses It)

If the codebase already marks DRY decisions in comments, follow its format. A common shape:

**`// DRY:`: applying the principle** (explaining why duplication is kept):
```
// DRY: Coincidental similarity — payments and transfers evolve independently
// DRY: Separate bounded contexts — duplication accepted over shared library coupling
```

**`// DRY-DEVIATION:`: knowingly violating** (duplicating knowledge):
```
// DRY-DEVIATION: Fee calculation duplicated in reconciliation job — scheduled for extraction
// DRY-DEVIATION: Validation rules duplicated client/server — contract generation not yet available
```

If the codebase does not use these markers, explain the decision in a normal comment or the PR description instead.
