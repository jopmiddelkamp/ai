# OWASP Engineering Rules

OWASP defines technical security controls for application code. Compliance frameworks such as ISO 27001 and SOC 2 say *that* a control must exist; OWASP says *how to build it*. Default verification target: **ASVS 5.0 Level 2**. Apply Level 3 to the parts of a system the project or its risk profile marks as high-assurance.

Apply only the sections for platforms the project has. The project's existing security libraries, middleware, and conventions win over the specific techniques named here, as long as they meet the same control.

Editions referenced (verified 2026-07):

| Standard | Edition | Applies to |
|---|---|---|
| OWASP Top 10 | 2025 (A01–A10) | Web apps and back ends |
| OWASP API Security Top 10 | 2023 (API1–API10) | APIs, sync endpoints, webhooks |
| OWASP Mobile Top 10 + MASVS | 2024 / v2.1.0 | Mobile apps |
| OWASP ASVS | 5.0.0, Level 2 | Verification baseline, all platforms |
| OWASP Top 10 for LLM Applications | 2025 (LLM01–LLM10) | LLM features and automated actions |
| OWASP Proactive Controls | 2024 (C1–C10) | Design-time defaults |
| OWASP Cheat Sheet Series | living | Concrete parameters (bottom of this file) |

## Access control (A01, API1/API3/API5, ASVS V8, C1)

- Deny by default through one central authorization layer: every route declares its required permission; a route with no declared policy fails closed and, where the tooling allows, fails CI (ASVS 8.2.1, C1).
- Authorize the object, not just the endpoint: every read and write verifies the caller may access that specific resource and that the caller's role permits the action (IDOR, ASVS 8.2.2). Scope the query to what the caller owns first, then find by ID (for example `currentAccount.orders.find(id)`, never `Order.find(id)`).
- Use permission-based checks (for example `user.can('order:delete', resource)`), not hard-coded role comparisons. Actors who act across ownership boundaries (support staff, partners, external collaborators) get access through explicit grant records (scoped, revocable, time-boxed), never through "role implies access" (C1, API5).
- Never bind request bodies to ORM entities. Use per-endpoint, per-role input DTOs that reject unknown properties; a regular user must not be able to set ownership, role, or approval fields through mass assignment (API3 BOPLA). Response DTOs are explicit allow-lists, shaped per role.
- SSRF (folded into A01:2025): any server-side fetch of a user- or integration-supplied URL goes through an https-only allow-list, blocks private, link-local, and metadata ranges (10/8, 172.16/12, 192.168/16, 127/8, 169.254/16, ::1) **checked on the resolved IP at connect time**, follows no redirects, runs from a segmented egress path, and never returns the raw response to the client (C10, API7). Provider base URLs come from static server config, never from client input or webhook payloads.
- The role matrix (each role plus anonymous × each endpoint) is asserted in tests; the matrix is the spec.

**If the app is multi-tenant:**

- Tenant context comes from the authenticated token or session only, never from a request parameter, header, or body field. Enforce it in one place, such as the data-access layer or database row-level security (in Postgres, `FORCE ROW LEVEL SECURITY` so it binds the table owner too) (ASVS 8.4.1).
- Return **404, not 403**, for objects outside the caller's tenant; never confirm another tenant's records exist (API1).
- Per new resource, write the cross-tenant test: authenticate as tenant B, request tenant A's IDs across GET/PUT/PATCH/DELETE (and sync, if present). All must fail.

**If the app syncs data from offline clients:**

- Sync batches are a high-risk surface: authorize and property-filter every record in a push or pull batch individually server-side, through the same DTO and policy pipeline as normal writes, including conflict-resolution paths (API1, API3).

## Authentication, sessions & tokens (A07, API2, ASVS V6/V7/V9, C7)

