---
name: owasp
description: "Use when writing or reviewing code that handles user input, authentication, sessions, authorization, APIs, webhooks, file uploads, data sync, LLM features, secrets, or third-party calls, even when security is not mentioned. Also use for questions about OWASP (Top 10, API Top 10, Mobile Top 10, MASVS, ASVS, LLM Top 10), injection, XSS, CSRF, SSRF, or how to secure an endpoint."
---

# OWASP Technical Security Controls

**The codebase wins.** Follow the project's existing security libraries, middleware, error handling, and code style. This skill adapts to the project, not the other way round. Where the project falls short of a rule here, raise it as a finding or proposal; do not silently rebuild its security layer. Use marker comments (such as `// SECURITY:`) only when the codebase already uses them.

Compliance frameworks such as ISO 27001 and SOC 2 (see the `compliance` skill) say *that* a control must exist. OWASP says *how to build it*. Default verification target: **ASVS 5.0 Level 2**. Raise it to Level 3 for parts of a system where the project or its risk profile asks for it.

## The rules

`references/owasp.md` holds the full rule set by control area: access control, auth and sessions, injection and I/O, web front-end, crypto, API limits, mobile, LLM, design, supply chain, error handling, logging, and concrete parameters. Read the sections for the platforms your change touches. Skip sections for platforms the project does not have. For anything non-trivial, read the whole file.

## Design gates (check on every change)

- **Authorization**: every new endpoint or query is deny-by-default and checked server-side. If the app is multi-tenant, every query is also tenant-scoped (query filter or row-level security), and a missing tenant filter blocks the release.
- **Untrusted input** (A05, API10, LLM01): every input path (endpoint, webhook body, sync payload, deep link, file upload, LLM tool argument, third-party API response) gets strict allow-list schema validation server-side. Parameterized queries and context-aware output encoding only. Verify webhook signatures before parsing.
- **Fail closed** (A10): errors in authorization, feature-flag, or permission lookups deny the action. One global exception handler: generic message plus correlation ID to the client, detail to logs. Multi-step operations are transactional, or idempotent and reconciled; never half-applied.
- **Resource limits** (API4): new endpoints get rate limits (per user or device, and per tenant if multi-tenant), pagination with a max page size, and payload or batch caps. Paid or outbound actions get quotas and spend ceilings.
- **Prompt injection** (LLM01, LLM06), if the change touches an LLM feature: untrusted content enters the model context only in delimited data blocks and taints the session, so high-risk tools then need human approval. Action targets resolve from verified IDs, never from model-extracted free text.

## Verification checklist (before marking a task complete)

- [ ] Authorization tested, including a denied-access case. If multi-tenant: a cross-tenant access attempt in a test fails.
- [ ] New input paths are schema-validated and injection-safe, covered by a negative test.
- [ ] New error paths fail closed (dependency-down and malformed-input cases tested).
- [ ] If LLM-facing: tool calls are schema-validated server-side and prompt-injection tests pass.
- [ ] New dependencies are pinned in the lockfile and free of known critical CVEs.
