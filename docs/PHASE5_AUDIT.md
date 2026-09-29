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

---

# Phase 5 report (v2.32.0)

## 2. New settings architecture

Admin → Settings is now a **control centre**:

```
Settings
├─ Search (settings, tools and sections: "password", "payment", "notification"…)
├─ Is Sidra healthy right now?  (live cards; tap for detail)
│   Database · Payments server · MarzPay · Storage · Notifications ·
│   Security · Learning · Payments · Application · Diagnostics
└─ Sections (each: status panel · settings with "last changed by … · why" ·
   reason for the change · tools)
    ├─ General        name EN/AR, time zone, contacts, messaging
    ├─ Users & access sign-up, password length, lock-out, sign-in brake,
    │                 "online" window, sign-in history retention
    ├─ Learner policies  reminders, overdue, escalation, grace, weekends,
    │                 inactivity, auto-suspension, pause; Holidays; Late work
    ├─ Teaching       attention thresholds, default rule and pass mark;
    │                 Problem reports; Languages & tracks
    ├─ Notifications  one switch per kind; Send me a test notification
    ├─ Devices & security  counts; Who's online; Security events; Your devices
    ├─ Payments       currency, MarzPay on/off, manual-payment instructions,
    │                 unanswered-payment window; Trace a payment
    ├─ MarzPay        honest status; safety (emergency stop, max test amount,
    │                 disbursement tests); MarzPay test centre; self-checks
    ├─ Storage        Cloudinary status, upload limit
    ├─ Database       connection, applied schema vs expected, backups note
    ├─ Offline & sync this phone's queue; retry; send now
    ├─ Audit          Settings history (who, old → new, when, why); Export
    ├─ Application    this phone's build, newest/minimum builds, builds in use
    └─ Diagnostics    run all checks; history
```

Each setting is defined once (`control/settings_registry.dart`): section,
label, help, type, limits, search words. The database checks every value
again (`set_org_setting`, 0033/0036/0039/0040) and records who changed it,
from what, to what, and why (0039 fixed the audit defect that hid *which*
setting changed).

## 3. Founder independence

| Task | Alone? | How / why not |
|---|---|---|
| System health, app version, schema version | **YES** | Health cards, Database and Application sections |
| Manage users, sessions, devices; revoke | **YES** | People, Who's online, Devices (0035) |
| Authentication policy | **YES** | Users & access |
| Inactivity, overdue, suspension; issues | **YES** | Learner policies, Late work, Problem reports |
| Why was a learner suspended? | **YES** | Late work: reason + policy snapshot; Settings history: who changed the policy and why |
| Teacher problems, unresolved work | **YES** | Health "Learning" card, Problem reports, teacher inbox |
| Payment methods, manual payments | **YES** | Payments section, Finance |
| MarzPay connection and authentication test | **YES** | Test centre: live, VERIFIED 2026-09-29 |
| Collection test (real money) | **YES** (needs a phone) | Test centre: typed confirmation, proven from MarzPay's ledger |
| Disbursement / bank / account-to-account | **PARTIAL** | Mobile-money disbursement is built but blocked by MarzPay's IP whitelist and a 0 UGX wallet. Bank and wallet transfer are offered by MarzPay; their request fields are undocumented, so Sidra doesn't implement them |
| Balance | **PARTIAL** | Wallet balance from the ledger works; the balance endpoint needs the IP whitelist |
| Look up a transaction; "I paid but unpaid" | **YES** | Trace a payment (Sidra side) + Ask MarzPay (lookup test) |
| Callbacks | **PARTIAL** | Receipts are listed; receiving them needs a public address for the server (infrastructure) |
| Reconciliation | **YES** | Test centre: every Sidra payment vs MarzPay's ledger |
| Uploads failing? | **YES** | Diagnostics → Storage (upload + download round trip); upload limit; Sync section |
| Notifications failing? | **YES** | Diagnostics → Notifications (test notification); phones blocking notifications counted |
| Suspicious sign-ins | **YES** | Security events; health counts |
| Who changed this setting? | **YES** | Settings history (from 0039 on) |

## 4. MarzPay capability matrix (evidence 2026-09-29)

