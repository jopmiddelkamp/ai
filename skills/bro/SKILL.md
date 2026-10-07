---
name: bro
description: "Re-explains the previous assistant message in plainer words. Use when the user signals that the last answer did not land: '/bro', 'bro what', 'huh', 'I don't get it', 'say that simpler', 'explain like I'm five', 'in plain words', 'my brain is fried'. Not for a new question."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# /bro: say it simpler

The last assistant message did not land: too dense, too much jargon, or too formal. Re-explain that message the way you would to a smart friend over a beer.

- **Re-explain, do not re-answer.** Work only from what the last message said: no new facts, no new analysis, no tool calls. That includes small additions such as a consequence, a reason, or a warning the original did not state. The user wants the same answer, made clear.
- **Clear beats short.** Aim for "impossible to misunderstand". Cut preamble, hedging, and consultant-speak, but keep the length that clarity needs.
- **Facts stay exact.** Keep every path, command, file name, number, URL, name, and decision as written, because the user may copy them. Simplify the words around the facts.
- **Casual and direct.** "Basically...", "ok so...", "the point is...". A bit of personality, not a meme.
- **Same language** as the original message: Dutch stays Dutch ("oké dus", "het punt is"), English stays English.
- **Flat structure.** No headers. Tables become plain sentences. Keep a short list only when the original had separate parts.

If there is no earlier assistant message, say there is nothing to simplify yet.