- Use a proven identity library or provider; never hand-roll password hashing, session handling, or JWT validation. MFA on admin surfaces and on web apps that hold sensitive data (ASVS 6.3.3).
- Passwords: min 8 characters with MFA, 15 without; max at least 64; all characters allowed; no composition rules; no forced rotation; check against a breached-password list; constant-time comparison; identical generic failure messages (no user enumeration).
- Rate-limit auth endpoints per account (not just per IP) with exponential backoff; alert on credential-stuffing patterns (ASVS 6.3.1).
- Access tokens short-lived (~15 min); refresh tokens rotate with reuse detection and server-side revocation per device, so "log out other devices" and lost-device cutoff actually work. Rotate the session or token on every (re)authentication (ASVS 7.2.4); terminated sessions are dead immediately (ASVS 7.4.1).
- JWT validation: explicit algorithm allow-list (ES256/EdDSA/PS256 preferred; reject `none` and header-driven alg); validate `iss`, `aud`, `exp`; revocation denylist keyed on `jti`+`iss`; HMAC secrets at least 256-bit from a CSPRNG, never shared across audiences.
- Step-up re-authentication before changing email, phone, MFA, or recovery settings; changing webhook URLs or payout settings; and transferring account or organization ownership (ASVS 7.5.1).
- Machine callers authenticate too: per-integration secrets (for example HMAC for webhooks), never one shared static API key.

## Injection & input/output handling (A05, ASVS V1/V2, C3)

- Parameterized queries for all database access, including any local database on a client; ban string-built SQL through lint or review (ASVS 1.2.4). Identifiers that cannot be bound (column names, sort order) go through allow-list maps.
- No user input in shell commands; if unavoidable, use exec APIs with argument arrays, never shell interpolation (ASVS 1.2.5).
- Strict schema validation (types, lengths, enums, ranges, allow-lists) at the API boundary for all input, including every field of sync payloads and webhook bodies; reject unknown properties. Validation lives on the server; client-side validation is UX only (ASVS 2.2.1/2.2.2).
- XSS: rely on framework auto-escaping. Ban the escape hatches (`dangerouslySetInnerHTML`, `v-html`, `bypassSecurityTrust*`) except through a sanitizer wrapper such as DOMPurify; use safe DOM sinks (`.textContent`, not `.innerHTML`). Encoding is the primary defense; validation and CSP are backstops.
- Content placed into outbound emails, messages, and third-party payloads is an injection surface too: use providers' structured APIs, escape per context, and guard against email header injection and CSV formula injection (`=`, `+`, `-`, `@` prefixes) in exports.
- No native deserialization of untrusted data (Java serialization, pickle); plain JSON with schema validation only (A08).
- Anchored, length-bounded regexes with explicit character classes (ReDoS-safe); normalize Unicode before validating.

## Web front-end (ASVS V3, C8, cheat sheets)

Applies if the project has a browser front-end.

- Session cookie: `__Host-` prefix, `Secure; HttpOnly; SameSite=Strict; Path=/`, no Domain attribute, generic name, at least 64 bits of CSPRNG entropy; never in localStorage or URLs; `Cache-Control: no-store` on responses carrying tokens or sensitive data; `Clear-Site-Data` on logout.
- CSRF protection on every state-changing request: framework built-in synchronizer tokens (or signed double-submit). `SameSite` is defense in depth, not the control. Never mutate state through GET (ASVS 3.5.1).
- Security headers on every response: the set in the parameters section below; CSP without `unsafe-inline` for scripts.
- CORS: exact origin allow-list; never `*` with credentials.
- Self-host JavaScript; if a third-party-hosted script is unavoidable, Subresource Integrity is mandatory (A08).
- Session timeouts: idle 15–30 min, absolute 4–8 h; regenerate the session on login and privilege change.

## Cryptography & secrets (A04, ASVS V11/V13, C2, M10)

