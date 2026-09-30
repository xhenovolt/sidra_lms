// Runs the push Worker's flush once from this PC, with the secrets from
// .env (PUSH_DATABASE_URL, FIREBASE_SERVICE_ACCOUNT_FILE). Proves delivery
// before (or without) Cloudflare.
//
//   node server/push_worker/run_local.mjs
import { readFileSync } from 'node:fs';
import { flush } from './worker.js';

const env = Object.fromEntries(
  readFileSync(new URL('../../.env', import.meta.url), 'utf8')
    .split(/\r?\n/)
    .filter((l) => /^[A-Z_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1).replace(/^['"]|['"]$/g, '')];
    }),
);
if (!env.PUSH_DATABASE_URL) throw new Error('No PUSH_DATABASE_URL in .env: run `dart run tool/db.dart push-role`');
if (!env.FIREBASE_SERVICE_ACCOUNT_FILE) throw new Error('No FIREBASE_SERVICE_ACCOUNT_FILE in .env');

const result = await flush({
  DATABASE_URL: env.PUSH_DATABASE_URL,
  FIREBASE_SERVICE_ACCOUNT: readFileSync(env.FIREBASE_SERVICE_ACCOUNT_FILE, 'utf8'),
});
console.log('push flush:', result);
