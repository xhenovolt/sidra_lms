# Phase 5 audit: settings and operational control

Date: 2026-09-29. It covers everything an administrator can or can't
control, as it stood at v2.31.0. Evidence comes from the code, the live
database and live read-only calls to MarzPay.

## 1. What existed

| Area | Existing control | Problem |
|---|---|---|
| Settings screen | One long scrolling form: organisation, payments text, sign-up/security, teaching defaults, learner policies, notifications, app updates, plus links (languages, holidays, export, MarzPay) | No structure, no search, no status. A value can't show who changed it or when |
| Setting changes | `set_org_setting` validates values; an audit trigger writes old and new values to `audit_log` | **Defect:** the trigger records `id`/`user_id` as the entity id, and `org_settings` has neither. So an *updated* setting's history doesn't say **which key** changed. It can't answer "who changed this?". There's also no place for a reason |
| MarzPay | A switch (`marzpay_enabled`) plus "Test integration": server-side checks (configuration, reachability, credentials, bad credentials refused, an invalid 1 UGX collection refused, timeout, duplicate crediting, webhook address, reconciliation, balance) | **Shallow.** None of it moves money or follows a real transaction. "ON" says nothing about whether money was ever collected. No disbursement, balance, lookup or webhook view, and no history |
| Payment tracing | Finance screen lists payments | No way to follow one payment from learner → request → MarzPay → webhook → record without reading the database |
| Suspension explanation | `learner_policy_events` stores the reason and a policy snapshot | Visible in Late work; the setting changes behind it can't be traced (see the audit defect above) |
| Devices and security | Presence, devices, revoke, sign-in history (v2.28) | No overview of failed sign-ins, locks or suspicious sessions |
| Storage | Cloudinary keys synced by `tool/db.dart migrate` | No status, no test upload, no size limit setting |
| Database | — | Nobody can see the schema version or whether the app and database match without developer tools |
| Diagnostics | MarzPay only | No database, storage, notification, sync or device tests |
| App version | Latest/minimum build settings (v2.27) | — |

## 2. Hard-coded or developer-only

| Item | Where | Should an admin control it? |
|---|---|---|
| MarzPay API key and secret | payments server environment | Status only. The secret must never pass through the app or database (it's a server credential). **Architectural:** rotating it needs the server host's dashboard |
| MarzPay IP whitelist | MarzPay dashboard | External; Sidra can only detect and explain it |
| Upload size limit | none (Cloudinary's plan limit applies) | Yes: setting added |
| Payment test limits and emergency stop | none | Yes: settings added |
| Webhook URL | server `PUBLIC_URL` env | Status only (infrastructure) |
| Session lengths (1 h access, 60 days refresh) | SQL | Keep internal. Changing them affects everyone's sign-in security, and the device controls cover the operational need |
| Migrations | `tool/db.dart` / CI | Status visible; applying stays with CI (infrastructure) |

## 3. MarzPay capabilities: live evidence (2026-09-29, read-only)

| Endpoint | Result |
|---|---|
| `GET /collect-money/services` | 200: MTN, Airtel, Card collection; account `8bb89e03…` |
| `GET /send-money/services` | 200: subscribed to **MTN, Airtel, Bank Transfer, Wallet Transfer, Bill Payments** disbursement |
| `GET /services` | 200 |
| `GET /webhooks` | 200: **no webhooks configured** |
| `GET /transactions` | 200: works; shows wallet balance **0 UGX**. The account is **shared with DRAIS** (its SMS top-ups appear too) |
| `GET /balance`, `GET /account`, `POST /send-money` | **403 `IP_WHITELIST_REQUIRED`** from this computer |

Consequences:
- Disbursement exists at MarzPay but needs the server's IP whitelisted
  **and** money in the wallet. The request format for send-money (and
  especially bank transfer fields) isn't in MarzPay's documentation.
- Reconciliation must ignore transactions that aren't Sidra's (DRAIS shares
  the account).
- Refunds, reversals and webhook signatures: not offered by MarzPay.

## 4. Plan (what this phase builds)

1. Every setting defined once (name, section, description, type, limits,
   search words), shown in sections with search, and showing **who last
   changed it and when**.
2. Settings history with reasons; fix the audit defect.
3. System health and a founder dashboard computed by the database.
4. A diagnostics centre (database, sign-in, storage round trip,
   notifications, device, sync, payments server, MarzPay) with history.
5. A MarzPay test centre: a capability matrix from live evidence;
   connection, balance, collection (real money, with confirmations and
   limits), disbursement (behind its own switch), transaction lookup,
   callbacks and reconciliation. Each test gets step-by-step lifecycle,
   durable history and the result model VERIFIED SUCCESS / PROVIDER
   ACCEPTED / FAILED / CANCELLED / PENDING / UNKNOWN / BLOCKED / UNSUPPORTED.
6. Payment trace (learner → request → MarzPay → webhook → record).
7. A security overview (failed sign-ins, locks, many-device accounts).