- Vetted libraries and platform primitives only. AES-256-GCM (or ChaCha20-Poly1305) for application-level encryption. No MD5 or SHA-1 for anything security-relevant, no ECB, no homegrown crypto. CSPRNG for every key, nonce, and token (at least 128 bits for invite and reset tokens) (ASVS 11.3.2, 11.5.1).
- Password hashing: argon2id m=19456 t=2 p=1 (or bcrypt cost ≥10 where argon2 is unavailable); per-user salts come automatically; upgrade work factors by re-hashing at next login (ASVS 11.4.2).
- Secrets live in a managed vault or KMS with rotation and access audit; never in code, git, config files, container image ENV, CI logs, or client binaries. Run a secret scanner (for example gitleaks or detect-secrets) as a blocking pre-commit or CI check (ASVS 13.3.1). Anything embedded in a client binary is public; clients hold only per-user, revocable tokens.
- TLS 1.2+ (prefer 1.3) everywhere, including service-to-service and third-party calls; HSTS with preload; no sensitive data (tokens, personal data, sensitive record IDs) in URLs or query strings, because they end up in proxy and server logs (ASVS 14.2.1).

## API, resource limits & third-party consumption (API4/API6/API8/API9/API10, ASVS V4)

- Rate limits per token or device and per user, plus per tenant if multi-tenant, so one runaway client cannot degrade others. Return 429 with `Retry-After`; clients back off with jitter (API4, ASVS 2.4.1).
- Hard caps everywhere: max body size, max batch size, mandatory pagination with a max page size (no "return all"), upload size, count, and storage quotas, bounded queue depths, and timeouts plus circuit breakers on every downstream call.
- Paid or automated outbound actions (messages, calls, orders, payments) get quotas, spend ceilings, and anomaly alerting; loops triggered by an attacker or a bug cost real money (API4/API6).
- Sensitive business flows (checkout, invitations, high-value record writes) get flow-level throttling and non-human-pattern detection beyond generic rate limits (API6).
- Inbound webhooks are untrusted input: verify the signature and timestamp (replay window) before parsing anything else, enforce idempotency by event ID, and schema-validate strictly. A webhook may only transition records **you created**, looked up by your own ID; never create or modify arbitrary records from webhook fields (API10).
- Validate, bound, and time out all third-party API responses before using them in business logic; provider-triggered automation runs through the same quota and approval controls as user-triggered automation (API10).
- Wrong method → 405, oversized → 413, wrong content type → 415; every response carries an accurate `Content-Type` (ASVS 4.1.1); generic API errors, no stack traces or framework banners; debug and introspection endpoints (GraphQL introspection, playgrounds, actuators) off in production (API8, ASVS 13.4.2).
- API inventory: an API description (for example OpenAPI) generated from code, covering every route including sync, webhooks, and admin. Version the API with a sunset policy; old versions kept alive for old clients get the same auth middleware and patches. Where possible, a running route absent from the spec fails CI (API9).
- File uploads: extension allow-list plus magic-byte check, random filenames, stored outside the webroot in private storage, served through access-checked, short-lived signed URLs with the correct Content-Type, size limits enforced after decompression.

## Mobile app (M1–M10, MASVS v2.1)

Applies if the project ships a mobile app.

- If the app stores sensitive data locally, encrypt the local database (for example SQLCipher, AES-256). The key is a random 256-bit value generated on the device and held in Android Keystore (StrongBox where available) or iOS Keychain (`ThisDeviceOnly`, Secure Enclave-backed); never derived from a hardcoded string or user ID (M9, MASVS-STORAGE/CRYPTO).
- Tokens only in keystore-backed secure storage; never in plain preferences, unencrypted key-value stores, or the app database. An HTTP interceptor redacts `Authorization` before any logger or crash reporter sees it (M1).
- Exclude sensitive files from backups: `allowBackup=false` (or `dataExtractionRules` excluding the database, WAL/journal, preferences, and key files) on Android; `NSURLIsExcludedFromBackupKey` plus file protection classes on iOS (M8, MASVS-STORAGE-2).
- Network: `cleartextTrafficPermitted=false`, ATS with no exceptions, full platform certificate validation (never a permissive certificate callback). For high-assurance APIs, add certificate or SPKI pinning with a backup pin and a remote rotation strategy; a pin failure is a security event, not an "offline" state (M5, MASVS-NETWORK).
- If the app works offline: local access is gated by device unlock plus biometric or PIN unlocking a keystore-protected key (not a flippable boolean). On definitive token revocation (as opposed to mere network absence; distinguish the two explicitly), lock the app and block further local edits (M3, MASVS-AUTH).
- Deep links: verified App Links or Universal Links; parameters validated against an allow-list before navigation; nothing from a link goes into a WebView, file path, or query (M4, MASVS-PLATFORM).
- Wipe on logout or account removal: delete the local database and destroy the keystore key (crypto-shredding); purge cached exports; keep sensitive data out of analytics, notifications, the clipboard, and app-switcher previews (M6/M9, MASVS-PRIVACY).
- Release hardening is defense in depth, never the boundary: obfuscation and split debug info, R8/ProGuard on Android, no `debuggable` builds; Play Integrity or App Attest verified server-side; root, jailbreak, and hooking detection that warns, restricts sensitive operations, and logs server-side (M7, MASVS-RESILIENCE). Before each release, run `strings` or a decompiler (for example jadx) on the artifact to confirm no secrets survived.

