# Sidra — Almuntahha Islamic Learning Management System

Mobile-first, local-first Flutter app for structured Islamic learning.

**Stack:** Flutter · Riverpod · GoRouter · Neon PostgreSQL (Data API over
HTTPS via Dio) · Clerk auth · Cloudinary media · SQLite (sqflite) offline store.

## Running

1. Copy `config/example.json` to `config/dev.json` and fill in the **public**
   values (Neon Data API URL, Clerk publishable key, Cloudinary cloud name).
2. Run:

   ```sh
   flutter run --dart-define-from-file=config/dev.json
   ```

Without a Clerk publishable key the app starts on a "Setup required" screen
listing the missing values. There is no fake/demo login.

## Configuration and secrets

| File | Contains | Shipped in app? |
|---|---|---|
| `config/*.json` | Public build values (`pk_…` key, API URL, cloud name) | Yes — treat as public |
| `.env` | Neon owner connection string, Cloudinary API secret | **Never** — tooling only |

Both are git-ignored (except `config/example.json` and `.env.example`).
Never add `.env` to `flutter: assets:`.

## Project layout

```
lib/
  app/            bootstrap, root widget, router + shell
  core/           config, errors, logging, network, theme, providers
  features/<f>/   data/ (remote, local, repositories) · domain/ · presentation/
  shared/widgets/ reusable UI (state views, brand mark)
  l10n/           ARB files (en, ar) — generated AppLocalizations
```

## Conventions

- **Versioning:** every commit bumps `version:` in `pubspec.yaml` using
  semver (major = breaking, minor = feature, patch = fix) and increments the
  build number.
- **Arabic-ready:** all UI strings go through `AppLocalizations`; use
  `EdgeInsetsDirectional` / `AlignmentDirectional` instead of left/right.
- **Clerk is isolated** behind `AuthService` (`features/auth/domain`) because
  the Flutter SDK is community-maintained beta.

## Checks

```sh
flutter analyze
flutter test
```
