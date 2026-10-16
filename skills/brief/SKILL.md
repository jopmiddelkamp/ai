---
name: brief
description: "Interview the user for a task brief (the task, the guardrails, the definition of done) with suggested guardrails and done criteria, then deepen the brief the way a top professional in the field would, then execute it. Use when the user says '/brief', 'brief me', 'interview me for this task', 'task, guardrails, done', or asks for a deeper version of a task before starting it. Not for quick questions or one-line fixes the user wants done right away."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-16"
---

# Brief

A task goes well when three things are clear before work starts: what the task is, what must not happen, and what proves it is done. This skill gets those three from the user in a short interview, then makes the brief deeper (not bigger), then runs it.

Work in three phases. Do not start a phase before the user has agreed to the result of the one before it.

## 1. Interview

Ask one question per turn, in this order. Use `AskUserQuestion` when it is available; otherwise ask in plain text with numbered suggestions. If the user already gave an answer in their request, show it back as a one-line restatement and move on.

### Task

Ask: "What is the task you want me to execute?"

Restate it in one sentence: the action, the input it works from, and the output it produces ("This week's client report from the CRM export"). If the input or the output is unclear, ask for that one thing before going on. Read the files or sources the task names, so the next suggestions fit the real material.

### Guardrails

Ask: "What are the guardrails for this execution?" Offer 3 to 4 suggested guardrails drawn from this task, and let the user pick several, edit them, or add their own.

A good suggestion names a concrete action or object the task could plausibly touch: "don't change the report template", "don't email anyone", "don't push to main", "no new dependencies", "spend at most 30 minutes of searching". Look for these sources of harm in the task:

- outward actions: sending, posting, publishing, paying, deploying
- irreversible actions: deleting, overwriting, migrating, force-pushing
- files, systems, or data the task sits next to but must not change
- scope creep: features, refactors, or extra deliverables nobody asked for
- budget: time, money, tokens, API calls, number of sources

Do not suggest generic care ("be careful", "follow best practices"). Each guardrail must be something an observer could check was broken.

### Definition of done

Ask: "What is the definition of done?" Offer 3 to 4 suggested criteria drawn from the task and the guardrails just agreed, and let the user pick, edit, or add.

A good criterion is checked by something other than you or the user: a test suite, a build, a source file, a sum that must reconcile, a validator, a diff that must be empty. "Every figure matches the export" beats "the report looks right". Turn each guardrail into a check where you can ("`git diff templates/` is empty"). Include at least one criterion about the output itself, not only about its absence of harm.

### Confirm the brief

Show the brief in this shape and ask for approval or edits:

```
Task:       <one sentence>
Guardrails: <bullets>
Done:       <bullets, each with how it is checked>
```

## 2. Deepen

The user wants a deeper version of this task, not a bigger one. Deeper means better inputs, better methods, and an outside check. It does not mean more deliverables or wider scope; the agreed guardrails still hold.

First name the field the task belongs to (financial reporting, market research, backend engineering, copywriting). Then answer these four, specific to this task, in a few lines each:

1. **What a top professional would do that the user is not asking for.** The step a senior practitioner in that field would take that is missing from the brief.
2. **The rawest material they would start from.** The primary source instead of the digested one: the raw export instead of the dashboard, the transaction log instead of the summary, the interview recordings instead of the notes, the code instead of the docs. Say whether you can reach it in this session.
3. **The specific methods and tools they would use.** Name them (a reconciliation, a pivot from the raw rows, a property-based test, a cohort analysis, a style guide), not "a rigorous approach".
4. **What, other than you or the user, would show the result is right.** A test, a source document, a third-party tool, a number that must reconcile, an expert, a market reaction.

Then rewrite the brief to ask for exactly that: the same task with the raw input, the methods, and the outside check folded in. Answer 4 becomes a criterion under Done. Show the rewritten brief in the same three-part shape, mark what changed from the version in phase 1, and ask for approval once. If the user rejects a change, drop it and keep the rest.

## 3. Execute

Run the approved brief.

- Treat every guardrail as a hard stop. If the work seems to need breaking one, stop and ask; do not find a way around it.
- When a guardrail or done criterion turns out to be wrong or impossible partway through, say so and propose the change; do not quietly adjust it.
- Run each done check yourself where you can, and show its output.

End with a report against the brief: each done criterion with its result and evidence (pass, fail, or not checkable here and why), each guardrail confirmed as kept, and anything left for the user.
