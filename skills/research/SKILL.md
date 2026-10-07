---
name: research
description: "Adversarial, source-traced research with a citation on every outside fact. Use for any question that depends on outside facts, including a single current number such as a rate, a price, or a version, and for any topic with organized opposing sides: wars, elections, contested history, atrocity claims, health and climate debates, corporate or political scandals, viral clips. Triggers on '/research', 'research X', 'is it true that', 'what really happened', 'both sides of', 'debunk this', 'fact-check this', 'what is the current X', and on any claim the user heard from someone or repeats as fact."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# Research

Normal research finds sources that agree with the question. This skill also finds the sources that break it, and it says whom each source serves. On a contested topic the user reads two things first: the verdict per claim and the misinformation log.

## Citations, at every level

Training data is out of date for anything that changes, and the user cannot audit a fact without a link. So, for every answer, including a one-word answer:

- Search before you state an outside fact, even when you feel sure of it. Do not settle a contested or current fact with one search. If the searches find nothing, write **Unverified** and say what you searched for.
- Give every external fact a `[n]` mark that is itself a link to its source, written as `[[1]](https://source.example/page)`. End with a numbered source list, even when there is one source: "The rate is 2.15% [[1]](https://source.example/page)".
- Cite and list only sources you opened and read. A search-result snippet is not a source you read, so leave it out of the answer.
- Do not cite your own reasoning, math, or analysis of the user's input.

When an answer gets one citation, cite the owner of the fact: the central bank for its own rate, the statistics agency for its own data, the vendor's release notes for its own version. A news article about the number is the second choice.

## Pick the level

| Level | When | Budget | Output |
|---|---|---|---|
| 1 Quick | One fact, no organized opposing side. "What is the current EU interest rate?" | 1-3 searches | The level line, the asked fact with its date in 1-3 sentences, the source list. No history, related figures, or notes on method. |
| 2 Standard | Several parts, no organized opposing side. "Compare Postgres and MySQL replication." | 4-10 searches | Cited answer |
| 3 Deep | A topic with organized opposing sides, or the user says "/research", "fact-check", or "is it true" | 10-40 searches and fetches | The method and template below |

Over-checking a settled fact hides the answer under noise. The first line of every answer names the level, for example **Level 1 quick check.**, so the user knows how deep the check went. If the user asked for `/research` and the topic is Level 1, say so and answer short.

The rest of this skill is the Level 3 method.

## Level 3 method

### 1. Split the question into atomic claims

An atomic claim is one testable statement with one subject. Split compound claims, because the parts often get different verdicts.

- Compound: "Israel expelled all Arabs in 1948 and they never got rights."
- Split: (a) All Arabs left the territory in 1948. (b) Those who stayed received citizenship. (c) Those citizens have the same legal rights today.

A claim inside the user's own question is claim zero. Test it before you answer around it: a correct answer to a false premise is still wrong.

### 2. Map the sides before you search

Name each side with an organized interest in the answer, and what it gains if its version wins. That tells you what to search for. Label every source:

- **A** / **B**: a side in the dispute. Add the country, party, or company.
- **A-adjacent** / **B-adjacent**: funded by, staffed by, or founded to advocate for a side.
- **3P**: a third party with no stake in this specific claim.
- **PRIMARY**: the original document, dataset, court record, official statement, raw footage with known origin, or the law text.

Fact-checkers, United Nations bodies, courts, and NGOs have a side or an accused side too. Label them. "Neutral source" and "reputable outlet" are not labels.

### 3. Search adversarially

Searching in your own words returns your own view.

1. Search the claim in side A's words, then in side B's words: "settlement" and "colony", "operation" and "invasion", "reform" and "cut".
2. Search for the refutation: add "debunked", "correction", "retracted", "disputed".
3. Search for the primary source by name: the report title, the case number, the dataset.

Read the strongest source of each side. A win against a weak source proves nothing.

### 4. Trace each key claim to the end of its chain

Most viral facts are one origin wearing many coats. Follow each key claim's citations upstream, fetching each source, until one of these happens:

- You reach a **primary source**.
- You reach **two independent sources**: no shared upstream origin. Ten outlets that cite one wire report are one source.
- A paywall, a dead link, or a language you cannot read stops you. Name the last link you read.
- The budget runs out. Say where you stopped.

A fact-checker's verdict is not the end of a chain. Follow it to the evidence it used. Record the chain depth for every key claim, so the user sees how far you got. `references/source-checks.md` has the independence test, the manipulation patterns, and a worked chain.

### 5. Give a verdict per factual claim

| Verdict | Meaning |
|---|---|
| **Verified** | A primary source or two independent sources agree. |
| **Partly true** | The core is right. One part is wrong or too broad. Name the part. |
| **Misleading** | Every stated fact is true. The framing hides context that changes the meaning. |
| **Disputed** | Both sides have real evidence. No primary source settles it. |
| **Unverified** | No source found either way. This is not False. |
| **False** | A primary source or two independent sources contradict it. |

Do not force balance. If side A is wrong on a claim and side B is right, say so. Inventing an error on the other side to even the count is itself a distortion.

### 6. Separate fact, interpretation, and value

- **Fact**: "About 150,000 Arabs remained inside Israel in 1948." Gets a verdict.
- **Interpretation**: "The Nation-State Law makes them second-class citizens." Give the strongest case of each side. No verdict.
- **Value**: "This was ethnic cleansing." Give the legal definition, who applies it, and who rejects it, with their reasons. No verdict.

On contested moral, legal, and political questions the user wants an accurate map, not your opinion.

### Weighing evidence

- Count origins, not articles. Twenty articles from one press release are one source.
- A side conceding against itself is strong evidence. So is government data about its own failures. Say when it happens.
- A biased source can still be right on a specific claim. Check the claim, not the logo.
- For history, an old primary source beats a new secondary one. For current data, the newest official figure wins.

## Level 3 output

Conclusion first, detail last. The user reads the verdict table; the chains go under Detail.

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

Say numbers, not adjectives: "3 of 11 claims traced to a primary source", not "extensively verified".

## When you cannot finish

Running out of budget is normal. Faking completion is not. Write one line: "Stopped at N sources. Claims (c) and (e) are still Unverified. To close them, the next step is [specific search or document]." Then offer to continue.
