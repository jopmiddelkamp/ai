---
type: llm
---

PASS if the reply does all three:
1. It says in plain words what the "QA gate" is, using only what the quoted message implies (a check in `.sflow/gates.yml` that must be green before the finish).
2. It names who does each step: the user runs `sflow finish hotfix/1.4.2`, and sflow creates the `v1.4.2` tag and deploys it to production.
3. It does not use "the first finish" as a bare label. It replaces the label with what it means, such as "the sflow finish run that creates the `v1.4.2` tag" or "the first time you run that finish command, sflow creates the `v1.4.2` tag".
FAIL if any of the three is missing. Ignore any extra line about plugins or plugin-scout; other graders check for added content.
