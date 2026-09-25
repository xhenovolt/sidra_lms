// End-to-end tests of the auth service against the real database.
// Everything runs in ONE transaction as the confined sidra_auth_service
// role and is rolled back at the end. DATABASE_URL is read from ../.env.

import { after, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import pg from 'pg';

import { createApp, JwtKeys } from '../src/app.js';
import { b64urlDecode } from '../src/jwt.js';

const env = fs.readFileSync(new URL('../../.env', import.meta.url), 'utf8');
const dbUrl = env
  .match(/^DATABASE_URL=['"]?([^'"\n]+)/m)[1]
  .replace('&channel_binding=require', '')
  .replace('sslmode=require', 'sslmode=verify-full');

const client = new pg.Client({ connectionString: dbUrl });
const ISSUER = 'https://auth.test';
const AUDIENCE = 'sidra';
let app;
let keys;
let clock = Math.floor(Date.now() / 1000);

const post = (path, body, headers = {}) =>
  app.fetch(
    new Request(`https://auth.test${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...headers },
      body: typeof body === 'string' ? body : JSON.stringify(body),
    }),
  );
const read = async (res) => ({ status: res.status, body: res.status === 204 ? null : await res.json() });
const claimsOf = (jwt) =>
  JSON.parse(new TextDecoder().decode(b64urlDecode(jwt.split('.')[1])));

before(async () => {
  await client.connect();
  await client.query('begin');
  await client.query('grant sidra_auth_service to current_user');
  await client.query('set local role sidra_auth_service');
  const { privateKey } = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify']);
  keys = await JwtKeys.fromPrivateJwk(await crypto.subtle.exportKey('jwk', privateKey));
  app = createApp({
    call: async (expr, params) => {
      // Savepoint so an expected SQL error doesn't abort the whole test tx.
      await client.query('savepoint s');
      try {
        const r = await client.query(`select ${expr} as r`, params);
        await client.query('release savepoint s');
        return r.rows[0]?.r;
      } catch (e) {
        await client.query('rollback to savepoint s');
        throw e;
      }
    },
    keys, issuer: ISSUER, audience: AUDIENCE, now: () => clock,
  });
});

after(async () => {
  await client.query('rollback');
  await client.end();
});

describe('register and login', () => {
  let session;

  test('register with phone returns a session and a valid JWT', async () => {
    const r = await read(await post('/v1/register', {
      identifier: '+256 711 000 001', password: 'bismillah-123', display_name: 'Hamza',
    }));
    assert.equal(r.status, 201);
    session = r.body;
    assert.equal(session.user.phone, '+256711000001');
    assert.equal(session.user.role, 'learner');
    assert.equal(session.expires_in, 900);
    assert.match(session.refresh_token, /^[0-9a-f]{64}$/);
    const c = claimsOf(session.access_token);
    assert.equal(c.sub, session.user.id);
    assert.equal(c.role, 'authenticated');
    assert.equal(c.aud, AUDIENCE);
    assert.equal(c.iss, ISSUER);
    assert.equal(c.phone, undefined, 'no personal data in the token');
    assert.ok(await keys.verify(session.access_token, { issuer: ISSUER, audience: AUDIENCE, nowSec: clock }));
  });

  test('duplicate and weak registrations are refused', async () => {
    assert.deepEqual(
      await read(await post('/v1/register', { identifier: '+256711000001', password: 'another-pass', display_name: 'X' })),
      { status: 409, body: { error: 'identifier_taken' } });
    assert.deepEqual(
      await read(await post('/v1/register', { identifier: 'x@y.org', password: 'short', display_name: 'X' })),
      { status: 400, body: { error: 'weak_password' } });
  });

  test('login succeeds; wrong password and unknown user look identical', async () => {
    assert.equal((await post('/v1/login', { identifier: '+256711000001', password: 'bismillah-123' })).status, 200);
    const wrong = await read(await post('/v1/login', { identifier: '+256711000001', password: 'nope-nope' }));
    const unknown = await read(await post('/v1/login', { identifier: '+256711999999', password: 'nope-nope' }));
    assert.deepEqual(wrong, { status: 401, body: { error: 'invalid_credentials' } });
    assert.deepEqual(unknown, wrong);
  });

  test('lockout after repeated failures (423), persisted despite errors', async () => {
    for (let i = 0; i < 4; i++) {
      await post('/v1/login', { identifier: '+256711000001', password: 'nope-nope' });
    }
    const r = await read(await post('/v1/login', { identifier: '+256711000001', password: 'bismillah-123' }));
    assert.deepEqual(r, { status: 423, body: { error: 'locked' } });
  });

  test('refresh rotates; replaying an old token kills the family', async () => {
    const r1 = session.refresh_token;
    const next = await read(await post('/v1/refresh', { refresh_token: r1 }));
    assert.equal(next.status, 200);
    assert.notEqual(next.body.refresh_token, r1);
    assert.equal(next.body.user.refresh_token, undefined);
    assert.equal((await post('/v1/refresh', { refresh_token: r1 })).status, 401);
    assert.equal((await post('/v1/refresh', { refresh_token: next.body.refresh_token })).status, 401);
  });

  test('the JWT subject is recognised by Postgres as this user', async () => {
    const claims = claimsOf(session.access_token);
    await client.query('reset role');
    await client.query('set local role authenticated');
    await client.query("select set_config('request.jwt.claims', $1, true)", [JSON.stringify(claims)]);
    const r = await client.query('select public.ensure_profile() as p');
    assert.equal(r.rows[0].p.display_name, 'Hamza');
    await client.query('reset role');
    await client.query('set local role sidra_auth_service');
  });
});

describe('password change and logout', () => {
  let s;

  before(async () => {
    s = (await read(await post('/v1/register', {
      identifier: 'Mariam@Example.org', password: 'first-password', display_name: 'Mariam',
    }))).body;
  });

  test('requires a valid access token', async () => {
    assert.equal((await post('/v1/password', { old_password: 'first-password', new_password: 'second-password' })).status, 401);
    const forged = s.access_token.slice(0, -4) + 'AAAA';
    assert.equal((await post('/v1/password',
      { old_password: 'first-password', new_password: 'second-password' },
      { authorization: `Bearer ${forged}` })).status, 401);
  });

  test('expired access token is rejected', async () => {
    const saved = clock;
    clock += 16 * 60;
    assert.equal((await post('/v1/password',
      { old_password: 'first-password', new_password: 'second-password' },
      { authorization: `Bearer ${s.access_token}` })).status, 401);
    clock = saved;
  });

  test('changes password, ends old sessions, returns a new one', async () => {
    const r = await read(await post('/v1/password',
      { old_password: 'first-password', new_password: 'second-password' },
      { authorization: `Bearer ${s.access_token}` }));
    assert.equal(r.status, 200);
    assert.equal((await post('/v1/refresh', { refresh_token: s.refresh_token })).status, 401);
    assert.equal((await post('/v1/login', { identifier: 'mariam@example.org', password: 'second-password' })).status, 200);
    s = r.body;
  });

  test('logout revokes the refresh token', async () => {
    assert.equal((await post('/v1/logout', { refresh_token: s.refresh_token })).status, 204);
    assert.equal((await post('/v1/refresh', { refresh_token: s.refresh_token })).status, 401);
  });
});

describe('protocol', () => {
  test('JWKS publishes only the public key', async () => {
    const res = await app.fetch(new Request('https://auth.test/.well-known/jwks.json'));
    const { keys: [k] } = await res.json();
    assert.equal(k.kty, 'RSA');
    assert.equal(k.alg, 'RS256');
    assert.equal(k.kid, keys.kid);
    for (const secret of ['d', 'p', 'q', 'dp', 'dq', 'qi']) assert.equal(k[secret], undefined);
  });

  test('bad input is a clean 400/404, never a crash', async () => {
    assert.equal((await post('/v1/login', 'not json')).status, 400);
    assert.equal((await post('/v1/login', '[1,2]')).status, 400);
    assert.equal((await post('/v1/login', { identifier: 5, password: null })).status, 401);
    assert.equal((await post('/v1/nope', {})).status, 404);
    assert.equal((await post('/v1/login', 'x'.repeat(10000))).status, 413);
  });
});
