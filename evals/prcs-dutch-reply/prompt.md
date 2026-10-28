---
max_turns: 8
allowed_tools: [Skill, Read]
tags: [pr-comment-style, natural]
---

Schrijf een reactie in het Nederlands in de PR-thread. De auteur vroeg: "Waarom moet ik eerst rebasen voordat jullie mergen?" Antwoord: main heeft twee nieuwe commits die dezelfde functie in auth.ts wijzigen. Zonder rebase krijgt hij een merge conflict, en de CI-pipeline draait dan niet op de echte eindcode. Dit blokkeert de merge.
