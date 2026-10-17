---
name: deepen
description: "Rewrite a task or prompt into a deeper version, not a bigger one: what a top professional in the field would do that the user did not ask for, the rawest source material, the specific methods and tools, and an outside check that shows the result is right. Use when the user says '/deepen', 'make this deeper', 'deeper not bigger', 'how would a pro do this', or asks to improve a prompt before running it. Also used by the brief skill. Not for making a task larger or adding deliverables."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-17"
---

# Deepen

The user wants a deeper version of their task, not a bigger one. Deeper means better inputs, better methods, and an outside check. It does not mean more deliverables or wider scope. Constraints the user already set still hold.

## Input

The task to deepen is, in this order of preference:

1. the text passed with the skill call
2. a brief handed over by the brief skill (Task, Guardrails, Done)
3. the user's last request in the conversation

If none of these gives a task, ask for it in one question. Read the files or sources the task names before you answer, so the answers fit the real material.

## Steps

First name the field the task belongs to (financial reporting, market research, backend engineering, copywriting). Then answer these four, specific to this task, in a few lines each:

1. **What a top professional would do that the user is not asking for.** The step a senior practitioner in that field would take that is missing from the task.
2. **The rawest material they would start from.** The primary source instead of the digested one: the raw export instead of the dashboard, the transaction log instead of the summary, the interview recordings instead of the notes, the code instead of the docs. Say whether you can reach it in this session.
3. **The specific methods and tools they would use.** Name them (a reconciliation, a pivot from the raw rows, a property-based test, a cohort analysis, a style guide), not "a rigorous approach".
4. **What, other than you or the user, would show the result is right.** A test, a source document, a third-party tool, a number that must reconcile, an expert, a market reaction.

Then rewrite the task to ask for exactly that: the same task with the raw input, the methods, and the outside check folded in. Keep the input's shape: a plain prompt stays a prompt; a brief stays a brief, with answer 4 added as a criterion under Done. Mark what changed from the original.

## After the rewrite

- Called from the brief skill: hand the rewritten brief back. The brief skill asks for approval and runs it.
- Called on its own: show the rewritten prompt in a code block, so the user can copy it, and offer to run it. Do not run it before the user says so.
