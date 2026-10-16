---
type: llm
---

PASS if the reply rates the static `Database.query` calls inside the business logic at the highest severity level the reply uses anywhere. Other findings may share that level. Ignore the order of findings and the formatting.
FAIL if the reply gives the static database calls a lower severity than any other finding, or does not mention them.
