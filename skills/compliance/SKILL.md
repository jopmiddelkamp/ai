---
name: compliance
description: "Use when writing or reviewing code that handles personal, financial, health, or otherwise sensitive data, or that takes automated real-world actions such as orders, payments, emails, or calls. Also use for questions about audit readiness, ISO 27001, SOC 2, HIPAA, GDPR, data handling, retention, logging, vendors, or \"is this compliant\"."
---

# Compliance-First Development

Security and compliance controls are cheapest when they exist from the first line of code. SOC 2 Type II needs months of operating evidence, ISO 27001 audits your history, and retrofitting encryption, audit trails, or tenant isolation into a shipped system costs far more than building them in. A team that may ever sell to enterprise customers, handle sensitive data, or act on a user's behalf benefits from these habits even before it pursues a certification.

**The codebase wins.** This skill adapts to the project, not the other way round. Implement each control with the project's existing conventions, libraries, patterns, and style. Where the project already solves a control (an audit logger, a secret loader, a redaction helper), reuse it. Use special marker comments only when the codebase already uses them.

This skill covers the management-system frameworks and the audit evidence they demand. The *technical* security controls (authorization mechanics, input validation, session parameters, LLM safety) live in the sibling `owasp` skill. Load both.

## The framework rules

Three files in this skill's `references/` define the controls. They are short. Read the ones that match your task before designing anything non-trivial:

| File | What it governs | Read it when |
|---|---|---|
| `references/iso-27001.md` | Secure SDLC, access control, crypto, logging, backup, suppliers, incident readiness, audit-evidence docs | Almost always; it is the broadest baseline |
| `references/soc2.md` | Change management and CI/CD, monitoring, availability, **processing integrity** (automated real-world actions), vendors | CI/CD or infra work, or any feature that acts in the real world (orders, payments, calls, emails) |
| `references/hipaa.md` | Health or similarly sensitive records, minimum-necessary data exposure, record integrity, breach readiness | Any feature touching health data or records with comparable sensitivity |

Legal scope: HIPAA legally binds only US covered entities (health plans, health care clearinghouses, and health care providers that conduct certain electronic transactions) and their business associates. Outside that scope, its Security Rule is a useful voluntary baseline. GDPR applies to personal data of people in the EU. Never claim HIPAA, SOC 2, or ISO 27001 compliance in user-facing text or marketing copy unless the organization actually holds it.

## Compliance design gates (check on every change)

- **Data classification**: sensitive data (health, financial, personal contact, credentials) is marked as such in the data model, so serializers, loggers, and exports treat it by type, not by convention.
- **Minimum necessary**: responses use per-role or per-purpose shapes, never full-entity serialization; integrations receive only the fields they need.
- **Secrets**: nothing secret in code, config files in git, logs, or client bundles; secrets come from a secret manager, environment, or platform keystore.
- **Audit trail**: security-relevant events (auth, permission change, export, sensitive-record detail read) emit append-only structured audit records with who, what, when, and, if the app is multi-tenant, which tenant.
- **Encryption**: TLS 1.2+ everywhere; at rest for databases, backups, and object storage. If the app stores sensitive data on devices, encrypt that store too, with the key in the platform keystore.
- **No production data** in tests, fixtures, or local dev; use synthetic data.
- **If the system performs automated real-world actions** (orders, payments, calls, emails, bookings): explicit user approval checked at execution time, an idempotency key enforced at the integration boundary, a persisted state machine (draft → approved → submitted → confirmed/failed), server-side spend and frequency guardrails, and a per-integration plus global kill switch.

## Evidence files (when the project pursues ISO 27001 or SOC 2)

These living documents serve as audit evidence. Apply this section when the project pursues ISO 27001 or SOC 2, or already keeps such documents. Use the project's existing location and format if it has one; the paths below are a suggested default. Create a file the first time a task needs it; update it whenever the relevant thing changes:

- `docs/security/supplier-register.md`: every third-party service, data shared, auth method, DPA status, region (create or update before wiring any integration)
- `docs/security/data-inventory.md`: systems, data categories, locations
- `docs/security/risk-register.md`: add an entry whenever a design decision accepts a security trade-off
- `docs/security/incident-response.md`: detection, containment, and breach-notification steps (for example GDPR's 72-hour deadline where GDPR applies)
- `docs/security/continuity.md`: RPO/RTO targets, backup and restore procedure
- `docs/security/access-reviews/`: dated quarterly access-review notes

## Verification checklist (before marking a task complete)

- [ ] No sensitive fields in logs, error messages, analytics, or LLM prompts introduced by this change
- [ ] Audit events emitted for new security-relevant operations, and covered by a test
- [ ] No secrets in the diff (`git diff` shows no keys, tokens, connection strings)
- [ ] If the change adds an automated real-world action: idempotency, approval check, guardrails, and kill switch each covered by a test
- [ ] If the project keeps evidence files: updated when the change added a vendor, data store, or accepted risk
