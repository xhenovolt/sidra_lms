# Sidra backend: PostgreSQL on Neon

The whole backend is PostgreSQL: tables, constraints, triggers, SQL
functions and Row Level Security in `db/migrations/`. There is no API
server, no Data API and no auth service. **The app connects to PostgreSQL
directly.**

```
Flutter app ──postgres wire (TLS)──▶ Neon pooler ──▶ PostgreSQL 17
   logs in as `sidra_app`             each app transaction:
                                        1. app_private.authenticate(token)
                                        2. queries / SQL functions (RLS applies)
dev tools (tool/db.dart) ──owner login from .env──▶ same database
```

## Why a login inside the app is safe here

The app ships with the password of **`sidra_app`**, so treat it as public.
Anyone can extract it from the APK. That's fine, because the role by itself
can only:

- call the sign-in functions `auth_api.app_*` (bcrypt, 5-strike lockout, same
  answer for "no such account" and "wrong password");
- read what an anonymous visitor may read (the published catalogue).

Everything else needs a **session token**. Each app transaction starts with
`app_private.authenticate(token)`, which checks the token (stored hashed,
expires after 1 hour) and binds that person to *this backend and this
transaction* in `app_private.connection_identity`, a table the app role
cannot write. RLS policies and every `SECURITY DEFINER` function read the
identity from there (`app_private.jwt_sub()` → `current_user_id()`).

Things `db/tests/direct_app_test.sql` verifies while acting as `sidra_app`:

- forged `request.jwt.claims` settings are ignored (no impersonation);
- the app role cannot write the identity table, mint tokens, change
  another person's password, or read the credentials/token tables;
- phone numbers and emails are not readable (column privileges);
- a staff password reset or a password change ends existing sessions;
- without a token: no lesson content, no profile, no admin data.

The **owner** connection string (`DATABASE_URL`) and the Cloudinary API
secret never go in the app. `statement_timeout` (20 s) and a connection limit
are set on `sidra_app`.

## Accounts

| Who | Signs in with | Created by |
|---|---|---|
| Learner | phone (+country code), email or username + password | themselves (Create account) or an admin |
| Teacher / admin | same | an admin (People tab) |
| Superadmin | same | `tool/db.dart create-user --role superadmin`, or another superadmin |

- **Superadmins** create, promote, edit, disable or demote administrators.
  Sidra always keeps at least one active superadmin (a database trigger).
- **Admins** manage learners and teachers, courses, books and access.
- **Teachers** review and unlock their own courses' learners and can reset
  those learners' passwords.
- Temporary passwords (from Add person or Reset password) must be changed at
  the next sign-in.

## Layout

| Path | Purpose |
|---|---|
| `0001`–`0006` | foundation, curriculum engine, integrity, API functions, RLS, dashboards |
| `0007` | identity helper runs as owner |
| `0008` | indexes behind per-row RLS checks |
| `0009` | own authentication: credentials, lockout, rotating refresh tokens, staff resets |
| `0010` | superadmins, usernames, people management API, overview |
| `0011` | direct app connection: `sidra_app`, session tokens, transaction-bound identity, private contact details |
| `db/tests/*.sql` | about 330 security and business-rule checks, run rolled back |

## Commands

```sh
dart run tool/db.dart status
dart run tool/db.dart test        # migrations + all db/tests, ONE rolled-back transaction
dart run tool/db.dart migrate     # apply pending migrations, sync Cloudinary settings
dart run tool/db.dart app-role    # (re)create sidra_app's password → .env APP_DATABASE_URL
SIDRA_NEW_PASSWORD=… dart run tool/db.dart create-user --name "Full Name" \
    --phone +256… --email … --username … --role superadmin|admin|teacher|learner
dart run tool/db.dart promote <phone|email|username> admin|teacher|learner
```

`migrate` refuses to run if an applied migration file was edited. Fix
forward with a new migration. Run `test` twice after a migration; the first
run right after DDL can hit a stale pooled connection.

## Security model

| Rule | Enforced by |
|---|---|
| Learners read only published outlines | RLS on courses, units, nodes, lessons |
| Lesson **content** only after unlock | `lesson_content_blocks` RLS → `can_read_lesson()` |
| Teacher-gated progression | only `unlock_lesson()` / `review_lesson()` write `lesson_unlocks` |
| Free courses self-enrol; paid need a grant | `enrol_in_course()` vs `grant_enrolment()` (admin) |
| No self-promotion | role/superadmin columns not grantable; trigger; admin-only functions |
| Contact details private | column privileges; admins use `admin_list_users()` |
| Graded quiz answers never leave the DB | `learner_assessment_options` hides `is_correct` unless practice |
| Server-authoritative scoring | `submit_attempt()` scores; client score stored separately |
| Idempotent offline sync | `sync_operations` keyed by client op id |
| Locked media stays locked | `media_url()` checks access and signs Cloudinary URLs in Postgres |

Errors raised as `SQLSTATE 'PTnnn'` reach the app as typed failures
(401 session, 403 forbidden, 404, 409 conflict, 400 invalid, 503).

### Progress definition

Course progress = completed **live** lessons ÷ **live** lessons, where live
means published all the way up the tree.

### Known limitations

- Cloudinary signed URLs (non-Enterprise) don't expire. They're only issued
  to learners who have unlocked the lesson.
- Mobile networks that block outbound port 5432 can't reach the database.
  The app treats that as offline.
- In-app payments will need a trusted receipt verifier (planned). Until
  then, paid access is granted by admins.