| Capability | MarzPay offers | Sidra built | Tested | Result |
|---|---|---|---|---|
| Connection | yes | yes | yes | **VERIFIED**: HTTPS 276 ms, account 8bb8…dd82, live environment |
| Authentication | yes | yes | yes | **VERIFIED**: credentials accepted; made-up ones refused (401) |
| Collection, MTN/Airtel | yes | yes | no | **UNPROVEN**: needs a person to enter a PIN (founder, from the test centre) |
| Card collection | yes | no | — | PROVIDER SUPPORTS IT — SIDRA IMPLEMENTATION MISSING |
| Disbursement, MTN/Airtel | yes | yes (test centre) | no | IMPLEMENTED — VERIFICATION BLOCKED (IP whitelist; wallet 0 UGX) |
| Bank transfer | yes (subscribed) | no | — | PROVIDER SUPPORTS IT — SIDRA IMPLEMENTATION MISSING (fields undocumented) |
| Account-to-account (wallet transfer) | yes (subscribed) | no | — | PROVIDER SUPPORTS IT — SIDRA IMPLEMENTATION MISSING |
| Balance | yes | yes | yes | **BLOCKED**: `IP_WHITELIST_REQUIRED`; ledger balance 0 UGX |
| Transaction lookup | yes | yes | yes | **VERIFIED**: found a real transaction and its ledger entries |
| Callback / webhook | yes | yes | yes | **BLOCKED**: server has no public address; 0 webhooks registered at MarzPay |
| Reconciliation | n/a | yes | yes | **VERIFIED**: 1 of 1 payment agrees |
| Refund / reversal | **no** | no | — | UNSUPPORTED BY PROVIDER |

## 5. Payment test results

The results are in the table above. They were run by the real payments
server against the real MarzPay account, and they're stored in
`payment_tests`, where they're visible in the app's test-centre history.
**No money moved.**

## 6. Remaining developer or outside dependencies

| Dependency | Kind |
|---|---|
| Hosting the payments server (it isn't deployed; it ran on the development PC for these tests) | infrastructure |
| Its public address (PUBLIC_URL) for callbacks | infrastructure |
| Whitelisting its IP at MarzPay (balance, account, send-money) | external (MarzPay dashboard, account owner) |
| Money in the MarzPay wallet before disbursement tests | operational (collect first) |
| Rotating MarzPay, Cloudinary and database secrets | security: host dashboards, see docs/OPERATIONS.md |
| Applying database changes | architectural: GitHub Actions → CI → "Apply database migrations" (the founder can press it) |
| Building and publishing an APK | CI → "Build an APK" |
| Bank and wallet transfers | missing implementation; MarzPay must document the request fields |
| Database backups and restores | Neon console (infrastructure) |

## 7. Security findings (new controls)

- **Money tests:** only `payments.test` (super admin) can run them. Each
  needs a typed confirmation. The amount is capped (admins can raise the cap
  to at most 100,000 UGX). There's an emergency stop, disbursement is off by
  default, and nothing is retried. A test interrupted mid-way ends as
  UNKNOWN and is never re-sent. The full phone number lives only in a
  private table and is deleted when the test ends.
- The app login can't use `payments_api` at all (checked by
  control_center_test).
- `roles.manage` (super admin) could grant `payments.test` to others. That
  is intended, and every role change is audited.
- The upload limit is enforced on the phone. A modified app could still
  upload larger files, up to Cloudinary's own limit. This is a cost risk,
  not a data risk.
- The storage diagnostic leaves a tiny file in `diagnostics/` on every run.
- Settings history shows values. No secret is an org setting; secrets live in
  `app_private.settings` and in the server's environment, and they're never
  shown.

## 8. Verdict

**For routine operation, yes.** Configuration, diagnosis, troubleshooting,
tracing a disputed payment, explaining a suspension, testing MarzPay's
connection, and running a real collection test no longer need a developer.

**Not yet for everything.** Mobile-money collection can't show as
*operational* until:
1. the payments server is hosted (with PUBLIC_URL);
2. MarzPay whitelists that server's IP;
3. the founder runs one real 500 UGX collection from the test centre.

Bank and account-to-account transfers stay unavailable until MarzPay
documents them.
