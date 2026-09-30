// Sidra push sender — a Cloudflare Worker (no dependencies; paste as is).
//
// Delivers Sidra's notifications to phones instantly through Firebase
// Cloud Messaging. The database decides WHAT to send (push_api.claim hands
// out each notification once); this only delivers it.
//
// Woken two ways:
//   POST /ping   by the app right after an action (carries no content, so
//                calling it can only deliver real notifications sooner);
//   cron         every minute, as a safety net.
//
// Secrets (Worker → Settings → Variables and Secrets):
//   FIREBASE_SERVICE_ACCOUNT   the whole Firebase service-account JSON
//   DATABASE_URL               the sidra_push login (tool/db.dart push-role)

let cachedToken = null; // { value, expires } — Google access token
let lastFlush = 0;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === '/health') {
      // Which secrets are present (names only, never values).
      const missing = ['FIREBASE_SERVICE_ACCOUNT', 'DATABASE_URL'].filter((k) => !env[k]);
      return json({ ok: true, configured: missing.length === 0, missing });
    }
    if (url.pathname === '/ping' && (request.method === 'POST' || request.method === 'GET')) {
      // At most one flush a second per Worker instance; the database hands
      // each notification out once, so overlapping flushes are harmless.
      const now = Date.now();
      if (now - lastFlush > 1000) {
        lastFlush = now;
        ctx.waitUntil(flush(env).catch((e) => console.error('flush', e)));
      }
      return json({ accepted: true }, 202);
    }
    return json({ error: 'not found' }, 404);
  },

  async scheduled(_event, env, ctx) {
    ctx.waitUntil(flush(env).catch((e) => console.error('cron flush', e)));
  },
};

/// Sends everything waiting. Returns counts (also used by the local test).
export async function flush(env, { fetchImpl = fetch } = {}) {
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  let sent = 0, failed = 0;
  const dead = [];
  for (let round = 0; round < 5; round++) {
    const rows = await sql(env.DATABASE_URL, 'select j from push_api.claim($1) j', [200], fetchImpl);
    if (rows.length === 0) break;
    const token = await accessToken(sa, fetchImpl);
    const jobs = [];
    for (const r of rows) {
      const n = typeof r.j === 'string' ? JSON.parse(r.j) : r.j;
      for (const t of n.tokens || []) jobs.push([n, t]);
    }
    for (let i = 0; i < jobs.length; i += 25) {
      const results = await Promise.all(
        jobs.slice(i, i + 25).map(([n, t]) => send(sa.project_id, token, n, t, fetchImpl)),
      );
      for (const r of results) {
        if (r.ok) sent++;
        else {
          failed++;
          if (r.dead) dead.push(r.token);
        }
      }
    }
    if (rows.length < 200) break;
  }
  if (dead.length) {
    await sql(env.DATABASE_URL, 'select push_api.drop_tokens($1)', [dead], fetchImpl);
  }
  return { sent, failed, dropped: dead.length };
}

async function send(projectId, token, n, fcmToken, fetchImpl) {
  // Data values must be strings; the app routes a tap with kind + data.
  const data = { kind: String(n.kind || ''), notification_id: String(n.id) };
  for (const [k, v] of Object.entries(n.data || {})) {
    if (v !== null && v !== undefined) data[k] = typeof v === 'string' ? v : JSON.stringify(v);
  }
  const res = await fetchImpl(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title: n.title || 'Sidra', body: n.body || '' },
        data,
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'sidra_learning',
            icon: 'ic_stat_sidra',
            color: '#134E33',
            tag: String(n.id),
          },
        },
      },
    }),
  });
  if (res.ok) return { ok: true };
  const body = await res.json().catch(() => ({}));
  const codes = (body.error?.details || []).map((d) => d.errorCode).filter(Boolean);
  // The phone removed the app or the address was replaced: forget it.
  const dead = res.status === 404 || codes.includes('UNREGISTERED') ||
    (res.status === 400 && codes.includes('INVALID_ARGUMENT'));
  return { ok: false, dead, token: fcmToken, status: res.status };
}

// Google access token for FCM, from the service account (RS256 JWT).
async function accessToken(sa, fetchImpl) {
  if (cachedToken && cachedToken.expires > Date.now() + 60_000) return cachedToken.value;
  const now = Math.floor(Date.now() / 1000);
  const enc = (o) => b64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc({ alg: 'RS256', typ: 'JWT' })}.${enc({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })}`;
  const der = Uint8Array.from(
    atob(sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    'pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned)),
  );
  const res = await fetchImpl('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${unsigned}.${b64url(sig)}`,
  });
  const t = await res.json();
  if (!res.ok) throw new Error(`Google refused the key: ${JSON.stringify(t)}`);
  cachedToken = { value: t.access_token, expires: Date.now() + (t.expires_in || 3600) * 1000 };
  return cachedToken.value;
}

// One statement over Neon's HTTPS SQL endpoint (no driver needed).
async function sql(connectionString, query, params, fetchImpl) {
  const host = new URL(connectionString).hostname;
  const res = await fetchImpl(`https://${host}/sql`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'Neon-Connection-String': connectionString,
      'Neon-Array-Mode': 'false',
    },
    body: JSON.stringify({ query, params }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`database: ${res.status} ${body.message || JSON.stringify(body)}`);
  return body.rows || [];
}

function b64url(bytes) {
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}