## LLM features & automated actions (LLM01–LLM10)

Applies if the project uses an LLM, especially one that can call tools or take actions.

- Assume prompt injection; you cannot fully prevent it. Wrap all untrusted content (emails, documents, transcripts, web pages, third-party responses) in delimited data blocks declared as data, never instructions. Scan inbound content for injection where feasible. Once untrusted content enters the context, taint the session: high-risk tools (send a message, place an order, make a payment) then require human approval (LLM01).
- Recipients, amounts, and targets never come from model-extracted free text: tool schemas take IDs resolved against a verified source (for example `contact_id` from the contacts table), not `email: string` or `phone: string` (LLM01/LLM05).
- Every LLM-produced tool call is schema-validated server-side (types, enums, ranges) and semantically bounded (quantity caps, recipients must exist). LLM output is untrusted input everywhere downstream: parameterized queries, escaped rendering, never eval'd (LLM05).
- Tiered agency, enforced in the backend executor (hiding a tool from the prompt is not a control): read = automatic; draft = automatic but visible; send, order, call = explicit user confirmation showing the exact recipient, content, and amount; payments and other high-impact or above-threshold actions = confirmation plus step-up auth (LLM06).
- The agent's service credentials are minimally scoped. Hard daily caps on outbound actions per user (and per tenant if multi-tenant); idempotency keys plus a cancellation window on queued actions; per-capability kill switches checked on every action and tripped automatically on anomaly signals (LLM06/LLM10).
- Context minimization: retrieve only the fields the task needs, never bulk records; retrieval is access-scoped server-side regardless of what the prompt asks; redact sensitive data and PII from prompt and response logs; no secrets in system prompts or tool descriptions; assume the system prompt is public (LLM02/LLM07).
- High-stakes factual content (medical, legal, financial, safety) is never free-generated: it comes from an authoritative structured source or routes to a human expert. The backend cross-checks numeric claims against the source of record; missing or conflicting data → ask the user, as an explicit code branch (LLM09).
- If RAG is used: partition the vector store at the database-permission level by the same boundary as the rest of the app (user or tenant); documents carry provenance and a trust tier; ingestion runs the injection scanner; retrieval respects record ACLs; retrieved document IDs are logged per context (LLM08).
- Bound loops: max agent iterations, max context size, and a wall-clock timeout per task, aborting safely (no half-executed actions); token and request budgets per user or tenant; pinned model versions; prompt and model changes run the injection test suite in CI before rollout (LLM03/LLM10).

## Design-time (A06, C4)

- Threat-model (for example with STRIDE) every feature that crosses a trust boundary (user or tenant boundaries, sensitive data, third-party actions) before implementation; record abuse cases and required controls in the plan or PR.
- Write misuse tests alongside unit tests for critical flows: what must NOT be possible is part of the spec.
- Minimize attack surface: no admin tools, sample apps, or unused functionality in production; unauthenticated, user, admin, and internal or ops surfaces are distinct routes with distinct credentials.
- Secure defaults as the paved road: the easy way to add an endpoint, query, or tool must be the safe way (central middleware, scoped repositories, generated clients). Never rely on security by obscurity.

