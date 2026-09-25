# Sidra: Almuntahha Islamic Learning Management System

A mobile-first, local-first Flutter app for structured Islamic learning,
with teacher-gated progression and an in-app console for teachers and
administrators.

**Stack:** Flutter · Riverpod · GoRouter · PostgreSQL 17 on Neon (Data API
over HTTPS, Row Level Security) · Clerk · Cloudinary · SQLite (sqflite)

## Docs

| Doc | For |
|---|---|
| [docs/BACKEND.md](docs/BACKEND.md) | database design, security model, Neon/Clerk/Cloudinary setup |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | config, migrations, building named APKs, versioning, signing |
| [docs/ADMIN_GUIDE.md](docs/ADMIN_GUIDE.md) | the Almuntahha team: building courses, reviewing learners |

## Quick start

```sh
cp .env.example .env                  # fill in values
dart run tool/db.dart migrate         # database schema (owner connection)
dart run tool/gen_config.dart dev     # public build config from .env
flutter run --dart-define-from-file=config/dev.json
```

Without a Clerk publishable key the app still shows onboarding and a sign-in
screen that explains what's missing. There is no fake login.

## What's inside

- **Learners:** onboarding, catalogue, free self-enrolment, course outline
  of any book structure, a lesson reader (Quranic Arabic RTL, audio,
  video, images, translations, references, quizzes), teacher-gated
  progress, offline downloads, and background sync.
- **Teachers:** a review queue. Mark a learner and open their next lesson.
- **Admins:** courses, units, books with configurable structures, the
  outline tree, lesson content, media upload, quizzes, publishing, roles
  and access.

## Project layout

```
lib/
  app/            bootstrap, root widget, router + shell
  core/           config, errors, logging, network (PostgresApi), database
                  (SQLite), sync (outbox engine), data providers, theme
  features/       auth · onboarding · home · courses · curriculum · lessons ·
                  progress · assessments · media · downloads · profile · admin
  shared/         models (JSON helpers), widgets
  l10n/           English + Arabic ARB files
db/
  migrations/     numbered SQL migrations (never edit applied ones)
  tests/          SQL security/business tests (run rolled back)
tool/             db.dart · gen_config.dart · build_apk.dart
```

## Checks

```sh
flutter analyze
flutter test
dart run tool/db.dart test
```

## Conventions

- Every commit bumps `pubspec.yaml` version (semver + build number).
- All UI strings go through `AppLocalizations` (English and Arabic), and
  layouts use directional insets.
- Clerk is isolated behind `AuthService`, because its Flutter SDK is a
  community beta.
- Trusted rules (access, grading, unlocking) live in PostgreSQL, never only
  in the app.
