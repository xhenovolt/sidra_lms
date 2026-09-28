# Phase 4 audit: production readiness at 3 teachers and 50 learners

Date: 2026-09-28. Scope: the whole stack as it stands at v2.26 plus the
v2.27 settings work (migrations 0031–0033). Every statement below was
checked against the code or the live database. Where something was only
read, not run, it says so.

Status words: **VERIFIED** (observed working end to end), **PARTIAL** (some
layers proven), **UNVERIFIED** (implemented, not proven), **FAILED** (a
defect was shown), **MISSING** (not built), **BLOCKED** (needs something we
don't have).

Priorities: **P0** fix before any real learner; **P1** before controlled
production; **P2** before wider rollout; **P3** future scale.

---

## A. Current architecture

```
Phone (Flutter)
 ├─ per-user SQLite: cached courses, progress outbox, queued submissions
 ├─ secure storage: refresh token (60 days), notification token
 ├─ Postgres wire protocol, port 5432, TLS ──▶ Neon (pooler)
 │     login `sidra_app` (in the APK, public by design)
 │     every transaction starts with app_private.authenticate(access token, 1 h)
 │     → identity bound to that backend + transaction → RLS + definer functions
 ├─ HTTPS ──▶ Cloudinary (uploads signed by the database, downloads signed URLs)
 └─ WorkManager every ~15 min + 1-min timer while open ──▶ poll_notifications(token)

Payments server (server/, Dart) ── login `sidra_payments` (payments_api.* only)
 ├─ LISTEN/NOTIFY + 5 s queue → MarzPay POST /collect-money
 ├─ every 20 s GET /collect-money/{uuid} → payments_api.settle
 └─ optional webhook (body never trusted; status is re-fetched)
```

Live checks (read-only queries on the production database):
- `sidra_app` is not a member of any other role, has **no** privileges on
  `app_private` tables, `statement_timeout=20s`,
  `idle_in_transaction_session_timeout=30s`, connection limit 300.
- Every `public` table has RLS on. Learners can't write directly to any
  learning, finance or teaching table; those writes all go through checked
  functions.

## B. Initial-launch verdict

**Not yet.** The core is sound for 50 learners: identity binding, RLS,
finance rules and idempotent submissions are well built and tested (15
database test suites, about 900 statements). But there are gaps that bite
even at this size:

1. **(P0) The app only works where port 5432 is open.** On 2026-09-28 this
   development PC's network passed TCP to Neon but silently dropped
   PostgreSQL's TLS request. HTTPS to the same host worked. Any learner on a
   network that filters the same way gets "offline" forever. It needs
   testing on MTN and Airtel mobile data and on the Wi-Fi learners actually
   use before launch. The permanent fix is the HTTPS API (P); the stop-gap
   is a WebSocket-over-443 fallback. `tool/pg_ws_bridge.mjs` proves the path.
2. **(P0) Release signing.** APKs are signed with this PC's debug key. If
   that key is lost, installed phones can never be updated. Moving to a
   real key later forces everyone to uninstall and lose unsynced work.
   Switch before the first real install.
3. **(P0) Android backup.** `allowBackup` is on by default. Backups restored
   to another phone copy app data (SharedPreferences, per-user SQLite).
   Encrypted tokens don't survive the move and break sign-in on restore.
   Turn backup off.
4. **(P1) Admins can't see sessions or devices, or revoke one phone.** The
   only lever is disabling the whole account.
5. **(P1) No "I have a problem with this work" path, and no overdue
   handling.**
6. **(P1) A MarzPay payment with no answer for a day is marked *failed*.**
   Money that arrives later is only picked up if a webhook comes in.
7. **(P1) Uploads only run while the app is open,** and one file error can
   leave a submission stuck at "uploading".

Items 1–3 are small changes. 4–7 are this phase's build work (Q).

## C. Security findings

| # | Finding | Evidence | Pri |
|---|---|---|---|
| S0 | **Found and fixed during this audit.** Internal `app_private` functions were executable by the public app login (PostgreSQL's default). They included `create_account` (make any account, even a super admin), `complete_and_unlock` (finish anyone's lesson), `find_user_by_identifier` (phone → account), and `int_setting` (a setting's text inside a cast error). **Fixed by 0034, applied 2026-09-29.** Nothing is executable by default now; only reviewed rule helpers are. `private_functions_test` guards against regressions. Live check: 4 accounts, 3 staff, all known; no sign of abuse. | live `has_function_privilege` queries; 0034 | P0: FIXED |
| S1 | Database login in the APK. Anyone who unpacks the APK can open sessions, call the sign-in functions and run read queries as "anonymous". RLS protects the data, but nothing limits the *rate* of calls. | 0011 design; role settings above | P1 (P0 before public sign-up) |
| S2 | Per-account lock-out exists (5 failures → 15 min, now configurable). Password spraying *across* accounts is unlimited, and each attempt costs the database a bcrypt hash. There's no per-IP limit: the database sees Neon's proxy, not the phone. | `auth_api.login` | P1 |
| S3 | Lock-out can be used to lock a known phone number out on purpose. After it expires, one more failure locks again (no reset), which is progressive in effect. | same | P2 |
| S4 | Revoking one device is impossible. There are only three levers: sign-out on that device, password reset (ends all sessions) and disabling the account. | 0009/0011 | P1 |
| S5 | Notification tokens don't end when the password changes or the session expires. A stolen phone keeps receiving notification *titles* until sign-out or the account is disabled. | 0025 | P1 |
| S6 | Sign-up closed (0033) raises SA403, but `app_register` only turns SA400/SA409 into answers. The app would show a generic error instead of "sign-up is closed". | 0033 vs 0011 | P1 (fixed in 0034) |
| S7 | Any signed-in user can get an upload signature. There's no size or type limit before Cloudinary, so the account's storage can be abused. | `sign_media_upload`, `uploadMedia` | P2 |
| S8 | `media_assets` rows are created by the client with a Cloudinary `public_id`. They're only usable if the id is known; Cloudinary ids are random. | `uploadMedia` | P3 |
| S9 | Local SQLite tampering: the server re-checks every write (progress, submissions, payments). Changing local data only changes what that phone shows. | outbox replays through definer functions | OK |
| S10 | Old app versions: now handled by the minimum-supported-build gate (0033 + UpdateGate). | v2.27 | OK |

## D. Session and device model

| State | Today |
|---|---|
| Account status | `users.is_active`, `removed_at`. VERIFIED (auth tests) |
| Session status | access token (1 h) + refresh family (60 days, rotating, reuse → family revoked). VERIFIED (auth tests) |
| Device status | **MISSING.** Tokens aren't tied to a device. No device list. |
| Connectivity | known only on the phone (connectivity_plus). Not reported. |
| Online (last server contact) | **MISSING.** |
| Activity (last interaction) | **MISSING.** |

Needed (0034 + app): a device record per installation (install id, maker,
model, Android/SDK, app version, locale, time zone, notification and
microphone permission), sign-in and refresh bound to it, heartbeats that
record *last contact* and *last activity* separately, and admin
revoke-one / revoke-all with audit.

## E. Permission matrix

| Permission | Why | Asked when | If denied |
|---|---|---|---|
| INTERNET | everything online | install (normal) | n/a |
| RECORD_AUDIO | recitations, teacher corrections | first time Record is tapped (`record.hasPermission`) | recording refused with a message; file upload still works. Needs verifying on a phone that revoked it later. |
| POST_NOTIFICATIONS (13+) | notification bar | **right after sign-in** (not tied to a need) | in-app notifications list still works. Should be asked at a meaningful moment, and admins should see the state. |
| Camera | photo, video, scan | none: image_picker and the ML Kit scanner use the system camera | n/a |
| Files/media | pick files | none: the system picker | n/a |

Not requested, and not needed: location, contacts, phone state, storage,
background location. Keep it that way.

## F. Submission and issue model

- Portion submissions, lesson work and assignments all queue on the phone
  with a client UUID. The server accepts that id once, so re-sending never
  duplicates. VERIFIED (lesson_work_test, teaching_test; the app queue is
  unit-tested).
- Files already uploaded are remembered, so a retry skips them. VERIFIED
  (code).
- **Issue reporting: MISSING.** There's no way to say "I can't do this work"
  and no teacher resolution or extension.

## G. Inactivity and suspension

- `due_at` exists on portions and assignments. Nothing uses it for warnings
  or overdue.
- Teacher attention flags: "not submitted after N days" and "falling
  behind" (now settings). PARTIAL.
- Account suspension = disabling the account (manual). Enrolment suspension
  happens only after a payment reversal.
- **Configurable warn / overdue / suspend policies: MISSING.** Proposal:
  settings `policy_*` with automatic suspension **off by default**. It skips
  learners with an open issue, an extension, or no delivery of the work.
  The learner is warned first and everything is recorded in the audit log.
  Suspension keeps all data.

## H. Payments and MarzPay

| Stage | Status |
|---|---|
| A. Connectivity | VERIFIED 2026-09-26 (services endpoint) |
| B. Authentication | VERIFIED |
| C. Request creation | VERIFIED: a real collection was created; the PIN prompt reached the phone |
| D. Money actually moved | **BLOCKED / UNPROVEN.** The PIN was never entered. Needs a person with a phone and a small real amount (500 UGX). |
| E. Webhook | UNVERIFIED: needs a public URL (the server isn't deployed) |
| F. Reconciliation | PARTIAL: polling + `settle` tested in SQL; never with a real success |
| Disbursement (send money) | **MISSING.** Not implemented; Sidra has no business need yet. MarzPay's send-money needs an allow-listed IP. |

Integrity already in place (VERIFIED by finance_test):
- one in-flight MarzPay payment per learner and course (unique index): tapping Pay five times gives one payment;
- the same reference is re-sent on retry (MarzPay rejects duplicates);
- only `payments_api.settle` with data re-fetched from MarzPay can verify;
- an amount mismatch goes to *pending* for a person to decide;
- verified, reversed and rejected are final; financial rows can't be deleted;
- waivers are separate from payments;
- manual payments stay *pending* until a finance officer verifies them.

Gaps:
- P1: the 1-day timeout marks a payment *failed* and stops checking it. It
  should stay *processing* (shown as "being confirmed") and be re-checked
  for 7 days.
- P1: a late success after *failed* is accepted only through a webhook
  (correct, because MarzPay is the evidence). Polling should cover it too.
- P2: there's no "status unknown" state visible to finance; it's covered by
  the above.

## I. Authorization matrix (enforced by the database)

L = learner, T = teacher of that course or group, A = admin with the
permission. "fn" = only through a checked function.

| Entity | L read | L write | T read | T write | A read | A write |
|---|---|---|---|---|---|---|
| users | self + names of people in their courses (0027) | own name/photo (fn) | names | – | all (people.view) | fn |
| courses/lessons/curriculum | published + enrolled | – | own courses | own courses | all | all |
| enrolments | own | fn (enrol/pay) | their courses | fn | all | fn |
| progress | own | fn (record_progress) | their courses | fn (unlock) | all | – |
| portions/participation | own | fn (submit) | their groups | fn | all | fn |
| submissions/files | own | fn | their courses/groups | fn (review) | all | – |
| reviews/corrections | own | – | theirs | fn | all | fn |
| resources/media | linked + own | fn (upload) | their courses | fn | all | fn |
| notifications | own | fn (mark read) | own | – | own | – |
| payments/waivers/refunds | own | fn (start/manual) | – | – | finance.view | fn (finance.*) |
| org settings | public keys | – | public keys | – | all | fn (settings.manage) |
| audit log | – | – | – | – | audit.view | – (triggers only) |
| tokens/credentials | – | – | – | – | – | – (app_private, no grants) |

Proven by access_test (110 statements), people_scope_test, roles_test and
direct_app_test: learners can't read other learners' submissions, progress
or payments, can't call staff functions, and can't mark payments.

## J. Offline and sync

- Progress uses an outbox with idempotent op ids. VERIFIED (unit tests +
  sync tests).
- Submissions queue with ids. PARTIAL: they send only while the app runs
  (start-up and on reconnect). If the app is killed mid-upload, it resumes
  on the next start from the last finished file. A missing or unreadable
  file raises a non-network error and leaves the entry at "uploading" with
  no message (P1). Two flushes can run at once and upload a file twice to
  Cloudinary (only the database record is deduplicated) (P2).
- No progress notification; there's a percentage only in the admin upload
  path (P1).

## K. Notifications

Polling, not push: every ~15 min in the background (Android may delay this
further under battery saving), every minute while open. Titles only, via a
notification-only token. Works when the app is killed. Delay: minutes to
hours with Doze. Real-time delivery needs FCM, which needs the server
(P2/P3). Notification kinds exist for portions, reviews, corrections,
submissions and lesson work. They're missing for issues, overdue,
suspension and payment results.

## L. Observability

Present: `audit_log` (courses, enrolments, roles, settings, payments,
users' role and active flag), payment diagnostics.
Missing: sign-in events (success and failure), session and device events,
upload failures, sync failures, app crash reports, server logs beyond
stdout, and alerting. P1 for sign-in, session and device events; P2 for
crash reporting.

## M. Performance

**UNVERIFIED.** No load test has been run. From this PC, every database
round trip crosses to us-east-1 (Neon region). With 50 learners the
connection limit (300) and Neon's pooler are far from limits on paper. A
50-session concurrency script is part of the plan (Q, step 7); results will
be recorded here, not assumed.

## N. Release and Android

| Item | Status |
|---|---|
| Signing | debug key: **P0** |
| Application id | com.almuntahha.sidra_lms: fine |
| allowBackup | default (on): **P0** |
| Exported components | only the launcher activity |
| Deep links | none |
| Secrets in APK | only the `sidra_app` login and the Cloudinary cloud name (both public by design). No owner, API or MarzPay secrets (gen_config allow-list) |
| R8/minify | Flutter defaults (release minified). OK |
| Notification channel | one ("Learning and teaching") |
| Versioning | pubspec, bumped every commit; minimum-build gate (v2.27) |

## O. Migrations 0031–0033

- 0031 (poll payload), 0032 (teacher inbox), 0033 (settings) and 0034
  (private functions) are **applied** (2026-09-29).
- Before applying: all 16 suites passed in a rolled-back run (1,031
  statements). After applying: the suites passed again against the migrated
  database.
- The first attempts dropped the connection mid-run. This network closes
  a WebSocket after about 5–6 minutes, and each statement was a round trip
  to us-east-1. `tool/db.dart test` now sends each file as one block (one
  round trip). The full run takes about 100 s and still names the failing
  statement.
- Idempotency: 0033 inserts settings with `on conflict do nothing` and
  patches functions only when an exact anchor is found (fails loudly
  otherwise). Each migration runs in one transaction, so a failure leaves
  nothing half-applied.
- Old apps: no columns removed. `poll_notifications` gains a field. Old
  apps ignore it.

## P. Future HTTPS API

Move behind HTTPS in this order, keeping the database functions as the
domain layer (the API calls them; nothing is rewritten):
1. sign-in, refresh, sign-up and password reset (rate limits per IP and per identifier, verification codes);
2. uploads (size and type checks, signing);
3. notifications (FCM push);
4. all other calls as a thin pass-through with the session token.

After step 4 the database login leaves the APK. The payments server is
the natural host. Multi-tenancy: **not needed**. Sidra is one organisation
(Almuntahha) serving many learners, and that decision is recorded here.

## Q. Remediation plan

| Step | Work | Pri |
|---|---|---|
| 1 | Apply 0031–0033 | done in this phase |
| 2 | 0034: devices + sessions bound to devices, last contact / last activity, revoke one / all, sign-in event log, global failure throttle, fix S6, notification tokens end with sessions | P1 |
| 3 | App: install id + device info + heartbeats; admin "Devices and sessions" screen with signed in / online / active shown separately | P1 |
| 4 | 0035 + app: work issue reports (categories, text, teacher response, extension) | P1 |
| 5 | 0036 + app: learner policies (warn / overdue / suspend, off by default, safeguards, audit) evaluated by the server | P1 |
| 6 | Payments: keep checking unanswered payments for 7 days; poll late successes | P1 |
| 7 | Upload robustness: errors never leave "uploading", single flush at a time, progress notification | P1 |
| 8 | Release: signing key, allowBackup off | P0 |
| 9 | Network fallback: test on MTN and Airtel data; WebSocket-over-443 fallback in the app if any network blocks 5432 | P0 |
| 10 | Load test: 50 concurrent sessions | P1 |
| 11 | MarzPay real 500 UGX collection with a person present; webhook on a deployed server | P1 (BLOCKED on people and hosting) |
| 12 | HTTPS API, FCM, verification codes | P2/P3 |

## The 17 questions

1. **Safe today for 3 + 50?** Not until P0 items 8–9 are done (signing,
   backup, port-5432 reachability on learners' networks). The data security
   core is ready.
2. **What prevents it?** The P0 list above, plus the P1s for controlled
   production: device and session control, issue reports, payment timeout
   handling, upload robustness.
3. **Vulnerability vs scale limitation.** Vulnerabilities: S2, S4, S5, S6,
   the debug key, backup. Scale limitations: direct database connections,
   polling notifications, no per-IP limits, no FCM. These matter when
   anyone can sign up.
4. **Signed in while offline?** Yes: the refresh token lasts 60 days and
   cached data is shown. The admin view that separates signed in, online,
   active and last seen doesn't exist yet (step 3).
5. **Devices visible to admins?** No (step 3).
6. **Unlimited password attacks?** Not against one account (lock-out). Yes
   across many accounts (step 2 adds a global throttle).
7. **Revoked session keeps working?** A disabled account stops at the next
   call (≤ every call). A password reset ends all sessions. A single device
   can't be revoked yet (step 2).
8. **Reach another learner's data by changing ids or local data?** No.
   Every read and write is checked in the database (access tests).
9. **Report assignment problems?** No (step 4).
10. **Configurable overdue and suspension?** No (step 5).
11. **Interrupted uploads recover?** Partly: resume on next app start, no
    duplicates in the database. Stuck-state and background gaps (step 7).
12. **MarzPay collects money end to end?** Unproven (step 11).
13. **Disbursement?** Not implemented.
14. **Proof that money moved?** The design only verifies from MarzPay's own
    status record (not the webhook body, not the app). That hasn't been
    exercised with a real success yet.
15. **Duplicate payments and callbacks?** Yes: unique in-flight index,
    reference reuse, idempotent settle. VERIFIED in SQL tests.
16. **Offline and concurrent use?** Offline: yes for progress and
    submissions. Concurrency: not measured yet (step 10).
17. **Before open public registration?** The HTTPS API (rate limits, the
    database login out of the APK), verification codes and password reset,
    self-service account deletion, FCM, crash reporting, a privacy policy
    and Play listing, and a paid Neon plan with backups.
