---
max_turns: 6
allowed_tools: [Skill]
tags: [best-solution, explicit]
---

Use your best-solution skill if you have one. I generate a deck of 100 AI images for a card game. The deck must hit target shares on several measures at once, for example 38% dark mood, 51% with a person in the image, and a few more like that.

Writing the prompts toward the targets does not work: only about 20% of the cards come out dark, and only 30% of the images I prompt as "dark" actually render dark. A judge model tags each finished image on every measure, and I already have 352 generated and paid-for images in the pool. I was planning to write one specialized prompt per target mood and assign them by quota.

How do I get a deck that actually hits the targets?
