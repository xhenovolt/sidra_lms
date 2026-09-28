// Local bridge for networks that block PostgreSQL's port 5432.
//
//   node tool/pg_ws_bridge.mjs            # reads DATABASE_URL's host from .env
//   SIDRA_DB_BRIDGE=127.0.0.1:55432 dart run tool/db.dart status
//
// Each local connection is carried over Neon's WebSocket endpoint
// (wss://<host>/v2, port 443), the same path Neon's serverless driver uses.
// TLS comes from the WebSocket, so the local side runs without SSL. Only
// listens on 127.0.0.1.
import { readFileSync } from 'node:fs';
import net from 'node:net';

const port = Number(process.env.BRIDGE_PORT ?? 55432);
const env = readFileSync('.env', 'utf8');
const url = /^DATABASE_URL=["']?([^"'\r\n]+)/m.exec(env)?.[1];
if (!url) throw new Error('DATABASE_URL missing from .env');
// BRIDGE_DIRECT=1 skips Neon's pooler (long transactions, e.g. `db test`).
const pooled = new URL(url).hostname;
const host = process.env.BRIDGE_DIRECT ? pooled.replace('-pooler.', '.') : pooled;

net
  .createServer((socket) => {
    const ws = new WebSocket(`wss://${host}/v2`);
    ws.binaryType = 'arraybuffer';
    const pending = [];
    socket.on('data', (d) => (ws.readyState === 1 ? ws.send(d) : pending.push(d)));
    ws.onopen = () => pending.splice(0).forEach((d) => ws.send(d));
    ws.onmessage = (e) => socket.write(Buffer.from(e.data));
    ws.onclose = () => socket.end();
    ws.onerror = (e) => {
      console.error('websocket error:', e.message ?? e);
      socket.destroy();
    };
    socket.on('close', () => ws.close());
    socket.on('error', () => ws.close());
  })
  .listen(port, '127.0.0.1', () =>
    console.log(`bridge 127.0.0.1:${port} -> wss://${host}/v2`),
  );
