# SOC 2 Rules

SOC 2 is an AICPA attestation report against the Trust Services Criteria (2017, with 2022 points of focus): Type I attests control design at a point in time, Type II attests operating effectiveness over a period (typically 3-12 months). It is voluntary but expected by many B2B customers and partners. Controls must run and produce evidence for months before a Type II report is possible, so a project that may pursue it builds them in from the first line of code. Categories: Security (CC1-CC9, always in scope), Availability (A1), Processing Integrity (PI1), Confidentiality (C1), Privacy (P, overlapping GDPR). The organization picks which categories beyond Security are in scope; apply the matching sections.

## Change management & CI/CD (CC8)

- Route every production change through a pull request; never commit directly to the main branch. (CC8.1)
- Require CI to pass (build, tests, lint, dependency audit) before any merge to main. (CC8.1)
- Keep infrastructure as code in the repo, so infra changes get the same PR review and history as app code. (CC8.1)
- Separate deploy from merge: deployments happen via the CI/CD pipeline, never by hand from a laptop. (CC8.1)
- Make every deploy traceable: tag releases, record who deployed what and when, and keep a documented rollback path. (CC8.1)
- Keep dev, test, and production environments and data strictly separated; never use production data in tests or fixtures. (CC8.1)
- Gate risky changes behind feature flags so they can be disabled without a redeploy. (CC8.1)
- If the team is too small for independent peer review, compensate: keep a pre-merge checklist in the repo and record self-review or AI-review notes in the PR description. (CC8.1, CC4.1)

## Logical access (CC6)

- Deny by default: every API endpoint and screen requires authentication and an explicit authorization check; no anonymous or "internal only by obscurity" routes. (CC6.1)
- Implement role-based access. If the app is multi-tenant, enforce tenant isolation in every query (tenant filter or row-level security), never only in the UI. (CC6.1, CC6.3)
- Grant least privilege everywhere: service accounts, DB users, cloud IAM roles, and third-party API tokens get only the permissions they need. (CC6.1, CC6.3)
- Require MFA on all admin and infrastructure accounts (cloud console, DB, CI/CD, registrar, email provider). (CC6.1)
- Never hardcode secrets; load them from a secret manager or environment, rotate on exposure, and keep `.env` files gitignored. (CC6.1)
- Build user lifecycle handling from day 1: provisioning, deprovisioning, and role change must fully revoke sessions and tokens immediately. (CC6.2, CC6.3)
- Maintain an access matrix (who or what can access which system and data) in the repo and update it when roles change. (CC6.1, CC6.2)
- Encrypt data in transit (TLS 1.2+ only) and at rest (DB, backups, object storage, and any device-local storage of sensitive data). (CC6.6, CC6.7)
- Hash passwords with a modern KDF (argon2 or bcrypt), use short-lived access tokens with refresh rotation, and, if clients work offline, expire offline sessions after a defined period. (CC6.1)
- If sensitive data lives on user devices, encrypt the local store and support remote invalidation of a device's credentials. (CC6.7)

## Monitoring & alerting (CC7)

- Emit structured logs (for example JSON) with timestamp, actor, action, outcome, and tenant if multi-tenant, for every security-relevant event: logins, failed logins, permission changes, data exports, admin actions. (CC7.2)
- Never log secrets, tokens, passwords, or personal data; scrub before logging. (CC7.2, C1.1)
- Ship logs to a central store with retention of at least 12 months and protection against tampering or deletion. (CC7.2)
- Alert on anomalies: error-rate spikes, repeated auth failures, unusual data-export volume, and failed background jobs. (CC7.2, CC7.3)
- Enable automated vulnerability and dependency scanning (for example Dependabot, SAST) in CI and treat critical findings as blocking. (CC7.1)
- Maintain an incident response runbook in the repo (detect, contain, eradicate, recover, post-mortem, customer and regulatory notification) and log every incident with a post-mortem. (CC7.3, CC7.4, CC7.5)
- If infrastructure is defined as code, alert when production config drifts from it. (CC7.1)

