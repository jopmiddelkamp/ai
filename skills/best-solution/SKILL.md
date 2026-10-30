---
name: best-solution
description: "Use before you recommend a fix, design, or approach for a problem the user is trying to solve and more than one solution could work: a bug whose cause is known, an architecture or tooling choice, a data or content pipeline that misses its targets, a process or workflow problem, an ops question such as where to keep a secret. Fires on its own, without being asked; also on 'is this really the best fix', 'can we do better', 'keep looping', 'think outside the box'. Not for a request with one obvious way to do it, such as a rename, a typo, or a command the user spelled out."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-30"
---

# Best solution

The user should never have to ask "is this really the best fix?". Run the loop below before you recommend anything, and show only the result. The first solution that works is rarely the best one. The two usual misses: a general mechanism where a small change covers every real case, and a fact from the user's message that the answer ignores.

## The loop

Do this in your head or in scratch notes. The user sees only the output.

1. **Frame it.** Write the real goal in one sentence, and the constraints. List every fact the user gave. Each fact is there for a reason: write what it rules in or out.
2. **Generate candidates from each angle.** Skip an angle only when it cannot apply.
   - **Remove the need:** make the problem not happen, or ask whether the thing is needed at all.
   - **Restore what worked:** what did the old version do that the new one dropped?
   - **Reuse what exists:** a convention, mechanism, or data the user already has.
   - **Smallest change at the trigger:** fix the step that sets the problem off.
   - **Change the level:** solve it for the whole set instead of each item, or the reverse.
   - **General mechanism:** the fix that covers every case in theory.
3. **Walk each candidate through the real scenarios.** List the concrete cases, failure paths included. Add combinations of the small candidates as candidates of their own. For each candidate, say which cases it covers and what it costs: new code, new concepts, new copies, new steps, and the new failure modes it brings (duplicates, ordering, drift). A bigger fix wins only if it covers a realistic case that every smaller candidate or combination misses. Name that case, or drop the bigger fix. A cost or a case you did not verify is an assumption: label it, and do not let it decide on its own.
4. **Attack the current best.** Ask: which fact from step 1 does it ignore? What simpler candidate or combination covers the same cases? Imagine it failed in six months: why? Then subtract: for each part it adds (a copy, a step, a component, a check), say what goes wrong without it and what recovery costs. Drop each part whose loss is cheap to recover.
5. **Repeat.** A candidate that beats the best becomes the best, then go to step 4. Stop after 2 rounds in a row with no better candidate, or after 5 rounds.

When the choice is expensive to reverse and you can start a subagent, give a fresh subagent the problem and the top candidates in random order, with no favorite marked, and ask it to break each one. Feed what it finds into step 4.

For a contested code-level choice inside a repo, use the `decision-matrix` skill for steps 3 and 4 when it is available.

## Output

Present the parts in this order. Do not narrate the rounds.

```markdown
**Recommendation:** [the solution and its main reason, one sentence]

[the details: steps, code, commands]

**Why not the alternatives:**
- [alternative]: [the concrete reason it loses: a case it misses, or a cost it adds for no real case]
- [at least two alternatives, the strongest ones first]

**What would change this:** [a specific assumption that, if wrong, makes another option win, and which option]
```

If the user's own idea is one of the candidates, it appears under "Why not" when it loses, or it is the recommendation when it wins. Say which.

## Common mistakes

| Mistake | Fix |
|---|---|
| Calling the general mechanism "the real fix" without naming a case only it covers | Name the case from step 3, or recommend the smaller fix |
| Rejecting two small fixes one by one when together they cover every case | Test the combination as its own candidate |
| Rejecting the old, working fix on a cost you guessed ("it flickers", "it is slow") | Label the cost as an assumption; it cannot decide on its own |
| Writing a fact that defeats your answer ("lost keys can be recreated") and keeping the answer | Run the subtract check: that part's loss is cheap, so drop it |
| A best-practice default that the user's facts make unnecessary | Check each step 1 fact against the default |
| Adding a new file, clone, or setting next to an existing convention | Use the "reuse what exists" candidate unless it fails a real case |
| Steering each item when the target is for the whole set | Try the "change the level" candidate |
