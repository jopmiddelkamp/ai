---
name: decision-matrix
description: "Structured comparison matrix for a contested code-level or architectural decision: implementation approaches, module or package structure, state management, API design, data flow, caching, or dependencies. Use when choosing between two or more engineering approaches, or before you recommend one coding approach over alternatives, standalone or inside a planning workflow. Not for non-code comparisons, wording, process questions, a follow-up question about a question you asked, or a choice with an obvious conventional answer: answer those in plain prose."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-08"
---

# Decision matrix

A reviewable comparison of engineering options, grounded in the project's own rules and verified against its code. The matrix is only as good as the facts under it, so most of the work happens before the first cell: find the project's rules, screen out options that break them, and walk every option through the real code.

## When it fits

Use it for a real choice between 2 or more code-level approaches where the answer is not obvious and is costly to reverse. Answer in plain prose instead when the comparison is not about code, when the choice has an obvious conventional answer, or when most criteria would come out equal. A plain-prose answer is 1 to 3 sentences: the pick and the evidence for it, with no caveats, extra options, or advice the user did not ask for. Name the evidence exactly (the actual file names or lines) rather than summing it up with a label that may not fit every item. Skip the steps below for such an answer: no rule search, gate, or walkthrough, and no notes about project rules the question did not raise. In a plan with many decisions, give the matrix only to the ones that are structural, hard to reverse, and contested; a stated trade-off is enough for the rest.

## Steps

### 1. Frame the decision

State in one sentence what is being chosen and why it matters now.

### 2. Generate the options

Label them A, B, C. Give each a one-line summary and 2 to 3 sentences on how it works, enough for someone new to see the trade-off. Aim for 3 to 6 genuinely different options: fewer than 3 usually means an angle is missing, more than 6 means some can go now. Merge options that are nearly the same. Include no strawman: every option should be one a competent engineer could defend.

### 3. Find the project's rules and precedents

Before you judge anything, find where this project records its decisions. Locations differ per project, so search instead of assuming: `CLAUDE.md`, `AGENTS.md`, rule files such as `.claude/rules/` or `.cursor/rules/`, `ARCHITECTURE.md` or `docs/architecture*`, architecture decision records (ADRs, often under `docs/adr/` or `docs/decisions/`), design specs, and plan documents. Then search the code for existing solutions to the same problem.

Collect two things with exact references:
- **Rules:** layer order, dependency direction, forbidden dependencies, module or feature ownership. Separate hard boundaries from preferences: a rule worded as an instruction ("must", "never", "only", "goes through") is a hard boundary unless the project calls it a guideline. Keep each rule's exact scope: a rule against importing storage libraries does not forbid every library.
- **Precedents:** where the codebase already solves this kind of problem (`path/to/file:line`), and the decision record that chose it, if any.

If the project records no rules, say so in one line and judge architecture fit on the dependency structure the code shows.

### 4. Gate the options on hard boundaries

A hard boundary is a constraint, not a trade-off, so an option that breaks one does not compete on points. Screen every option, including the user's own idea in the exact form they stated it. If an option passes only in one form (for example only through the owner's public interface), say which form passes and which rule the other form breaks.

- **Passes** (compliant, or allowed but discouraged): it enters the matrix.
- **Breaks a hard boundary:** it stays out. Write one line naming the option and the rule it breaks, then keep the pool the same size. First try a compliant variant that keeps the option's core idea (move the code to the owning module, invert the dependency, go through the owner's public interface, extract shared logic to a shared module). If no compliant variant exists, add a fresh approach from a different angle. Give the replacement its own label in the option list, and name that label in the gate line. Screen the replacement against the same rules: it must pass the gate too.

Exception: when the decision is about changing the boundary itself, the breaking option may enter the matrix, marked as requiring a rule change.

An option that conflicts with a recorded decision (an ADR or design spec) appears in the gate line either way: gated, or passed with the reason the decision does not apply. A later cell must not reveal a conflict the gate line skipped.

### 5. Walk every option through the real code

Patterns mislead; code does not. Before you fill a cell:

1. **Fix the scenario set.** List the concrete situations the decision must cover: data states, environments or platforms, user types, and failure paths, including each outside dependency being down, slow, or returning an error. Check which of them the current code already handles. The real gap is often smaller or larger than it first looks, and that changes the recommendation.
2. **Trace each option from trigger to deliverable.** Follow one scenario through the path the option would take: input, files and functions touched, output. Compare that output with the real deliverable (its actual format, side effects, and failure behavior), not the one you assume. Follow failures through every layer the option uses, shared ones included (event buses, retries, transactions, caches): a layer that swallows an error changes the outcome. Walk the recommended option through at least one failure path end to end.
3. **Verify every fact a cell will rest on with a tool call.** Which module a symbol lives in, who calls it, what it returns, how it handles errors, what the configuration says. Cite `file:line` only for lines you read in this session, and take the number from the line itself: rule 2 in a numbered list is rarely on line 2. When unsure of the line, cite the file and the rule or symbol name instead. Watch for similarly named symbols: confirm which one you mean. Anything you did not verify (the number of hosts, traffic, future plans) is an assumption: label it as one.
4. **Feed findings back.** A finding that changes an option (a simpler shape, a new disqualifier) goes back to step 2 or 4 before you continue. If an option is only safe with an addition (a unique constraint, a reconciliation job, a retry), that addition becomes part of the option: describe it there and count its cost in that option's cells (migration effort, KISS, risk).

