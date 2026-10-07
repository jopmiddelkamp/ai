---
name: solid-principles
description: "Use when designing, refactoring, or reviewing classes, interfaces, or modules; when a class has many dependencies or a vague name like Manager, Helper, or Utils; when a switch or if-else chain dispatches on type or status; when an implementation throws not-implemented errors; when an interface has many methods; or when code news up services or calls infrastructure directly."
---

# SOLID Principles

Reference for the SOLID principles: what each one means, the signals that show a violation, and when a pragmatic deviation is fine.

**The codebase comes first.** The existing project's conventions, architecture, and style win over this skill. Apply the principles inside the patterns the project already uses; do not introduce a new architecture, DI style, or layering to satisfy SOLID. Use marker comments such as `// SOLID-DEVIATION:` only when the codebase already uses them.

**Code examples:** `examples/violations.md`, `examples/srp-examples.dart`, `examples/ocp-examples.dart`, `examples/lsp-examples.dart`, `examples/isp-examples.dart`, `examples/dip-examples.dart`. The examples use Dart; the language is only illustrative.

**Related skills:** `kiss-principles` (counterbalance to SOLID ceremony), `dry-principles` (DRY-SRP tension).

## S — Single Responsibility Principle

**"A class should have only one reason to change."** — Robert C. Martin

SRP is NOT "a class should do one thing." It means a class should serve one actor or stakeholder. When two different stakeholders could request changes to the same class, that class has two responsibilities.

### Where SRP Applies Per Layer

If the codebase uses a layered architecture (for example Clean Architecture or hexagonal), SRP looks like this per layer. Map it to the layers the project actually has.

| Layer | SRP Means |
|-------|-----------|
| **Domain** | One aggregate/entity = one business concept. A `Payment` doesn't manage `Wallet` state. |
| **Application** | One service = one domain aggregate's operations. `PaymentAppService` doesn't handle notifications. |
| **Interface Adapters** | One adapter = one external system. A payment provider adapter doesn't send email. |
| **Frameworks** | One configuration class = one concern. DB config separate from auth config. |

Without explicit layers, the same rule holds per module or file: one module, one reason to change.

### Violation Signals

- **Class name contains "Manager", "Helper", "Utils", "Processor"** — vague names hide multiple responsibilities
- **Too many constructor dependencies** — see the `kiss-principles` skill for thresholds
- **>7 public methods serving different workflows** — the class is an orchestration hub
- **Changes to unrelated features require modifying the same class**
- **Test file for the class tests unrelated behaviors**

### Static Helpers That Hide Orchestration

Static helpers that disguise workflow orchestration as domain logic are an SRP violation: the class mixes domain state transitions with workflow orchestration, two different reasons to change.

## O — Open/Closed Principle

**"Software entities should be open for extension, closed for modification."** — Bertrand Meyer

When new requirements arrive, you should be able to add new behavior by writing NEW code (a new class, a new implementation) rather than modifying EXISTING code.

### Primary Mechanism: Polymorphism

```
PaymentProvider  ← interface (closed for modification)
├── ProviderA       (extension)
├── ProviderB       (extension)
└── NewProvider     (add this — no existing code changes)
```

### Violation Signals

- **Growing switch/if-else chains** that check type or status to determine behavior
- **Modifying existing classes every time a new variant is added**
- **"Shotgun surgery"** — adding one feature requires touching many files in the same way
- **Enum-based dispatch** where each enum value triggers different logic inline

### When NOT to Apply

- **Simple CRUD with no realistic extension points** — don't create an interface hierarchy for a single implementation
- **Stable, well-understood logic** that genuinely won't change
- **Languages with exhaustive matching** (sealed types, discriminated unions) — if the codebase already uses an exhaustive switch over a closed set, the compiler flags every missed case; that can be the simpler and accepted choice
- **Extraction timing** — see the `kiss-principles` skill for when to extract and how to spot premature abstraction

## L — Liskov Substitution Principle

**"Subtypes must be substitutable for their base types."** — Barbara Liskov

If code works with a `PaymentRepository` abstraction, it must work identically with ANY implementation. No implementation may surprise its caller.

### Violation Signals

- **Not-implemented or unsupported-operation errors** (`NotImplementedException`, `UnsupportedOperationException`, `UnimplementedError`) — the implementation doesn't fulfill the contract
- **Type-checking the implementation** (`if (repo is SqlRepository)`) — code shouldn't care which implementation it has
- **Different error semantics per implementation** — one throws, another returns null, a third returns a default
- **Preconditions stricter than the interface promises**
- **Postconditions weaker than the interface promises**

### The Test: Behavioral Substitutability

Write interface contracts as tests. Every implementation must pass the same contract tests. If an implementation needs special handling, either:
1. The interface contract is too broad (split it — ISP)
2. The implementation doesn't belong behind this interface

