---
name: research
description: "Use for ANY question that depends on outside facts, including a single current number such as a rate, a price, or a version, and ALWAYS when the topic has organized opposing sides: wars, elections, contested history, atrocity claims, health and climate debates, corporate or political scandals, viral clips. Triggers on '/research', 'research X', 'is it true that', 'what really happened', 'both sides of', 'debunk this', 'fact-check this', 'what is the current X', and on any claim the user heard from someone or repeats as fact. Never answer a contested or outside-world factual question from memory or from one search."
---

# Research

Normal research finds sources that agree with the question. This skill finds the sources that
break the question. It assumes every source serves someone, and it says who.

Two outputs matter more than the prose: the **verdict per claim** and the **misinformation log**.

## Step 0: Pick the level

Effort must match the topic. Over-checking a settled fact wastes the user's time and hides the
real answer under noise.

| Level | When | Budget | Always |
|---|---|---|---|
| **1 Quick** | One fact, no organized opposing side. "What is the current EU interest rate?" | 1-3 searches | Cite. No log. |
| **2 Standard** | Multi-part research, no organized opposing side. "Compare Postgres and MySQL replication." | 4-10 searches | Cite. No log. |
| **3 Deep** | Any topic with organized opposing sides, or the user says "/research", "fact-check", "is it true". | 10-40 searches and fetches | Cite. Full loop below. Log required. |

**Citation is not a level. It applies to every answer, including a one-word answer.**

- Every external fact gets a `[n]` mark. Each `[n]` is a hyperlink to the source.
- Number all sources at the end of the answer, even when there is only one.
- One fact means one source shown, not zero. "The rate is 2.15% [1]" is the minimum shape.
- Never state an outside fact from memory. If a search finds nothing, say **Unverified** and say
  what you looked for. Do not fall back to what you think you know.
- Do not cite your own reasoning, math, or analysis of the user's own input.

At Level 1 you get one citation, so make it the best one. Prefer the body that owns the number:
the central bank for its own rate, the statistics agency for its own data, the vendor's release
notes for its own version. A news article about the number is second choice.

State the level in one line at the top of the answer. If the user asked for `/research` and the
topic turns out to be Level 1, say so and answer short. Do not pad.

Everything below applies to **Level 3**.

## Step 1: Split the question into claims

Write out the atomic claims the answer depends on. An atomic claim is one testable statement
with one subject. Split compound claims, because the parts often get different verdicts.

- Bad: "Israel expelled all Arabs in 1948 and they never got rights."
- Good: (a) All Arabs left the territory in 1948. (b) Those who stayed received citizenship.
  (c) Those citizens have the same legal rights today.

**Check the premise inside the user's own question.** If the user repeats a claim, that claim
becomes claim zero. Test it before answering around it. A correct answer to a false premise is
still a wrong answer.

## Step 2: Map the sides before searching

List the sides that have an organized interest in the answer. For each side, name what it gains
if its version wins. This tells you what to search for later.

Every source gets a label. Use these:

- **A** / **B** — the sides in the dispute. Add the country, party, or company.
- **A-adjacent** / **B-adjacent** — funded by, staffed by, or founded to advocate for a side.
- **3P** — third party with no stake in this specific claim.
- **PRIMARY** — the original document, dataset, court record, official statement, raw footage
  with known origin, or the actual law text.

There is no neutral source. Fact-checkers, United Nations bodies, courts, and non-governmental
organizations all have a side or an accused side. Label them too. Never write "neutral source".

## Step 3: Search adversarially

Searching in your own words returns your own view. Break out of it on purpose.

1. Search the claim in the words **side A** uses.
2. Search the same claim in the words **side B** uses. Their terms are different: "settlement"
   and "colony", "operation" and "invasion", "reform" and "cut".
3. Search for the refutation directly: add "debunked", "correction", "retracted", "disputed".
4. Search for the **primary source** by name: the report title, the case number, the dataset.

Read the strongest source each side has, not the weakest. A win against a weak source proves
nothing.

## Step 4: Trace each key claim to the end of its chain

This is the core of the skill. Most viral facts are one origin wearing many coats.

For each key claim, follow the citations upstream. Fetch each source and read what it cites.
Repeat until you reach one of the stop conditions.

