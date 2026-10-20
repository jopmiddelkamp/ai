---
type: llm
---

The agent was asked to re-explain this earlier message in plainer words:

"The effort resolution order prioritizes an explicit selection via CLAUDE_CODE_EFFORT_LEVEL, the --effort flag, or /effort; failing that, per-model modelSettings take precedence, and a top-level effortLevel in ~/.claude/settings.json is disregarded for Opus 5.5, so set modelSettings.claude-opus-5-5.effortLevel to xhigh."

PASS if the reply only re-explains that message. It may explain a term that the message uses, in one plain sentence (for example what "effort", a "tag" or a "QA gate" is).
A plain paraphrase of something the message says also counts as re-explaining: "deploys it to production" may become "basically shipping", and "is disregarded" may become "gets ignored". A one-line summary of the message's own advice counts too.
FAIL if the reply adds a consequence, reason, warning, step, or advice that the message did not state.
