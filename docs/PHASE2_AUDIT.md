# Phase 2A: audit of the existing Sidra codebase (v2.1.0)

Scope: 73 Dart files (~14,400 lines), 11 SQL migrations, 5 SQL test suites
(~330 statements), 14 Flutter test files (83 tests), and a live test against
Neon.

## Decisions that supersede the Phase 2 brief

The brief lists Clerk and the Neon Data API. Both were **deliberately replaced**
at the owner's request:

- **Authentication** is Sidra's own: bcrypt in PostgreSQL, rotating refresh
  tokens, lockout, and staff password resets.
- **Data access** is a direct PostgreSQL connection as the low-privilege
  `sidra_app` role. Every transaction is bound to the signed-in person via
  `app_private.authenticate()`, and RLS applies.

The security intent of the brief holds, since no privileged secret is in the
APK. The one exception is still to come: **MarzPay**. A payment callback needs
a publicly reachable HTTPS endpoint and a merchant secret, so it needs a small
trusted server component (see 2F).

## EXISTING (works today, verified by tests and the live test)

| Area | What exists |
|---|---|
| Curriculum engine | courses → units → admin-defined book structures (levels) → node tree → lessons → typed content blocks; server-computed lesson sequence; structure templates |
| Learner app | onboarding, catalogue, self-enrol (free), outline of any structure, lesson reader (13 block types incl. Quranic RTL), quizzes, downloads, offline-first sync |
| Teacher gating | unlocks/reviews, first-lesson unlock, sequential mode |
| Auth | phone/email/username + password, forced change after reset, lockout |
| People | superadmin/admin/teacher/learner, create/edit/disable, reset password |
| Admin UI | role-based navigation, dashboard (basic counts), course builder, lesson/block editor, quiz editor, books + structures, course people |
| Security | RLS on every table, SECURITY DEFINER API, contact details private, identity bound per transaction, audit-free but tested |

## STRONG (keep as-is)

- Curriculum data model and `lesson_sequence()`: it already handles Yassarna
  (page), Quran (surah → verse) and book → chapter → topic without code
  changes.
- Direct-connection security model and its test suite.
- Offline outbox (idempotent ops, backoff, rejected ops kept).
- Lesson content blocks with forward-compatible `UnknownBlock`.

## WEAK

| Item | Problem |
|---|---|
| Course model | no overview, intended audience, visibility, self-enrol switch, dates, intro media, completion rule; no publish validation |
| Course delete | **hard delete** cascades learner history; should archive |
| Admin dashboard | basic counts only; no finance, attention list, completion |
| Admin navigation | bottom bar, 5 tabs; no room for Academic/People/Enrolment/Finance/Content/Reports/Audit |
| People list | `limit 500`, no server paging, no learner profile view |
| Teacher assignment | course-level only (`course_staff`); no unit/node scope |
| Enrolment | status only; no dates, fee, amounts, access state |
| Course lists | load everything; no search/filter/paging |

## MISSING

- **Permissions**: roles are fixed (`learner/teacher/admin` + superadmin flag)
  and there are 25 `is_admin()` checks in SQL. No Academic Manager, Finance
  Officer or Content Manager.
- **Finance**: fees, charges, payments (bank, mobile money, MarzPay), waivers,
  expenses, refunds, verification, reports.
- **Audit log** of administrative actions.
- **External resources** (YouTube, Telegram, websites) as content, with
  preview.
- **Reports** (academic, finance, people) and export.
- **Learner profile (admin view)**: enrolments, progress, results, payments,
  waivers, activity.
- **Draft → review → published → archived** for lessons; course `archived`
  exists but has no UI.

## HARDCODED

- Navigation decided by the `role` string (`admin`/`teacher`/`learner`).
- Currency: none yet (only `price_currency` column).
- Structure templates list (fine; admins can still define custom levels).

## SECURITY RISKS

- The `sidra_app` login ships in the APK by design. Mitigated: it only works
  as the signed-in person. Keep every new table under RLS, and new functions
  permission-checked.
- **Finance** must never be writable by learners, and **payment verification
  must never be client-trusted**. MarzPay confirmation must come from its
  callback, handled server-side.
- Hard deletes (courses) destroy academic history, and would destroy
  financial history once added.
- Cloudinary signed URLs don't expire (plan limitation, documented).

## ARCHITECTURAL RISKS

- Replacing `is_admin()` with permission checks touches many SQL functions.
  Do it in one migration with tests, keeping `is_admin()` as "has any admin
  permission" so nothing breaks.
- Direct connection: some networks block port 5432 (treated as offline).
- MarzPay forces a small server component (webhook). Keep it minimal: it
  records callbacks into Postgres and nothing else.

## PLAN (incremental; each step tested, committed, versioned)

| Step | Delivers |
|---|---|
| **2B** Admin shell ✅ (v2.2.0) | retractable drawer with grouped sections (Dashboard · Academic · People · Enrolment · Finance · Content · Reports · Audit · Settings), permission-aware; real dashboard metrics (learners, courses, teachers, finance placeholders fed by real tables as they appear) |
| **2D-1** Permissions ✅ (v2.2.0) | roles + permissions tables, `has_permission()`, system roles (Super Admin, Admin, Academic Manager, Finance Officer, Content Manager, Teacher, Learner), roles & permissions screens; SQL checks migrated |
| **Audit** | `audit_log` + triggers on courses, enrolments, roles, payments, waivers, expenses; activity screen |
| **2C** Courses ✅ (v2.3.0) | richer course model, course editor with sections (not a locked wizard), publish validation, archive instead of delete, external resource blocks with YouTube/link preview, preview as learner |
| **2D-2** People ✅ (v2.4.0) | server-paged learner/teacher lists, learner profile (enrolments, progress, results, payments, waivers, activity), unit/node-scoped teacher assignments |
| **2E** Enrolment ✅ (v2.5.0) | enrolment dates, access state, fee snapshot, bulk enrol, self-enrol only when the course allows |
| **2F** Payments ✅ (v2.5.0) | fee/charges ledger, bank and mobile-money submissions (pending → verified/rejected), waivers, refunds/voids; MarzPay boundary (awaiting API docs) |
| **2G** Finance ✅ (v2.5.0) | expected / collected / outstanding / waived / expenses / retained with the formula shown, filters, transactions, reports |
| **2H** Teaching | teacher dashboard scoped to assignments |
| **2I** Hardening | RLS/permission/payment integrity review, indexes, tests |

Accounting definition used unless Almuntahha specifies otherwise:
**Retained = Verified collections − Refunds − Recorded expenses.**
Waivers are never counted as collections.
