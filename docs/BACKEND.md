# Sidra backend: PostgreSQL on Neon

The whole backend is PostgreSQL: tables, constraints, triggers, SQL
functions and Row Level Security in `db/migrations/`. There is no separate
API server.

```
Flutter app ──HTTPS + Clerk JWT──▶ Neon Data API ──▶ PostgreSQL 17
                                    (validates JWT)    RLS + SQL functions
dev tools (tool/db.dart) ──postgres wire + owner password (.env)──▶ same DB
```

## Why the app does not connect to PostgreSQL directly

A direct connection needs a database password, and anything shipped in an
APK can be extracted in minutes. Whoever holds that password bypasses every
rule: they can unlock their own lessons, grant themselves paid courses and
read every learner's data.

Instead, each learner calls the database with their own short-lived Clerk
token. Postgres sees them as the `authenticated` role, and `auth.user_id()`
(from `pg_session_jwt`) returns their Clerk user id. RLS policies and
`SECURITY DEFINER` functions then decide what that one learner may do.

The owner connection string lives only in `.env` on developer machines and
is used by `tool/db.dart` for migrations and admin bootstrap.

## Layout

| Path | Purpose |
|---|---|
| `db/migrations/0001_foundation.sql` | extensions, `app_private` schema, enums, identity helpers |
| `db/migrations/0002_schema.sql` | tables: people, media, curriculum engine, assessments, gating, progress |
| `db/migrations/0003_integrity_and_access.sql` | integrity triggers, `can_read_lesson`, lesson sequencing |
| `db/migrations/0004_api_functions.sql` | RPC functions: enrol, unlock, review, progress, quizzes, media |
| `db/migrations/0005_rls_and_grants.sql` | RLS policies and Data API grants |
| `db/migrations/0006_dashboards.sql` | `my_courses()`, `teacher_learners()` read models |
| `db/migrations/0007_identity_definer.sql` | identity helper runs as owner (the `authenticated` role cannot read the `auth` schema on Neon) |
| `db/migrations/0008_performance_indexes.sql` | indexes behind every per-row RLS check |
| `db/tests/access_test.sql` | about 50 security and business-rule checks |
| `db/tests/authoring_test.sql` | console permissions: teacher vs editor vs admin, learner uploads |

## Commands

```sh
dart run tool/db.dart status     # applied / pending migrations
dart run tool/db.dart test       # migrations + access tests in ONE rolled-back transaction
dart run tool/db.dart migrate    # apply pending migrations, then sync app_private.settings from .env
dart run tool/db.dart promote <clerk_user_id> admin|teacher|learner
```

`migrate` records applied files in `public.schema_migrations`, keyed by
filename and checksum. It refuses to run if an applied file has changed
since it was applied. Fix forward with a new migration instead.

## Security model

| Rule | Enforced by |
|---|---|
| Learners read only published outlines | RLS on `courses`, `course_units`, `curriculum_nodes`, `lessons` |
| Lesson **content** only after unlock | `lesson_content_blocks` RLS → `app_private.can_read_lesson()` |
| Teacher-gated progression | only `unlock_lesson()` / `review_lesson()` (course staff) write `lesson_unlocks` |
| First lesson available on enrolment | trigger `unlock_first_lesson` |
| Sequential courses auto-advance | `record_progress()` unlocks next on completion |
| Free courses self-enrol; paid needs grant | `enrol_in_course()` vs admin-only `grant_enrolment()` |
| No self-promotion | role column not grantable; `protect_user_role` trigger; `set_user_role()` admin-only |
| Private progress | RLS: own rows, or staff of that course |
| Graded quiz answers never leave the DB | base `assessment_options` is staff-only; `learner_assessment_options` hides `is_correct` unless practice |
| Server-authoritative scoring | `submit_attempt()` scores; client score stored only as `client_score` |
| Idempotent sync | `sync_operations` ledger keyed by client `op_id`; attempts keyed by client UUID |
| Locked media stays locked | `media_url()` checks `can_read_media()` and signs `authenticated` Cloudinary URLs inside Postgres |
| Anonymous requests | `anonymous` role granted nothing |

Errors raised with `SQLSTATE 'PTnnn'` reach the app as HTTP `nnn`
(401, 403, 404, 409, 503).

### Progress definition

Course progress = completed **live** lessons ÷ **live** lessons. A lesson
is live when it, its course, its unit and every ancestor node are
`published`. Draft or archived content never counts.

### Media limitation to know about

Cloudinary signed delivery URLs (non-Enterprise plans) do not expire. The
database only issues one to a learner who has unlocked the lesson, so they
can't be guessed or enumerated. A learner could still share a URL they were
given. Token-based expiring URLs need Cloudinary Enterprise ("authenticated
access with tokens"). `media_url()` is the single place to change if you
upgrade.

## One-time setup

### 1. Neon

1. Neon console → project → **Data API** → enable for database
   `sidra_lms`. This creates the `authenticated` / `anonymous` roles (already
   present on this database).
2. Copy the Data API URL into `.env` as `NEON_DATA_API_URL`
   (`https://….apirest.….neon.tech/sidra_lms/rest/v1`).
3. Under **Authentication provider**, add **Clerk** and paste the JWKS URL
   from step 2 below.

### 2. Clerk

1. Dashboard → **API Keys** → copy the publishable key into `.env` as
   `CLERK_PUBLISHABLE_KEY` (`pk_test_…`).
2. Dashboard → **JWT templates** → **New template** → name it `neon`
   (must match `CLERK_JWT_TEMPLATE`). Claims:
   ```json
   { "aud": "sidra-neon" }
   ```
   `sub` (Clerk user id) is included automatically and is what RLS uses.
   Lifetime: 60 seconds is fine, because the SDK refreshes it.
3. JWKS URL: `https://<your-clerk-frontend-api>/.well-known/jwks.json`
   (Dashboard → API Keys → Advanced). Give it to Neon (step 1.3). If Neon
   asks for an audience, use `sidra-neon`.

### 3. Cloudinary

Nothing is configured in the app beyond the cloud name.
`dart run tool/db.dart migrate` copies `CLOUDINARY_CLOUD_NAME`, `…_API_KEY`
and `…_API_SECRET` from `.env` into `app_private.settings`, which is not
exposed and not readable by `authenticated`. `media_url()` and
`sign_media_upload()` use them there.

### 4. First administrator

After you sign in to the app once (which creates your `users` row):

```sh
dart run tool/db.dart promote user_2abc…   # your Clerk user id
```

From then on, admins manage roles in the app.

## Payments (planned)

`enrol_in_course()` refuses paid courses, and only `grant_enrolment()`
(admin) can grant them. In-app purchases will need a trusted verifier
(Google Play / App Store receipt validation), which cannot run inside
Postgres or the app. The planned addition is a small webhook service that
verifies the receipt and calls `grant_enrolment` with `source = 'payment'`.
Nothing else changes.
