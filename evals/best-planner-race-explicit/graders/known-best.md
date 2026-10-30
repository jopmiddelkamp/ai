---
type: llm
---

PASS if the recommended fix stops re-saving the work-from-home days when they did not change (so the needless rebuild no longer happens), alone or together with restoring the `invalidateSelf()` refresh after saving trips.
FAIL if the main recommendation is a new mechanism such as buffering, queueing, or replaying events during rebuilds, or if it does not address the needless work-from-home save.