## Supply chain & CI/CD (A03, M2, C6, ASVS V15)

- Lockfiles committed and enforced for every package manager in the project; upgrades through reviewed PRs only; SCA scanning (for example osv-scanner, Dependency-Check, or Renovate) blocking on known-exploited criticals; an SBOM (for example CycloneDX) per release.
- Vet packages that touch data, crypto, or storage: maintained, provenance-verified, no abandoned dependencies in the data path; scoped package names against dependency confusion.
- Hardened CI/CD: MFA on VCS and CI, branch protection with required review and no bypass, short-lived OIDC cloud credentials (no long-lived deploy keys), least privilege per pipeline, secrets injected from a vault and masked, non-root runners.
- Artifacts are signed and verified at deploy. Release builds come from tagged CI commits only (signing keys in a secrets manager, never on laptops); use staged rollouts. Anything a client fetches and trusts (config pushes, OTA bundles) is signature-checked before use (A08).

## Exceptional conditions & availability (A10, ASVS V16)

- One global exception handler per service: unknown errors → generic message plus correlation ID to the client, full detail to logs only. Empty `catch` blocks and broad catch-and-continue are banned by lint (ASVS 16.5.1).
- Fail closed: if the authorization layer, feature-flag store, or a permission lookup errors, deny. Test "dependency down → request denied" explicitly.
- Strict schemas reject missing, extra, or null parameters instead of proceeding with defaults; this matters most for partial batches, such as sync after connectivity loss.
- Multi-step operations are transactional. External side effects that cannot roll back get idempotency keys plus a reconciliation job: no external action fires while the local write failed, no half-merged state.
- Timeouts, retries with backoff and jitter, and circuit breakers on every third-party call; test unhappy paths in CI (fault injection, malformed payloads, mid-operation crashes).

## Logging & alerting (A09, C9, ASVS V16)

- The 2025 emphasis is **alerting**, not only logging: real-time alerts, with a named responder and runbook, on brute-force patterns, 403/404 spikes by authenticated users (IDOR probing), anomalous traffic or sync volume, and bursts of automated actions. Test that a synthetic failed-login burst actually fires the alert.
- Log security events with when, where, who, and what (see the `compliance` skill for audit-trail rules); also log input-validation failures and business-logic sequence violations (C9).
- Strip CR/LF and encode user input in log lines (log injection); never log tokens, passwords, session IDs, or sensitive personal payloads.
- Where the app acts on users' behalf, show them an activity trail of those actions; user visibility is part of detection.

## Concrete parameters (Cheat Sheet Series)

Security headers on every web response (APIs additionally: `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, CSP `frame-ancestors 'none'`):

| Header | Value |
|---|---|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` |
| `Content-Security-Policy` | app-specific; no `unsafe-inline` scripts; `frame-ancestors 'none'` |
| `X-Frame-Options` | `DENY` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `geolocation=(), camera=(), microphone=()` (allow per feature) |
| `Cross-Origin-Opener-Policy` | `same-origin` |
| `X-XSS-Protection` | `0` |
| Remove | `Server`, `X-Powered-By`, version banners |

Reference numbers: argon2id m=19456 KiB t=2 p=1 · bcrypt cost ≥10 · session/JWT ~15 min idle, 4–8 h absolute · session ID ≥64 bits entropy · invite/reset tokens ≥128 bits CSPRNG, single-use, short-lived · password length 8 (with MFA) / 15 (without), max ≥64.

## Verification against this file

Before marking a task complete, in addition to the checklist in SKILL.md (and the `compliance` skill's checklist, if loaded): (1) new endpoints have authorization and role-matrix tests, plus cross-tenant tests if multi-tenant; (2) every new input path (endpoint, webhook, sync field, deep link, LLM tool) has strict schema validation; (3) every new error path fails closed; (4) LLM-related changes pass the prompt-injection tests. When a change knowingly deviates from a rule here, record it where the project tracks accepted risks (risk register, ADR, or the PR description if nothing else exists).
