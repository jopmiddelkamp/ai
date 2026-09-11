---
name: pull-request-comment-style
description: Use when writing or replying to a pull request comment, review comment, or review summary on GitHub, GitLab, Bitbucket, or Azure DevOps, or when a review flow needs findings posted to a PR. Triggers on "PR comment", "review comment", "reply in the thread", "post this on the PR", "draft a review summary", "write a nit".
---

# Pull request comment style

## Overview

A PR comment gives the author one decision in one glance: what is wrong, why it matters, what to change. The reader is a developer whose first language is not English. The source material is the conversation so far. The comment carries the conclusion, never the debate.

## Shape

A comment has these parts, in this order, and nothing else.

| Part | Content | Size |
|---|---|---|
| 0, reply only | One sentence that answers the last message in the thread | 1 sentence |
| 1 | The problem, stated as a fact about the code | 1 sentence |
| 2 | Why it matters for the reader, the user, or the code. Cite at most one source: a rule file, a doc line, or one earlier thread | 1 or 2 sentences |
| 3 | The fix, or the one question you need answered | 1 or 2 sentences, or 1 code block of at most 10 lines |
| 4 | The merge decision line, when the section below requires one | 1 sentence |

Limits: at most 20 words per sentence. At most 100 words of prose per issue, part 4 excluded. At most one code block per issue. No list longer than 5 items. A blank line separates the parts.

Several issues: one comment, one numbered bold title per issue, parts 1 to 4 under each title, each with its own merge decision. That title is the only bold in a comment. No headings.

## Merge decision

A comment blocks the merge by default. The reader never has to guess whether an unmarked comment is serious.

Three cases:

- **It blocks the merge.** Inside a batched review, write no part 4. The review body carries the convention line. In a standalone reply, part 4 is: `This blocks the merge.`
- **It does not block the merge.** Part 4 is: `This is just a suggestion. If you disagree, resolve this comment yourself.`
- **It is a question, an answer, context, or agreement.** No part 4. A question ends with a question mark and asks for one thing.

Write part 4 word for word, every time. The same words carry the same decision, so the reader learns them once.

**The convention line.** A batched review body opens with this line, before anything else:

```text
Comments here block the merge unless the comment says it is a suggestion.
```

That line is what makes silence readable. A standalone reply has no review body, so it states its own decision in part 4.

When the conversation already settled the severity, use that severity.

## Language

- Active voice, present tense: "the method throws", not "an exception is thrown".
- One idea per sentence. Small words. Expand an abbreviation the first time you use it.
- The same word for the same thing every time.
- Name the code, not the person: "the guard", not "your guard".
- Straight quotes. No emoji. No em dash or en dash: use a period, a comma, or a colon.
- A question mark only on a question you want answered.

Words and shapes that stay out of a comment:

- thanks, great, nice catch, you are right, feel free, let me know, hope this helps
- note that, worth noting, keep in mind, in order to, actually, additionally
- crucial, robust, leverage, streamline, seamless, ensure, comprehensive, align, enhance
- "not just X but Y", "not only X but also Y", a group of three for effect, a trailing "-ing" clause that explains the sentence before it
- a closing line that sums up or cheers, such as "This makes the code more robust."

This list comes from the humanizer skill. When a pattern slips into a draft, apply that skill to the draft.

## Mermaid

Add a diagram only for a flow: state changes, async paths, retry paths, or boundaries between layers. One caption sentence goes before it. When one sentence explains the flow, write the sentence.

## Output

- Comment text for the user to paste: one ```text block, or one ```markdown block when the comment holds a Mermaid block. Outside the block, at most one line, and only to flag a choice you made, such as the merge decision.
- Comment text you post yourself with gh or the API: the raw text, no fence.

## Example

A finding: the guard throws `ClientProtocolException`, only the Soroban methods document it, five other methods throw it too, the CHANGELOG lists them.

```text
`HandleResponse` now throws `ClientProtocolException`, but only the `StellarRpcServer` methods document it.

`Server.RootAsync`, `RequestBuilder<T>.Execute`, `Link.Follow`, `FederationServer.ResolveAddress`, and `TransferServerService` throw it too. The CHANGELOG lists them, so the release notes and the XML docs disagree.

Add the `<exception cref="ClientProtocolException">` block to those methods.

This is just a suggestion. If you disagree, resolve this comment yourself.
```

A reply, after the author says the README update comes in a later PR:

```text
The README change belongs in this PR.

`http-networking.mdc` line 28 requires both files in the same change, and no follow-up PR exists yet.

Add the README paragraph here, about 4 lines. If you open the follow-up PR before this one merges and link it, I drop the requirement.

This blocks the merge.
```

## Final check

Confirm each line before you output:

1. Part 4 matches the merge decision, and it is word for word.
2. Parts 1 to 3 are in order. The fix is the last part before part 4.
3. No sentence has more than 20 words.
4. The prose per issue is 100 words or fewer.
5. No em dash, en dash, emoji, or word from the list above.
