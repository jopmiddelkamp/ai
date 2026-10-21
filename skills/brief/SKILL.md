---
name: brief
description: "Interview the user for a task brief (the task, the guardrails, the definition of done) with suggested guardrails and done criteria, then deepen the brief the way a top professional in the field would, then execute it. Use when the user says '/brief', 'brief me', 'interview me for this task', 'task, guardrails, done', or wants to agree on a task before it starts. For only deepening a prompt, use the deepen skill. Not for quick questions or one-line fixes the user wants done right away."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-16"
---

# Brief

A task goes well when three things are clear before work starts: what the task is, what must not happen, and what proves it is done. This skill gets those three from the user in a short interview, then makes the brief deeper (not bigger), then runs it.

Work in three phases. Do not start a phase before the user has agreed to the result of the one before it.

## 1. Interview

Ask one question per turn, in this order. Ask every question in plain text. Do not use `AskUserQuestion`: its fixed options get in the way of a dialog.

After every answer the user gives, in every step, restate it as "As I understood, you want <X>. Right?" and wait for a yes before you go on. If the user corrects you, restate the corrected version the same way. Repeat until the user says yes. Never act on an answer the user has not confirmed. In the guardrails and done steps, the full updated list followed by "Do you agree?" is that restatement; do not ask twice.

### Task

The task must come from the user, in their own words. If the request already holds a task, use that text. Otherwise ask: "What is the task you want me to execute?" Do not offer options, and do not guess a task from the working tree, recent commits, or open files.

Check the task against this bar for a professional task description:

- **Action**: one clear verb for what must happen.
- **Input**: the files, data, or sources the work starts from.
- **Output**: the deliverable, with its form and its place.
- **Purpose**: who uses the output, or why the task exists.
- **Scope**: where the task stops, when the boundary is not obvious.

If one item is missing or vague, ask for that one item in plain text, with a short reason why it matters. Merge the answer into the task and restate the full task. Loop until all items are clear. Then ask for the confirmation above.

Read the files or sources the task names, so the next suggestions fit the real material.

### Guardrails

Propose 3 to 4 guardrails drawn from this task as a numbered list, and ask: "Do you agree with these guardrails? You can add, remove, or change any of them." When the user asks for a change, apply it, show the full updated list, and ask again. Loop until the user agrees.

A good suggestion names a concrete action or object the task could plausibly touch: "don't change the report template", "don't email anyone", "don't push to main", "no new dependencies", "spend at most 30 minutes of searching". Look for these sources of harm in the task:

- outward actions: sending, posting, publishing, paying, deploying
- irreversible actions: deleting, overwriting, migrating, force-pushing
- files, systems, or data the task sits next to but must not change
- scope creep: features, refactors, or extra deliverables nobody asked for
- budget: time, money, tokens, API calls, number of sources

Do not suggest generic care ("be careful", "follow best practices"). Each guardrail must be something an observer could check was broken.

### Definition of done

Propose 3 to 4 done criteria drawn from the task and the guardrails just agreed as a numbered list, and ask: "Do you agree with this definition of done? You can add, remove, or change any of them." Handle changes the same way as for the guardrails: apply, show the full updated list, ask again, until the user agrees.

A good criterion is checked by something other than you or the user: a test suite, a build, a source file, a sum that must reconcile, a validator, a diff that must be empty. "Every figure matches the export" beats "the report looks right". Turn each guardrail into a check where you can ("`git diff templates/` is empty"). Include at least one criterion about the output itself, not only about its absence of harm.

### Confirm the brief

Show the brief in this shape and ask for approval or edits:

```
Task:       <one sentence>
Guardrails: <bullets>
Done:       <bullets, each with how it is checked>
```

## 2. Deepen

Run the `deepen` skill (`ai:deepen`) on the approved brief. If the Skill tool cannot load it, read `skills/deepen/SKILL.md` in this plugin and follow it. The agreed guardrails still hold.

Show the rewritten brief in the same three-part shape, with the changes marked, and ask for approval once. If the user rejects a change, drop it and keep the rest.

## 3. Execute

Run the approved brief.

- Treat every guardrail as a hard stop. If the work seems to need breaking one, stop and ask; do not find a way around it.
- When a guardrail or done criterion turns out to be wrong or impossible partway through, say so and propose the change; do not quietly adjust it.
- Run each done check yourself where you can, and show its output.

End with a report against the brief: each done criterion with its result and evidence (pass, fail, or not checkable here and why), each guardrail confirmed as kept, and anything left for the user.