**Stop when:**

- You reach a **primary source**. The chain is complete.
- You reach **two independent sources**. Independent means they do not share one upstream
  origin. Ten outlets that all cite one wire report are one source, not ten.
- You reach a **paywall, dead link, or a language you cannot read**. Say so, and name the last
  link you could read.
- You hit the search budget. Say where you stopped.

**Never** end a chain at a fact-checker's verdict. Follow through to the evidence the
fact-checker used. A fact-checker is a source, not an authority.

Record the chain depth for every key claim. The user must be able to see how far you got.

See `references/source-checks.md` for the independence test, the manipulation patterns to look
for, and a worked example of a chain.

## Step 5: Give a verdict per claim

Only facts get verdicts. Use exactly this scale:

| Verdict | Meaning |
|---|---|
| **Verified** | Reached a primary source or two independent sources. They agree. |
| **Partly true** | The core is right. One part is wrong or too broad. Name which part. |
| **Misleading** | Every stated fact is true. The framing hides context that changes the meaning. |
| **Disputed** | Both sides have real evidence. No primary source settles it. |
| **Unverified** | No source found either way. This is not the same as False. |
| **False** | A primary source or two independent sources contradict it. |

**Unverified is not False.** Absence of evidence is a finding, not a refutation. Keep them apart.

**Do not force balance.** If side A is wrong on a claim and side B is right, say so. Inventing an
error on the other side to make the counts even is itself a distortion.

## Step 6: Separate fact, interpretation, and value

Three different things get mixed in every contested topic. Sort them.

- **Fact**: "About 150,000 Arabs remained inside Israel in 1948." Gets a verdict.
- **Interpretation**: "The Nation-State Law makes them second-class citizens." Gets the strongest
  case from each side. No verdict.
- **Value**: "This was ethnic cleansing." A legal and moral judgment. No verdict. Give the legal
  definition, who applies it, and who rejects it, with their reasons.

On contested moral, legal, and political questions, present the best case each side makes. Do not
deliver a personal verdict. The user wants an accurate map, not your opinion.

## Output template

Use this exact structure. It matches the user's report format: conclusion first, optional detail
last.

```markdown
**Level 3 deep check. N sources read, M chains traced to a primary source.**

## Answer
[2-4 sentences. Lead with the conclusion. Include the correction to the user's premise if there was one.]

## Claims and verdicts
| Claim | Who says it | Verdict | Corrected or confirmed by |
|---|---|---|---|
| ... | Side A (name) | False | [primary source with [n] link] |

## Misinformation log
- Side A: X false, Y misleading.
- Side B: X false, Y misleading.
- [One line per error: what was claimed, what is true, which source settles it.]

## Not settled
[Claims with verdict Disputed or Unverified. One line each, with the best evidence on each side.]

## Detail
### Chains traced
- Claim (a): outlet -> wire report -> government dataset. PRIMARY reached.
- Claim (b): outlet -> think tank PDF -> not opened (paywall). STOPPED at depth 2.

### Source labels
[n] Name — type, funder or owner, side label.

## Sources
1. [Title](url)
```

## Hard rules

These are the failure modes that make research worse than no research.

- **Every external fact carries a link.** At every level. An uncited fact is an unchecked fact,
  and the user cannot audit it.
- **No source is neutral.** Label every one. "Reputable outlet" is not a label.
- **Do not launder a citation.** If you cannot open a source, you have not read it. Say so.
- **Count origins, not articles.** Twenty articles from one press release is one source.
- **A side conceding against itself is strong evidence.** Weight it. Say when it happens.
- **Government data about its own failures is strong evidence.** Weight it too.
- **A source being biased does not make its specific claim false.** Check the claim, not the logo.
- **Old primary beats new secondary.** For history, a 1948 document beats a 2026 opinion piece.
  For current data, the newest official figure wins.
- **Report short, gather wide.** The user reads the verdict table. The chain goes under Detail.
- **Say the number.** "3 of 11 claims traced to primary source" beats "extensively verified".

## What to do when you cannot finish

Running out of budget is normal and fine. Faking completion is not.

Write one line: "Stopped at N sources. Claims (c) and (e) are still Unverified. To close them, the
next step is [specific search or document]." Then offer to continue.
