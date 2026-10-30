---
max_turns: 6
allowed_tools: [Skill]
tags: [best-solution, natural]
---

Bug in our Flutter app (Riverpod). The month planner loads transactions per month and keeps a cached list. It applies add/update/delete events to that cached list, but it ignores events that arrive while the provider is rebuilding.

When a user saves a trip, the save flow first re-saves the user's work-from-home days (even when none of them changed), and that save makes the planner provider rebuild. The add event for the new trip then arrives during the rebuild and is dropped. Result: the saved day looks empty until a full page reload.

On develop this did not happen; there we called `invalidateSelf()` on the planner after saving trips, which was removed in a refactor. How should we fix this?
