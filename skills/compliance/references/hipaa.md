# HIPAA Security Baseline Rules

> HIPAA is a US federal law (45 CFR Parts 160/164) protecting human Protected Health Information (PHI) held by covered entities and their business associates.
> **Check applicability first.** HIPAA legally binds only US covered entities (health plans, health care clearinghouses, and health care providers that conduct certain electronic transactions) and their business associates. If the project is neither, HIPAA does not bind it; personal data of people in the EU falls under GDPR instead.
> Projects outside HIPAA's scope can still adopt the HIPAA **Security Rule** safeguards (45 CFR 164.308/310/312) voluntarily, as an engineering baseline for health data or records of comparable sensitivity.
> If the project may start handling human PHI for or as a covered entity (for example, US health care customers), stop and do a formal compliance review. That is the moment real BAAs and full HIPAA compliance become mandatory.
> Below, "sensitive records" means PHI, or whatever records the project treats as equivalent.

## Technical safeguards: access control (§164.312(a))

- Give every user, service, and integration its own unique identifier; never share accounts or API keys between users or services (§164.312(a)(2)(i)).
- Enforce authorization on every backend endpoint server-side; never rely on the client hiding a button (§164.312(a)(1)).
- If the app is multi-tenant, scope every query to the authenticated tenant (a tenancy filter in every data-access path, or row-level security); a missing tenant filter is a release blocker.
- Implement automatic logoff: idle-timeout web sessions; if there is a mobile app, require re-authentication (biometric or PIN) after inactivity or backgrounding (§164.312(a)(2)(iii)).
- Provide a break-glass emergency access path for support access to production data that is separately authenticated, time-boxed, and fully logged (§164.312(a)(2)(ii)).
- Grant third-party integrations scoped tokens limited to the specific data and, if multi-tenant, the specific tenant they serve; never issue platform-wide credentials.

## Technical safeguards: encryption (§164.312(a)(2)(iv), §164.312(e))

- If sensitive records are stored on devices (mobile or offline storage), encrypt that store at rest with a key held in the platform keystore, never hardcoded or stored in app files.
- Encrypt all transport with TLS 1.2+ (prefer 1.3); reject plaintext HTTP everywhere, including sync, webhooks, and integration callbacks (§164.312(e)(2)(ii)).
- Encrypt backend data at rest (database, backups, object storage) with managed KMS keys; encrypt backups with a different key than live data.
- Never write sensitive record details into logs, crash reports, analytics events, push-notification payloads, or URL query strings.
- Keep queued payloads and local caches (uploaded documents, images, PDFs) inside the encrypted store, not in plaintext temp or download directories.

## Technical safeguards: audit controls (§164.312(b))

- Emit an immutable audit event (who, what, when, which record, and which tenant if multi-tenant) for every create, detail read, update, and delete on sensitive records.
- Log all authentication events, permission changes, data exports, and third-party API access; make audit logs append-only and retained separately from application logs.
- If the system takes automated outbound actions (calls, emails, orders), audit-log each one with recipient and the data categories disclosed.
- Review anomalous access patterns (bulk reads, off-hours exports) via alerting, not manual log-grepping (§164.308(a)(1)(ii)(D)).

## Technical safeguards: integrity and authentication (§164.312(c), (d))

- Protect sensitive records from silent alteration: use server-authoritative timestamps, checksums or version columns, and conflict detection (§164.312(c)(2)).
- If clients sync offline edits, resolve conflicts on critical fields by preserving both versions for review; never silently apply last-write-wins.
- Authenticate every caller before returning data: no unauthenticated "lookup" endpoints, and verify webhook signatures from integration partners (§164.312(d)).
- Soft-delete sensitive records with an audit trail; support hard erasure as a deliberate, logged operation (for example a GDPR erasure request).

## Minimum necessary: data minimization (§164.502(b), §164.514(d))

- Return only the fields the consuming screen or partner needs; build per-role or per-purpose response shapes instead of serializing full entities.
- Give each role and partner access only to the records and data types its purpose requires.
- Default list views and search results to non-sensitive summary fields; require an explicit detail fetch (which is audit-logged) for the full record.
- Collect only what the feature needs: avoid free-text fields that invite users to paste sensitive data where structured fields suffice.
- Strip or pseudonymize identifiers in analytics, error tracking, and any AI/LLM prompt; never send raw sensitive records to third-party AI or telemetry services without a processor agreement (or a BAA where HIPAA applies).

## Sensitive-record handling

- Model sensitive records with an explicit data classification so serializers, loggers, and exporters can enforce redaction by type, not by convention.
- If automated phone calls disclose sensitive details: verify the callee (known number plus a confirmation step) before disclosing anything, and disclose the minimum necessary for the call's purpose. Never leave sensitive details in voicemail; leave only a callback request.
- In email, prefer a link to an authenticated view over embedding the full record in the body.
- Do not put sensitive details in SMS, email subject lines, or push-notification text; use neutral wording ("You have a new update to review").
- Store safety-critical values (for example dosages) as validated structured data with unit checks, never as free text.

## Breach readiness (§§164.400–414)

- Design so a lost device is a non-event: encrypted local storage, remote session revocation, and short-lived tokens mean device loss does not equal a data breach (encryption safe harbor, §164.402).
- Build a "what did this credential touch" query path now: audit logs must answer the scope, records, and time window of any compromise within hours.
- Support immediate revocation of any integration partner's access (a kill switch per partner, and per tenant if multi-tenant).
- Keep an incident runbook: classify, contain, assess (four-factor style: what data, who got it, was it viewed, mitigation), and notify. Use the strictest deadline that applies: GDPR's 72 hours to the supervisory authority where GDPR applies; HIPAA's 60 days where HIPAA applies.
- Alert on bulk export, mass read, and audit-log write failures; detection is a prerequisite of notification.

## Third parties: BAA or equivalent (§164.308(b), §164.314(a))

- Sign the right agreement before any vendor (hosting, telephony, email, error tracking, AI APIs) touches sensitive data: a BAA where HIPAA applies, a GDPR processor agreement (DPA) where GDPR applies.
- Document the data residency of every processor; where GDPR applies, document the transfer mechanism (for example SCCs) for any vendor outside the EU before integrating it.
- Verify each integration partner receives data only under a documented agreement defining purpose, scope, retention, and deletion.
- Pin per-vendor allowlists in code or config for which data categories may flow to each external service; block new outbound data flows that lack an entry.
- Re-check the applicability note at the top of this file before onboarding US health care customers or adding features that handle human health data.
