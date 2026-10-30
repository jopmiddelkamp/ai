---
type: llm
---

PASS if the main recommendation is to select the 100 cards from a larger pool (the 352 existing images, topped up when needed) so the deck as a whole hits all targets at once, for example with an optimizer or a greedy picker over the judge tags.
FAIL if the main recommendation is still to steer each card through prompts (per-mood prompts, quotas, prompt tuning, regenerating until each card fits).
