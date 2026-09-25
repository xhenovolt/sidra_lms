# Sidra auth service

A small Cloudflare Worker that turns a verified password into short-lived
JWTs the Neon Data API accepts. It holds **no** passwords or user data. All
credential logic (bcrypt, lockout, refresh-token rotation) runs in PostgreSQL
(`auth_api.*`, migration `0009_own_auth.sql`).

| Endpoint | Purpose |
|---|---|
| `POST /v1/register` | `{identifier, password, display_name}` → session |
| `POST /v1/login` | `{identifier, password}` → session |
| `POST /v1/refresh` | `{refresh_token}` → new session (rotating) |
| `POST /v1/logout` | `{refresh_token}` → 204 |
| `POST /v1/password` | Bearer access token + `{old_password, new_password}` → session |
| `GET /.well-known/jwks.json` | public key for Neon |

`identifier` is a phone number in international format (`+256…`) or an
email address. A session is `{access_token (15 min), refresh_token (60 days),
expires_in, user}`.

## One-time deployment (about 10 minutes)

You need a free Cloudflare account.

```sh
cd auth-service
npm install

# 1. Signing key → Worker secret (then delete the file)
node scripts/gen-keys.mjs > private-jwk.json
npx wrangler login
npx wrangler secret put JWT_PRIVATE_JWK < private-jwk.json
del private-jwk.json            # (rm on macOS/Linux)

# 2. Database login for the service (run from the project root)
cd ..
dart run tool/db.dart auth-role   # prints a connection string: copy it
cd auth-service
npx wrangler secret put AUTH_DATABASE_URL   # paste it when prompted

# 3. Deploy
npx wrangler deploy               # prints https://sidra-auth.<you>.workers.dev
```

Then:

1. Put that URL in `wrangler.toml` as `JWT_ISSUER` and run `npx wrangler
   deploy` again.
2. **Neon console → Data API → Authentication provider → Other/Custom:**
   - JWKS URL: `https://sidra-auth.<you>.workers.dev/.well-known/jwks.json`
   - Audience: `sidra`
3. Add to the project `.env`:
   ```
   AUTH_URL=https://sidra-auth.<you>.workers.dev
   NEON_DATA_API_URL=<from the Neon Data API page>
   ```
   then `dart run tool/build_apk.dart dev`.
4. Create your account in the app, then make yourself admin:
   `dart run tool/db.dart promote +2567XXXXXXXX admin`

## Tests

`npm test` runs every endpoint against the real database inside one
transaction, as the confined `sidra_auth_service` role, and rolls it back.
It reads `DATABASE_URL` from the project `.env`.

## Security notes

- The service's database role can only EXECUTE `auth_api` functions. It
  can't read or change any table directly.
- Wrong password and unknown account return the same `invalid_credentials`.
- 5 failed attempts lock an account for 15 minutes (enforced in Postgres).
- Refresh tokens are stored hashed. Replaying a rotated token revokes that
  whole login (theft detection).
- Access tokens carry only `sub` (user id), `role`, `iss`, `aud`, `iat`, `exp`,
  and no phone or email.
- Rotate the signing key by generating a new one and re-running step 1.
  Existing access tokens stop working within 15 minutes, and apps refresh
  automatically.
- Forgotten passwords: a teacher (for their learners) or an admin sets a
  temporary one in the app, and the learner must change it at sign-in.
