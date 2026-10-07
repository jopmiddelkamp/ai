---
name: solid-principles
description: "Use when designing, refactoring, or reviewing classes, interfaces, or modules; when a class has many dependencies or a vague name like Manager, Helper, or Utils; when a switch or if-else chain dispatches on type or status; when an implementation throws not-implemented errors; when an interface has many methods; or when code news up services or calls infrastructure directly."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# SOLID principles

How to read each SOLID principle, the signals of a violation and their severity, and when a deviation is fine.

**When you review or advise on code,** label each finding with its severity from the review checklist below and list the most severe first. A signal without a fixed severity is Medium unless it blocks a change today. Report only violations the code shows, not possible ones. Explain each finding by the principle and its reason, not by this skill or its checklist, because the reader has not seen them. Keep the answer to the findings, each stated once: what, severity, why, and the fix. Stay inside the code shown and the question asked: no sections on topics outside this principle, no redesign sketch or target-shape code, and no findings about code that does not exist yet. State as fact only what the code or the user shows; call anything else an assumption.

**The codebase comes first.** Its conventions, architecture, and style win over this skill. Apply the principles inside the patterns the project already uses; do not introduce a new architecture, DI style, or layering to satisfy SOLID. A pattern the whole codebase uses on purpose is not a finding on its own: raise it as a proposal instead. Document a deviation the way the codebase documents such decisions; use a marker such as `// SOLID-DEVIATION: {reason}` only when the codebase already uses it.

Related skills: `kiss-principles` (counterweight to SOLID ceremony, constructor-dependency thresholds, extraction timing) and `dry-principles` (the DRY-SRP tension). Code examples, in Dart for illustration only: `examples/violations.md`, `examples/srp-examples.dart`, `examples/ocp-examples.dart`, `examples/lsp-examples.dart`, `examples/isp-examples.dart`, `examples/dip-examples.dart`.

## How to read each principle

- **SRP means one actor, not "one thing".** A class has one reason to change: it serves one stakeholder. If two stakeholders could request changes to the same class, it has two responsibilities. Static helpers that hide workflow orchestration inside domain logic mix two reasons to change.
- **OCP means add, do not modify.** A new variant arrives as new code, such as a new implementation, not as an edit to existing classes.
- **LSP means no surprises.** Every implementation behaves exactly as its abstraction promises. Write the interface contract as tests that every implementation passes. If one implementation needs special handling, the interface is too broad (split it), or the implementation does not belong behind it.
- **ISP means split by client need.** No client depends on methods it does not use; a query-only client does not see mutation methods. Follow the codebase's interface naming: `IUserReader`, `UserReader`, `UserReaderProtocol`.
- **DIP means depend on abstractions.** Business logic receives abstractions; the concrete implementation comes from outside, through the wiring the codebase already uses (a DI container, a composition root, providers, factory functions, module-level injection). Inner layers never depend on outer layers.

SRP per layer, when the codebase has layers (map this to the layers it actually has):

| Layer | SRP means |
|---|---|
| Domain | One aggregate or entity is one business concept. A `Payment` does not manage `Wallet` state. |
| Application | One service covers one aggregate's operations. `PaymentAppService` does not send notifications. |
| Interface adapters | One adapter wraps one external system. A payment provider adapter does not send email. |
| Frameworks | One configuration class covers one concern. Database config is separate from auth config. |

Without explicit layers, the same rule holds per module or file: one module, one reason to change.

## Review checklist

| # | Principle | Signal | Severity |
|---|---|---|---|
| 1 | DIP | Static calls to infrastructure (`Database.query()`, `HttpClient.get()`) from business logic or inner layers | Critical |
| 2 | OCP | Adding a variant requires modifying existing classes | High |
| 3 | LSP | An implementation throws not-implemented or unsupported (`NotImplementedException`, `UnsupportedOperationException`, `UnimplementedError`) | High |
| 4 | LSP | Code type-checks the implementation (`is`, `as`, `instanceof`, `typeof`) | High |
| 5 | DIP | `new ConcreteService()` in business logic | High |
| 6 | SRP | Too many constructor dependencies (thresholds in `kiss-principles`) | Medium |
| 7 | SRP | Class name contains Manager, Helper, Utils, or Processor | Medium |
| 8 | OCP | Growing switch or if-else chain that checks type, status, or variant | Medium |
| 9 | ISP | Interface with more than 7 methods serving different clients | Medium |
| 10 | ISP | Implementation provides dummy methods it does not need | Medium |

More signals, judged in context:

- **SRP:** more than 7 public methods serving different workflows; changes to unrelated features all modify the same class; the class's test file tests unrelated behaviors.
- **OCP:** enum-based dispatch where each value triggers different inline logic; adding one feature touches many files in the same way.
- **LSP:** different error semantics per implementation (one throws, one returns null, one returns a default); preconditions stricter or postconditions weaker than the interface promises.
- **ISP:** a client uses 2 of 10 methods; an interface change breaks unrelated implementations.
- **DIP:** constructor parameters typed as concrete service classes; a service locator such as `ServiceLocator.get<T>()`, unless the codebase has deliberately standardized on it.

## Violations cluster

When you find one violation, look for its siblings, and fix the root principle rather than the surface symptom.

| Symptom | Primary violation | Usually also |
|---|---|---|
| God service that does everything | SRP | ISP: a fat interface serving all clients |
| Switch or if-else selector | OCP | DIP: dispatch on concretions |
| Not-implemented error in an implementation | LSP | ISP: the interface is too broad for it |
| Utility class with 15 methods | SRP | ISP: clients use different subsets |
| Service locator | DIP | SRP: hidden dependencies obscure responsibilities |
| Every new feature modifies existing code | OCP | SRP: the class has several reasons to change |

## When a deviation is fine

- Value objects, DTOs, and domain entities are created directly and need no interface: `new Money(100, "EUR")`, `new Payment(...)`.
- Reading the current time directly is fine; consider a clock abstraction when tests need control over time.
- A single-implementation interface that keeps a layer boundary clean, if the codebase has layers, even with no second implementation planned.
- Simple CRUD, such as a GET endpoint that reads and returns data, needs no OCP ceremony and no interface hierarchy for one implementation.
- Stable, well-understood logic that genuinely will not change.
- An exhaustive switch over a closed set (sealed types, discriminated unions), when the codebase already uses it: the compiler flags every missed case, so it can be the simpler choice.
- A known violation during rapid prototyping, if a cleanup pass is scheduled.

For over-engineering detection and when to extract, see `kiss-principles`.
