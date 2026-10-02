// node --test server/push_worker/worker.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { flush, verifyPayments } from './worker.js';

const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const sa = {
  project_id: 'sidra-test',
  client_email: 'push@sidra-test.iam.gserviceaccount.com',
  private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
};

test('sends each claimed notification to every phone and drops dead ones', async () => {
  const calls = { sql: [], fcm: [] };
  let claims = 0;
  const fakeFetch = async (url, init) => {
    const body = init?.body ? (init.headers['content-type'] === 'application/json' ? JSON.parse(init.body) : init.body) : null;
    if (url.endsWith('/sql')) {
      calls.sql.push(body);
      assert.equal(init.headers['Neon-Connection-String'], 'postgresql://sidra_push:pw@ep-x.neon.tech/sidra_lms');
      if (body.query.includes('claim')) {
        return Response.json({
          rows: claims++ === 0
            ? [{ j: { id: 'n1', kind: 'work_reply', title: 'Page 12', body: 'Your teacher responded',
                      data: { portion_id: 'p1' }, tokens: ['good-token', 'dead-token'] } }]
            : [],
        });
      }
      return Response.json({ rows: [{ drop_tokens: 1 }] });
    }
    if (url === 'https://oauth2.googleapis.com/token') {
      assert.match(String(body), /assertion=[\w-]+\.[\w-]+\.[\w-]+$/, 'a signed JWT');
      return Response.json({ access_token: 'google-token', expires_in: 3600 });
    }
    if (url.startsWith('https://fcm.googleapis.com/v1/projects/sidra-test/messages:send')) {
      calls.fcm.push(body.message);
      assert.equal(init.headers.authorization, 'Bearer google-token');
      return body.message.token === 'good-token'
        ? Response.json({ name: 'projects/sidra-test/messages/1' })
        : Response.json({ error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }, { status: 404 });
    }
    throw new Error('unexpected ' + url);
  };

  const r = await flush(
    { FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa), DATABASE_URL: 'postgresql://sidra_push:pw@ep-x.neon.tech/sidra_lms' },
    { fetchImpl: fakeFetch },
  );
  assert.deepEqual(r, { sent: 1, failed: 1, dropped: 1 });
  // What the phone gets: title/body, and what to open on tap.
  const m = calls.fcm.find((x) => x.token === 'good-token');
  assert.equal(m.notification.title, 'Page 12');
  assert.equal(m.data.kind, 'work_reply');
  assert.equal(m.data.portion_id, 'p1');
  assert.equal(m.android.priority, 'HIGH');
  assert.equal(m.android.notification.icon, 'ic_stat_sidra');
  // The dead address was handed back to the database.
  const drop = calls.sql.find((q) => q.query.includes('drop_tokens'));
  assert.deepEqual(drop.params, [['dead-token']]);
});

test('nothing waiting: nothing sent, no Google call', async () => {
  let google = 0;
  const r = await flush(
    { FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa), DATABASE_URL: 'postgresql://sidra_push:pw@ep-x.neon.tech/db' },
    {
      fetchImpl: async (url) => {
        if (url.endsWith('/sql')) return Response.json({ rows: [] });
        google++;
        throw new Error('should not be called');
      },
    },
  );
  assert.deepEqual(r, { sent: 0, failed: 0, dropped: 0 });
  assert.equal(google, 0);
});

test('payments are verified at MarzPay itself, never guessed', async () => {
  const settled = [];
  const fakeFetch = async (url, init) => {
    if (url.endsWith('/sql')) {
      const q = JSON.parse(init.body);
      assert.equal(init.headers['Neon-Connection-String'], 'postgresql://sidra_payments:pw@ep-x.neon.tech/db');
      if (q.query.includes('to_reconcile')) {
        return Response.json({ rows: [
          { id: 'p1', provider_uuid: 'uuid-ok', reference: 'ref-1' },
          { id: 'p2', provider_uuid: 'uuid-down', reference: 'ref-2' },
        ] });
      }
      settled.push(q.params);
      return Response.json({ rows: [{ outcome: 'verified' }] });
    }
    assert.equal(init.headers.authorization, 'Basic marz-key');
    if (url.endsWith('/collect-money/uuid-ok')) {
      return Response.json({ data: { transaction: { uuid: 'uuid-ok', status: 'successful', amount: { raw: 100000 },
                                                    provider_reference: 'MTN-9' } } });
    }
    if (url.endsWith('/collect-money/uuid-down')) return Response.json({ message: 'busy' }, { status: 503 });
    if (url.includes('/transactions?reference=ref-1')) {
      return Response.json({ data: { transactions: [
        { reference: 'ref-1', type: 'credit', amount: { raw: 100000 } },
        { reference: 'ref-1', type: 'debit', amount: { raw: 5000 } },
      ] } });
    }
    throw new Error('unexpected ' + url);
  };
  const r = await verifyPayments(
    { PAYMENTS_DATABASE_URL: 'postgresql://sidra_payments:pw@ep-x.neon.tech/db', MARZPAY_AUTH_BASIC: 'marz-key' },
    { fetchImpl: fakeFetch },
  );
  assert.deepEqual(r, { checked: 2, settled: 1 });
  assert.equal(settled.length, 1, 'MarzPay did not answer for the second: nothing recorded');
  const [uuid, status, amount, providerRef, , fee] = settled[0];
  assert.deepEqual([uuid, status, amount, providerRef, fee], ['uuid-ok', 'successful', 100000, 'MTN-9', 5000]);
});

test('without the payments login nothing is checked', async () => {
  const r = await verifyPayments({}, { fetchImpl: async () => { throw new Error('no calls'); } });
  assert.equal(r.checked, 0);
});
