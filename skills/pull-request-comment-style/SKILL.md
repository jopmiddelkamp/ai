---
name: github-pr-comment
description: Write GitHub PR comments and review-thread replies in the user's house style: compact, direct English for a non-native team, merge-intent labels (blocking/suggestion/none), optional Mermaid diagrams. Use when writing any PR comment or reply.
---

# GitHub PR Comment Writer

Write a GitHub PR comment or a reply to an existing PR review thread, in the user's communication style.

The user typically uses Claude for advice or analysis first, then at the end asks for a PR comment that captures the conclusion. The preceding conversation is the source material — use it.

## Step 1: Read the style guide

ALWAYS read `references/style-guide.md` before writing. It is the authoritative definition of tone, structure, label usage, and Mermaid rules. Do not write from memory of it — load it fresh each time.

## Step 2: Decide what is being written

Two cases:

- **New comment** — the user wants to raise a point on a PR (a review comment on a line, or a general PR comment). No existing thread to answer.
- **Reply** — the user is responding inside an existing PR review conversation. There is a prior comment (often pasted in, or discussed earlier). A reply should briefly connect to what was already said before adding the new point.

If it is genuinely unclear which one, ask one short question. Otherwise infer it and continue.

## Step 3: Pull the content from the conversation

Use the full discussion as context. The user has already worked through the reasoning with Claude — the comment must reflect that conclusion, not restate the whole debate. Extract:

- the single issue or point the comment is about
- why it matters (the reasoning from the discussion)
- the concrete fix or question that came out of it

**One issue** — write a single, plain comment.

**Multiple issues** — write one comment with a clear section per issue. Do not ask the user to split it, and do not blend unrelated points into one paragraph. Apply all the rules of this skill to *each* section independently: each section gets its own problem → why → fix structure, and its own merge-intent decision (one section can be `blocking:`, another `suggestion:`, another unlabelled). Give each section a short bold header so the reader can act on them one by one. Keep the sections compact — the per-issue rule still holds, the sections just live in one comment.

## Step 4: Decide merge intent (label)

Per the style guide:

- `blocking:` — only if the PR should not merge before this is fixed.
- `suggestion:` — useful improvement, not required before merge.
- **no label** — normal discussion, agreement, context, praise, or a plain question.

Do not add a label just to add structure. When in doubt between `blocking:` and no label, consider how the discussion framed it — was this a real defect, or a preference? If the user already signalled severity in the conversation, follow that.

## Step 5: Write the comment

Follow `references/style-guide.md` exactly. Key points:

- Simple, direct English. Short sentences. No idioms, sarcasm, rhetorical questions, or emotional wording.
- Structure: problem → why it matters → suggested fix. Skip "why it matters" only when it is obvious.
- Focus on the code, not the person.
- For a reply: open with one short line connecting to the existing thread, then the new point.
- Add a Mermaid diagram only if it genuinely makes a flow clearer (state transitions, async flows, error/retry paths, architecture boundaries) — never when one sentence is enough. Precede any diagram with one sentence explaining what it shows.

## Step 6: Output

Output the comment as plain text inside a single Markdown code block, so the user can copy it directly into GitHub. Use a ```text fence (or ```markdown if the comment itself contains a Mermaid block, so the fences do not collide).

Do not add commentary before or after the block unless the user asked a question that needs answering, or you need to flag a decision you made (e.g. "I treated this as `blocking:` because the discussion framed it as a domain-layer leak — change to `suggestion:` if you disagree"). Keep any such note to one or two lines.

## Quick reference: comment shape

Single issue:

```text
[optional: one line connecting to existing thread, for replies]

[optional label: ] <problem>

<why it matters>

<suggested fix or direct question>
```

Multiple issues — one comment, one section each:

```text
[optional: one line connecting to existing thread, for replies]

**1. <short issue title>**

[optional label: ] <problem>

<why it matters>

<suggested fix or direct question>

**2. <short issue title>**

[optional label: ] <problem>

<why it matters>

<suggested fix or direct question>
```
