// Generates the RSA signing key for the auth service.
//
//   node scripts/gen-keys.mjs > private-jwk.json
//   npx wrangler secret put JWT_PRIVATE_JWK < private-jwk.json
//   (then delete private-jwk.json)
//
// The public key is served automatically at /.well-known/jwks.json.

const { privateKey } = await crypto.subtle.generateKey(
  {
    name: 'RSASSA-PKCS1-v1_5',
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: 'SHA-256',
  },
  true,
  ['sign', 'verify'],
);
const jwk = await crypto.subtle.exportKey('jwk', privateKey);
process.stdout.write(JSON.stringify(jwk));
