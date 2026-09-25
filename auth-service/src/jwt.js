// Minimal RS256 JWT signing/verification with WebCrypto (Workers + Node 20+).

const enc = new TextEncoder();

export function b64url(bytes) {
  let s = '';
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  for (let i = 0; i < arr.length; i++) s += String.fromCharCode(arr[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function b64urlDecode(str) {
  const pad = str.length % 4 === 0 ? '' : '='.repeat(4 - (str.length % 4));
  const bin = atob(str.replace(/-/g, '+').replace(/_/g, '/') + pad);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

const ALG = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };

/** Public half of an RSA private JWK (never includes d, p, q…). */
export function publicJwk(privateJwk) {
  const { kty, n, e } = privateJwk;
  if (kty !== 'RSA' || !n || !e) throw new Error('JWT key must be an RSA JWK');
  return { kty, n, e };
}

/** RFC 7638 thumbprint, used as the key id (kid). */
export async function thumbprint(pub) {
  const canonical = JSON.stringify({ e: pub.e, kty: pub.kty, n: pub.n });
  return b64url(await crypto.subtle.digest('SHA-256', enc.encode(canonical)));
}

export class JwtKeys {
  static async fromPrivateJwk(privateJwk) {
    const pub = publicJwk(privateJwk);
    const kid = await thumbprint(pub);
    const signKey = await crypto.subtle.importKey(
      'jwk', { ...privateJwk, alg: 'RS256', ext: true }, ALG, false, ['sign']);
    const verifyKey = await crypto.subtle.importKey(
      'jwk', { ...pub, alg: 'RS256', ext: true }, ALG, false, ['verify']);
    return new JwtKeys(kid, pub, signKey, verifyKey);
  }

  constructor(kid, pub, signKey, verifyKey) {
    this.kid = kid;
    this.pub = pub;
    this.signKey = signKey;
    this.verifyKey = verifyKey;
  }

  jwks() {
    return { keys: [{ ...this.pub, kid: this.kid, alg: 'RS256', use: 'sig' }] };
  }

  async sign(payload) {
    const header = { alg: 'RS256', typ: 'JWT', kid: this.kid };
    const input =
      b64url(enc.encode(JSON.stringify(header))) + '.' +
      b64url(enc.encode(JSON.stringify(payload)));
    const sig = await crypto.subtle.sign(ALG, this.signKey, enc.encode(input));
    return input + '.' + b64url(sig);
  }

  /** Returns the payload if signature, alg, kid, iss, aud and exp check out. */
  async verify(token, { issuer, audience, nowSec }) {
    const parts = (token || '').split('.');
    if (parts.length !== 3) return null;
    let header, payload;
    try {
      header = JSON.parse(new TextDecoder().decode(b64urlDecode(parts[0])));
      payload = JSON.parse(new TextDecoder().decode(b64urlDecode(parts[1])));
    } catch {
      return null;
    }
    if (header.alg !== 'RS256' || header.kid !== this.kid) return null;
    const ok = await crypto.subtle.verify(
      ALG, this.verifyKey, b64urlDecode(parts[2]),
      enc.encode(parts[0] + '.' + parts[1]));
    if (!ok) return null;
    if (payload.iss !== issuer || payload.aud !== audience) return null;
    if (typeof payload.exp !== 'number' || payload.exp <= nowSec) return null;
    return payload;
  }
}
