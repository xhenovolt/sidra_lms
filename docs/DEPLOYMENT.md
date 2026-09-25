# Building and releasing Sidra

## 1. Configuration (one place: `.env`)

`.env` holds two kinds of values (see `.env.example`):

| Kind | Keys | Goes into the app? |
|---|---|---|
| Public | `APP_DATABASE_URL` (the `sidra_app` login: public by design), `CLOUDINARY_CLOUD_NAME` | yes, via `config/<channel>.json` |
| Secret | `DATABASE_URL`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | **never** (used by `tool/db.dart`, or stored inside Postgres) |

`dart run tool/gen_config.dart <channel>` copies only the allow-listed
public keys into `config/<channel>.json` and refuses any database login other than
`sidra_app`. Create or rotate it with `dart run tool/db.dart app-role`.

## 2. Database

```sh
dart run tool/db.dart status
dart run tool/db.dart test      # all migrations + db/tests, rolled back
dart run tool/db.dart migrate   # apply + sync Cloudinary settings
```

Never edit an applied migration; add `NNNN_description.sql`. The tool
refuses to run if an applied file's checksum changed.

## 3. Building an APK

```sh
dart run tool/build_apk.dart dev     # → dist/Sidra-<version>-dev.apk
dart run tool/build_apk.dart beta
dart run tool/build_apk.dart prod
```

The name comes from `pubspec.yaml` (`version: X.Y.Z+N`), where `N` becomes
the Android versionCode.

## 4. Versioning rule

Every commit bumps `pubspec.yaml`:

- **major**: breaking change (e.g. a data migration that old apps can't read)
- **minor**: new feature
- **patch**: fix or small change

Always increment the build number `+N` too.

## 5. Release signing (before the Play Store)

Release builds are currently signed with the **debug key**. That's fine for
installing test APKs, but it isn't accepted by Google Play, and updates
signed with a different key won't install over it.

1. Create an upload key once and store it safely, outside the repo:
   ```sh
   keytool -genkey -v -keystore sidra-upload.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias sidra
   ```
2. Create `android/key.properties` (git-ignored):
   ```
   storePassword=…
   keyPassword=…
   keyAlias=sidra
   storeFile=C:/secure/sidra-upload.jks
   ```
3. Reference it from `android/app/build.gradle.kts` `signingConfigs`
   (see flutter.dev/deployment/android#configure-signing-in-gradle).
4. Build an App Bundle for Play: `flutter build appbundle
   --dart-define-from-file=config/prod.json`.

## 6. Checklist per release

- [ ] `flutter analyze` clean, `flutter test` green
- [ ] `dart run tool/db.dart test` green; `migrate` applied to production
- [ ] After `migrate`, run `dart run tool/db.dart test` twice (the first run right
      after DDL can hit stale pooled connections)
- [ ] Version bumped; APK/AAB named correctly
