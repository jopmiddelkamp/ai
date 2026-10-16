---
type: llm
---

PASS if the answer uses exactly three top-level sections, "Plugins to Add", "Plugins to Remove" and "What else have I done", gives each listed plugin a one-line "Why", and has no table and no JSON block.
FAIL if a section is missing, a table or JSON block appears, or the answer lists the plugins it left out.
