# Running Sidra without its developer

This handbook is for whoever looks after Sidra for Almuntahha. It lists every
outside service, what depends on it, and how to do each routine task. None
of these tasks need the developer's computer.

## 1. Services and accounts

| Service | What Sidra uses it for | Where its settings live | Owner (fill in) |
|---|---|---|---|
| **GitHub** (`xhenovolt/sidra_lms`) | Source code; CI checks every push and builds APKs | Repository → Settings → Secrets | |
| **Neon** (PostgreSQL) | All data: accounts, courses, progress, payments. The database also enforces who may see what | Neon console → project → Roles / Connection details | |
| **Cloudinary** | Stores photos, audio, video and documents | Cloudinary console; the API secret is stored inside the database (`tool/db.dart migrate` syncs it) | |
| **MarzPay** | Mobile-money payments (MTN, Airtel) | MarzPay dashboard → API keys | |
| **Payments server host** (VPS, Fly.io, Railway or Render) | Runs `server/`, which sends payments to MarzPay and confirms them | The host's dashboard (environment variables) | |

Put at least two people on every account, so no account depends on one
person.

## 2. Secrets and where each one goes

| Secret | Used by | Stored in |
|---|---|---|
| `DATABASE_URL` (owner login) | migrations (`tool/db.dart`) | GitHub secret `DATABASE_URL`; a maintainer's local `.env` |
| `APP_DATABASE_URL` (`sidra_app` login) | the app itself. It's public by design and can only do what the database's security rules allow | GitHub secret `APP_DATABASE_URL` |
| `PAYMENTS_DATABASE_URL` (`sidra_payments` login) | the payments server. It can only call `payments_api.*` | the payments host's environment |
| `MARZPAY_API_KEY`, `MARZPAY_API_SECRET` | the payments server | the payments host's environment |
| `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | signing uploads, kept inside the database | a maintainer's `.env` when running `migrate` |
| `CLOUDINARY_CLOUD_NAME` | the app | GitHub secret `CLOUDINARY_CLOUD_NAME` |

**Rotating a secret:** create the new value in the service's dashboard. For
the database logins, run `dart run tool/db.dart app-role` or `payments-role`.
Then update it everywhere the table lists, and revoke the old value. If you
change `APP_DATABASE_URL`, build and publish a new APK, because it is
compiled into the app.

## 3. Everyday administration (inside the app)

Signed in as an administrator: **Admin → Settings**.

- **Organisation:** the name (English and Arabic, shown throughout the app),
  support contacts, currency and payment instructions.
- **Sign-up and security:** whether anyone may create an account, the
  shortest password allowed, and the lock-out after wrong passwords.
- **Teaching defaults:** when a teacher's attention list flags late work or
  a learner falling behind, and the lesson rule and pass mark new courses
  start with.
- **Notifications:** which phone notifications are sent at all. Each course
  can also switch its own off.
- **App updates:** see section 5.
- **Languages and learning tracks:** add, rename or hide them.
- **Export data:** learners, enrolments, payments and progress as CSV
  spreadsheets. Export regularly and keep the files as your own records.

Roles and permissions are set on the admin **Roles** screen.

## 4. Payments server

1. Create its login once: `dart run tool/db.dart payments-role`. This
   writes `PAYMENTS_DATABASE_URL`.
2. Deploy `server/` with its `Dockerfile` to a host that keeps one process
   running (not one that sleeps). Set `PAYMENTS_DATABASE_URL` (Neon's
   **direct** host, not `-pooler`), `MARZPAY_API_KEY` and
   `MARZPAY_API_SECRET`. For faster confirmation, also set `PUBLIC_URL`.
3. Open `https://<host>/health`. It should show recent queue and reconcile
   runs. Admin → Settings → Payments (MarzPay) → Test integration checks it
   from the app.
4. Run **one** instance only.

While the server is down, learners' payments wait as "In progress" and go
out as soon as it is back. No payment is lost or sent twice.

## 5. Releasing a new version

1. Merge the changes into `main`. **GitHub Actions → CI** must be green.
2. If the release has database changes: **Actions → CI → Run workflow**
   with *Apply database migrations* ticked. This runs the database tests
   first and only then migrates.
3. **Actions → CI → Run workflow** with *Build an APK* (channel `prod`).
   Download `sidra-apk` from the run and publish it where phones can fetch
   it, for example as a GitHub Release or on a shared drive with a direct
   link.
4. In the app, go to **Admin → Settings → App updates** and fill in:
   - *Newest version* and *Newest build number*: the `version:` line of
     `pubspec.yaml` (for `2.27.0+46`, that's `2.27.0` and `46`);
   - *Download link*: the https link from step 3.

   Every phone on an older build then shows an "Update" banner.
5. When old versions must stop (for example, after a breaking database
   change), set *Oldest build still allowed*. Phones below it can't
   continue until they update.

## 6. When something goes wrong

| Symptom | Check |
|---|---|
| Nobody can sign in | Neon status; is the project suspended or over its limits? |
| Uploads fail | Cloudinary quota; run `dart run tool/db.dart migrate` to re-sync the Cloudinary keys |
| Payments stuck "In progress" | The payments server's `/health`; the MarzPay dashboard |
| A phone shows old data | It's offline. Sidra shows the saved copy and refreshes on reconnect |

More detail: `docs/DEPLOYMENT.md` (builds, database, signing),
`docs/BACKEND.md` (the database design), `server/README.md` (payments).
