# Architecture audit: founder independence (v2.26)

Question: can Almuntahha run, change and keep Sidra without the person who
built it? This audit covers every setting that was fixed in code, and every
task that only works from one person's computer.

## Depends on one person or one computer
| # | Finding | Fix |
|---|---|---|
| 1 | The payments server (MarzPay) runs only on the developer's PC. | Deploy it to an always-on host (Dockerfile in `server/`); steps in `docs/OPERATIONS.md`. |
| 2 | APKs are built and database migrations applied from the developer's PC, with secrets in a local `.env`. | GitHub Actions: tests on every push; APK built on demand from repository secrets. |
| 3 | New versions reach phones only when an APK is sent by hand. | Settings → App updates: latest build number and download link; the app tells everyone when a newer version exists. |
| 4 | No record of which accounts exist (Neon, Cloudinary, MarzPay, GitHub) and who owns them. | `docs/OPERATIONS.md`: every service, its purpose, where its settings live, how to rotate each secret. |

## Fixed in code; now changeable in the app (Settings)
| # | Was | Now |
|---|---|---|
| 5 | Anyone could create an account. | Sign-up: open, or closed (accounts created by staff only). |
| 6 | Password rules and lock-out fixed (minimum length, 5 failures → 15 minutes). | Minimum password length; failed sign-ins before lock-out; lock-out minutes. |
| 7 | Languages and learning tracks only in the database seed. | Settings → Languages and Learning tracks: add, rename, switch off. |
| 8 | "Almuntahha" written into about ten app texts. | Texts use the organisation name from Settings. |
| 9 | Teacher alerts fixed: "not submitted" after 2 days, "falling behind" at 3 open portions. | Both are settings. |
| 10 | New courses always started as "teacher unlocks" with a 70% pass mark. | Default lesson rule and pass mark for new courses. |

## Data ownership
| # | Finding | Fix |
|---|---|---|
| 11 | Administrators could not take their data out. | Settings → Export: learners, enrolments, payments and progress as CSV files. |

## Where each fix lives
- 1, 4: `docs/OPERATIONS.md`. 2: `.github/workflows/ci.yml`. 3: `lib/core/settings/update_gate.dart`.
- 5–10: `db/migrations/0033_founder_independent_settings.sql`, `lib/core/settings/public_settings.dart`,
  `lib/features/admin/presentation/settings_screen.dart`, `languages_tracks_screen.dart`.
- 11: `admin_export()` in 0033 and `lib/features/admin/presentation/export_screen.dart`.

## Deliberately not settings
- **App name, logo, colours:** part of the installed app; changing them means a new build (done by CI, item 2).
- **Database and Cloudinary addresses:** infrastructure, kept in repository secrets (item 2).
- **Security checks (who may see what):** enforced by the database, never by a switch in the app.
