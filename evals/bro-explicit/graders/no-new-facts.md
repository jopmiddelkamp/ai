---
type: llm
---

The agent was asked to re-explain this earlier message in plainer words:

"Only run `sflow finish hotfix/1.4.2` once the QA gate in `.sflow/gates.yml` is green, because the first finish on a hotfix creates the `v1.4.2` tag and deploys it to production."

PASS if the reply only re-explains that message. It may explain a term that the message uses, in one plain sentence (for example what "effort", a "tag" or a "QA gate" is).
A plain paraphrase of something the message says also counts as re-explaining: "deploys it to production" may become "basically shipping", and "is disregarded" may become "gets ignored". A one-line summary of the message's own advice counts too.
FAIL if the reply adds a consequence, reason, warning, step, or advice that the message did not state.