## I — Interface Segregation Principle

**"No client should be forced to depend on methods it does not use."** — Robert C. Martin

### Violation Signals

- **Interface with >7 methods** serving different client groups
- **Implementations that throw not-implemented errors** for some methods
- **"I only use 2 of the 10 methods"** — the client is coupled to 8 irrelevant methods
- **Interface changes break unrelated implementations**
- **Read/write split ignored** — query-only clients forced to depend on mutation methods

### Practical Application

```
// BAD: One fat interface
UserService { getUser, updateUser, deleteUser, getUserPreferences, sendNotification, resetPassword }

// GOOD: Segregated interfaces
UserReader   { getUser, getUserPreferences }
UserWriter   { updateUser, deleteUser }
UserAuth     { resetPassword }
UserNotifier { sendNotification }
```

Split by client need, not by arbitrary grouping. Follow the codebase's naming convention for interfaces (`IUserReader`, `UserReader`, `UserReaderProtocol`, and so on).

## D — Dependency Inversion Principle

**"Depend on abstractions, not concretions."** — Robert C. Martin

### Class-Level DIP

- Constructor parameters should be abstractions, not concrete classes
- A `PaymentService` depends on a `PaymentRepository` abstraction, not on `SqlPaymentRepository`
- The concrete implementation is supplied from outside: by the DI container if the codebase uses one, otherwise by whatever wiring it already uses (constructor injection at a composition root, a provider system, factory functions, module-level injection)

If the codebase has architectural layers, inner layers never depend on outer layers.

### Violation Signals

- **`new ConcreteClass()` for services** inside business logic
- **Constructor parameters typed as concrete service classes** instead of abstractions
- **Static method calls to infrastructure** (`Database.query()`, `HttpClient.get()`)
- **Service locator pattern** — `ServiceLocator.get<T>()` hides dependencies, unless the codebase has deliberately standardized on it

### When a Concrete Dependency Is Acceptable

- **Value objects and DTOs** — `new Money(100, "EUR")` is fine; these are data, not services
- **Domain entities** — `new Payment(...)` is fine; the domain creates its own objects
- **Pure utility types** — reading the current time directly is fine (though consider a clock abstraction for testability)

## SOLID Code Review Checklist

| # | Principle | Check | Severity |
|---|-----------|-------|----------|
| 1 | SRP | Too many constructor dependencies (see `kiss-principles` for thresholds) | Medium |
| 2 | SRP | Class name contains "Manager", "Helper", "Utils" | Medium |
| 3 | OCP | Growing switch/if-else chain that checks type or variant | Medium |
| 4 | OCP | Adding a variant requires modifying existing classes | High |
| 5 | LSP | Interface implementation that throws not-implemented | High |
| 6 | LSP | Type-checking implementations (`is`, `as`, `instanceof`, `typeof`) | High |
| 7 | ISP | Interface with >7 methods serving different clients | Medium |
| 8 | ISP | Implementation provides dummy methods it doesn't need | Medium |
| 9 | DIP | `new ConcreteService()` in business logic | High |
| 10 | DIP | Static calls to infrastructure from business logic or inner layers | Critical |

Weigh each finding against the codebase's own conventions. A pattern the whole codebase uses on purpose is not a finding on its own; raise it as a proposal instead.

## When Pragmatic Deviation Is Acceptable

- **Simple value objects** don't need interfaces — `Money`, `Address`, `DateRange` are data, not services
- **Single-implementation interfaces** are justified when they exist to keep a layer boundary clean (if the codebase has layers), even if no second implementation is planned
- **Simple CRUD** — a basic GET endpoint that reads and returns data doesn't need full OCP ceremony
- **Prototyping phase** — knowingly violating SOLID during rapid prototyping is fine IF you schedule a cleanup pass
- For over-engineering detection and complexity calibration, see the `kiss-principles` skill

Document a deviation the way the codebase documents such decisions. If it already uses a marker such as `// SOLID-DEVIATION: {reason}`, use that; otherwise a plain comment with the reason is enough.

## Principles Work Together

SOLID violations cluster. When you find one, look for its siblings:

| Symptom | Primary Violation | Usually Also |
|---------|-------------------|-------------|
| God Service (does everything) | SRP | ISP — fat interface serving all clients |
| Switch/if-else selector | OCP | DIP — depending on concretions to dispatch |
| Not-implemented error in an implementation | LSP | ISP — interface too broad for this implementation |
| Utility class with 15 methods | SRP | ISP — clients use different subsets |
| Service locator pattern | DIP | SRP — hidden dependencies obscure responsibilities |
| Modifying existing code for every new feature | OCP | SRP — class has multiple reasons to change |

When reviewing code, don't just fix the surface symptom. Trace it to the root principle violation, then check for clustered violations.