### 6. Build the matrix

Columns are the options that passed the gate; a gated option gets no column. Indicators: ✅ clear advantage, ⚠️ trade-off or minor concern, ❌ significant drawback. Every cell gets the indicator plus a short reason; the reason is what makes the matrix useful. A cell states only what that option's walkthrough or the code shows, and every risk or limit the walkthrough found for an option shows up in that option's row for it, usually Risk.

| Criterion | What to judge |
|---|---|
| KISS | How simple is it to understand and build? Would a new developer get it quickly? |
| DRY | Does it avoid duplicating knowledge (not lines of code)? |
| Precedent | ✅ matches an existing pattern, cite it. ⚠️ new pattern, but nothing existing covers this and the benefit justifies a second way. ❌ duplicates an existing pattern, or diverges without enough benefit. |
| Architecture fit | ✅ within the rules. ⚠️ allowed but discouraged, cite the rule. ❌ only when the decision is about changing a boundary; hard breaks were gated in step 4. |
| SRP | Does each part have one reason to change? |
| OCP | Can it be extended without editing existing code? |
| LSP | Can implementations be swapped without breaking callers? |
| ISP | Do consumers see only what they need? |
| DIP | Do high-level parts depend on abstractions? Judge by this project's rules, not by textbook layering. |
| Performance | Runtime cost, memory, latency, cache behavior |
| Migration effort | How much existing code and how many consumers change? |
| Testability | Can it be tested in isolation? |
| Reversibility | How hard is it to undo if it proves wrong? |
| Risk | What can go wrong, how likely, how bad? |

Drop a row where every option gets the same indicator for the same reason, and list the dropped criteria in one line under the matrix, so the reader sees they were judged. Call a criterion equal only after checking it against each column's walkthrough; when one option differs, keep the row. A cell that contradicts its option's walkthrough is wrong: fix the cell. The recommended option shows its real costs: a column that is green on every row except one or two usually means costs were missed, so look again at performance, migration effort, and risk.

When the `kiss-principles`, `dry-principles`, or `solid-principles` skills are available, they hold the calibration for those rows.

### 7. Recommend

- **Recommendation:** the option and its main reason, in one sentence. It opens the answer, so the reader sees the outcome first.
- **Why [pick] over [runner-up]:** the criteria where they differ most, tied to the project's rules and precedents, plus the concrete settings the pick needs (values, limits, names). Anywhere in the answer, a claim such as "the only option that" must hold against every column of the matrix; check it before you write it.
- **When I'd pick [runner-up]:** the concrete conditions that flip the choice ("if X", "when Y"). The runner-up is the same option in both sections.

## Output

Present the parts in this order. Each part appears once, and the answer ends after "When I'd pick", with no closing offer or summary.

```markdown
**Recommendation:** [option and main reason, one sentence]

**Decision:** [one sentence]

**Today:** [what the current code does for the scenario set, with `file:line`: what it already handles and what is missing]

**Project rules and precedents:** [rules and precedents found, with file references; or "none recorded"]

**Gate:** [one line per gated option: "[option] breaks [rule, file] → replaced by [label: name]"; or "all options pass"]

### Options
- **A: [name]**: [summary and how it works] (gated options are not listed here; the gate line covers them)

### Walkthrough
- **A: [name]**: scenario [x]. Path: `file:line` → `file:line`. Output: [what it produces]. Breaks on: [what fails, or "nothing found"].

### Matrix
| Criterion | A: [name] | B: [name] | C: [name] |
|---|---|---|---|
| KISS | ✅ No new concepts | ⚠️ Adds an indirection layer | ❌ Complex lifecycle |
| Precedent | ✅ Matches `src/orders/notify.ts:12` | ⚠️ New, nothing existing covers it | ❌ Second way to do what `src/shared/modal.ts` does |

Equal across all options: [criterion: the shared reason; ...], or "none".

**Why A over B:** ...
**When I'd pick B:** ...
```

Before you present it, check the specific failure points: every cell has a reason after its indicator, every `file:line` was read in this session, every gate line names a replacement that appears under Options, and the recommended option's column shows its real costs.

## Inside a planning workflow

This skill settles one decision; it does not scope the work. Run it inside a planning session, after the problem statement, non-goals, and constraints are set, because the gate in step 4 needs them. A planning skill names the candidate approaches, this skill picks one, and the recommendation goes back into the plan or design spec. With the superpowers plugin, that is the approach-comparison step of `superpowers:brainstorming` and the file-structure step of `superpowers:writing-plans`, where module placement and new dependencies get locked in.
