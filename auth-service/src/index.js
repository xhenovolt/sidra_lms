// Cloudflare Worker entry point.
//
// Secrets (wrangler secret put …):
//   AUTH_DATABASE_URL  connection string for the sidra_auth_service role
//                      (from `dart run tool/db.dart auth-role`)
//   JWT_PRIVATE_JWK    RSA private key as JWK JSON (from scripts/gen-keys.mjs)
// Vars (wrangler.toml):
//   JWT_ISSUER, JWT_AUDIENCE

import { neon } from '@neondatabase/serverless';
import { createApp, JwtKeys } from './app.js';

let cached; // reused across requests in the same isolate

async function appFor(env) {
  if (cached) return cached;
  const sql = neon(env.AUTH_DATABASE_URL);
  const keys = await JwtKeys.fromPrivateJwk(JSON.parse(env.JWT_PRIVATE_JWK));
  cached = createApp({
    call: async (expr, params) => {
      const rows = await sql.query(`select ${expr} as r`, params);
      return rows[0]?.r;
    },
    keys,
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE,
  });
  return cached;
}

export default {
  async fetch(request, env) {
    const app = await appFor(env);
    return app.fetch(request);
  },
};
