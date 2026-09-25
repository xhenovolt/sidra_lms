// Sidra auth service: turns a verified password into short-lived JWTs.
//
// All credential logic lives in PostgreSQL (auth_api.*). This service only
//   1. forwards identifier/password to the database,
//   2. signs an access token (RS256) for the returned user,
//   3. publishes the public key at /.well-known/jwks.json for Neon.

import { JwtKeys } from './jwt.js';

const ACCESS_TTL_SECONDS = 15 * 60;
const MAX_BODY_BYTES = 8 * 1024;

const STATUS_BY_ERROR = {
  invalid_identifier: 400,
  weak_password: 400,
  name_required: 400,
  same_password: 400,
  invalid_credentials: 401,
  invalid_token: 401,
  disabled: 403,
  identifier_taken: 409,
  locked: 423,
};

class HttpError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

const json = (status, body) =>
  new Response(body === null ? null : JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  });

/**
 * @param {object} deps
 * @param {(sql: string, params: unknown[]) => Promise<unknown>} deps.call
 *        runs `select <sql> as r` and returns r
 * @param {JwtKeys} deps.keys
 * @param {string} deps.issuer
 * @param {string} deps.audience
 * @param {() => number} [deps.now] epoch seconds
 */
export function createApp({ call, keys, issuer, audience, now }) {
  const nowSec = now ?? (() => Math.floor(Date.now() / 1000));

  async function db(sql, params) {
    try {
      const r = await call(sql, params);
      if (r && typeof r === 'object' && typeof r.error === 'string') {
        throw new HttpError(STATUS_BY_ERROR[r.error] ?? 400, r.error);
      }
      return r;
    } catch (e) {
      if (e instanceof HttpError) throw e;
      // Errors raised by auth_api carry SQLSTATE SAnnn and a code message.
      const code = String(e?.code ?? '');
      if (code.startsWith('SA')) {
        const msg = String(e.message ?? '').trim();
        throw new HttpError(STATUS_BY_ERROR[msg] ?? Number(code.slice(2)), msg);
      }
      console.error('database error', code);
      throw new HttpError(503, 'unavailable');
    }
  }

  async function session(user, refreshToken) {
    const iat = nowSec();
    const access = await keys.sign({
      iss: issuer,
      aud: audience,
      sub: user.id,
      role: 'authenticated',
      iat,
      exp: iat + ACCESS_TTL_SECONDS,
    });
    const { refresh_token: _drop, ...profile } = user;
    return {
      access_token: access,
      token_type: 'Bearer',
      expires_in: ACCESS_TTL_SECONDS,
      refresh_token: refreshToken,
      user: profile,
    };
  }

  async function body(request) {
    const len = Number(request.headers.get('content-length') ?? 0);
    if (len > MAX_BODY_BYTES) throw new HttpError(413, 'too_large');
    const text = await request.text();
    if (text.length > MAX_BODY_BYTES) throw new HttpError(413, 'too_large');
    try {
      const b = JSON.parse(text);
      if (b && typeof b === 'object' && !Array.isArray(b)) return b;
    } catch {
      /* fall through */
    }
    throw new HttpError(400, 'invalid_body');
  }

  const str = (v) => (typeof v === 'string' ? v : '');

  const routes = {
    'GET /.well-known/jwks.json': async () =>
      new Response(JSON.stringify(keys.jwks()), {
        headers: {
          'content-type': 'application/json',
          'cache-control': 'public, max-age=300',
        },
      }),

    'GET /health': async () => json(200, { ok: true }),

    'POST /v1/register': async (req) => {
      const b = await body(req);
      const user = await db('auth_api.register($1, $2, $3)', [
        str(b.identifier), str(b.password), str(b.display_name),
      ]);
      const refresh = await db('auth_api.issue_refresh($1)', [user.id]);
      return json(201, await session(user, refresh));
    },

    'POST /v1/login': async (req) => {
      const b = await body(req);
      const user = await db('auth_api.login($1, $2)', [
        str(b.identifier), str(b.password),
      ]);
      const refresh = await db('auth_api.issue_refresh($1)', [user.id]);
      return json(200, await session(user, refresh));
    },

    'POST /v1/refresh': async (req) => {
      const b = await body(req);
      const user = await db('auth_api.rotate_refresh($1)', [str(b.refresh_token)]);
      return json(200, await session(user, user.refresh_token));
    },

    'POST /v1/logout': async (req) => {
      const b = await body(req);
      await db('auth_api.revoke_refresh($1)', [str(b.refresh_token)]);
      return json(204, null);
    },

    // Requires a valid access token; ends all other sessions.
    'POST /v1/password': async (req) => {
      const auth = req.headers.get('authorization') ?? '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
      const claims = await keys.verify(token, {
        issuer, audience, nowSec: nowSec(),
      });
      if (!claims) throw new HttpError(401, 'invalid_token');
      const b = await body(req);
      const user = await db('auth_api.change_password($1, $2, $3)', [
        claims.sub, str(b.old_password), str(b.new_password),
      ]);
      const refresh = await db('auth_api.issue_refresh($1)', [user.id]);
      return json(200, await session(user, refresh));
    },
  };

  return {
    async fetch(request) {
      const url = new URL(request.url);
      const handler = routes[`${request.method} ${url.pathname}`];
      if (!handler) return json(404, { error: 'not_found' });
      try {
        return await handler(request);
      } catch (e) {
        if (e instanceof HttpError) return json(e.status, { error: e.code });
        console.error('unhandled', e?.name);
        return json(500, { error: 'internal' });
      }
    },
  };
}

export { JwtKeys };
