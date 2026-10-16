---
max_turns: 8
allowed_tools: [Skill, Read, Glob, Grep]
tags: [compliance, explicit]
---

Use your compliance skill if you have one. Write an Express route in TypeScript, GET /patients/:id, that lets a logged-in nurse view a patient record. We have a `db.patients.findById` and a `req.user` with `id` and `role`. Return only the code.