## Availability & backup (A1)

- Define uptime and RPO/RTO targets in a doc in the repo before making customer commitments; design to them. (A1.1)
- Automate daily encrypted backups of all production datastores, stored in a separate location or account from production. (A1.2)
- Test restores on a schedule (at least quarterly) and record the result; an untested backup does not count. (A1.3)
- Monitor capacity (DB storage, queue depth, API latency) and alert before limits are hit. (A1.1)
- If users must keep working without connectivity, design the client offline-first and make sync resumable after interruptions. (A1.2)
- Apply timeouts, retries with backoff, and circuit breakers on all third-party calls, so one partner outage cannot take the platform down. (A1.1, CC9.1)
- Run health-check endpoints and external uptime monitoring with alerting from day 1. (A1.1)

## Processing integrity (PI1): when the system acts in the real world

Applies when the system places orders, makes payments, calls, sends emails, or books on a user's behalf. Treat every such action as a financial transaction.

- Require explicit user approval before any impactful automated action; record who approved, what exactly, and when. Never let AI or automation act on ambiguous consent. (PI1.1, PI1.4)
- Make every external action idempotent: generate a unique idempotency key per intended action and enforce it at the integration boundary, so retries, replays, and double-clicks never cause duplicate orders or calls. (PI1.3)
- Model each automated action as a state machine (draft → approved → submitted → confirmed/failed) persisted in the database; never fire-and-forget. (PI1.3)
- Write an immutable audit trail entry for every automated action: input, approval, timestamp, target partner, request and response identifiers, and outcome; make it visible to the user. (PI1.2, PI1.4)
- Validate all inputs at the edge (schema validation, quantity and price sanity limits, allowed-partner checks) before an action is queued; reject rather than guess. (PI1.2)
- Reconcile regularly: compare actions the system believes it executed against partner confirmations (order confirmations, call logs, email delivery receipts) and alert on mismatches. (PI1.4, PI1.5)
- If actions can be queued offline, handle sync conflicts deterministically with a documented resolution strategy; never silently drop or duplicate a pending action. (PI1.3)
- Build a kill switch per integration and per action type, so automated actions can be halted instantly. (PI1.1, CC7.3)
- Set spend and frequency guardrails (for example max order value, max calls per day per account) with hard server-side enforcement and alerts on threshold breach. (PI1.1)
- Make failed actions loud: surface failures to the user and to internal alerting; never swallow a partner API error. (PI1.4, CC7.3)

## Confidentiality & privacy (C1, P series)

- Classify data in a doc in the repo (public, internal, confidential, personal) and tag customer business data as confidential by default. (C1.1)
- Collect only the data a feature needs (data minimization) and define retention periods; implement deletion or anonymization jobs that actually run. (C1.2, P4.2, P4.3)
- Build data export and account deletion as first-class features (this also covers GDPR access and erasure rights where GDPR applies). (P5.1, P5.2)
- Never send personal data to third parties (including LLM APIs) beyond what the integration strictly requires; document each data flow per partner. (C1.1, P6.1)
- Keep production data access rare, logged, and justified; no ad-hoc production DB queries without a recorded reason. (C1.1, CC6.1)

## Vendor management (CC9)

- Maintain a vendor register in the repo (cloud, telephony, email, LLM, payment, partner APIs) with data shared, DPA status, subprocessor role, and SOC 2 or ISO 27001 status of each vendor. (CC9.2)
- Review vendor security posture before integrating a new third party and re-review annually; choose hosting regions deliberately (for example EU-region for personal data under GDPR). (CC9.2)
- Scope third-party credentials minimally, store them in the secret manager, and rotate them on a schedule. (CC9.2, CC6.1)
- Design integrations so a vendor can be replaced: isolate each partner behind an internal interface and keep exported copies of critical data. (CC9.1)

## Evidence habit (all criteria)

- Prefer controls that generate evidence automatically (CI logs, PR history, alert history, backup job logs) over manual checklists; when a control is manual, record its execution in the repo or ticket system. (CC4.1)
