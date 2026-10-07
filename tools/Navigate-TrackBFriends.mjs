import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9230);
const settleMs = Math.max(1000, Math.min(30000, Number(process.argv[3] ?? 5000)));
const outputPath = process.argv[4];
if (!outputPath) throw new Error('Output path is required.');

const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP WebSocket error.')));
});
let nextId = 1;
const pending = new Map();
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (!message.id || !pending.has(message.id)) return;
  const request = pending.get(message.id);
  pending.delete(message.id);
  if (message.error) request.reject(new Error(`${message.error.code}: ${message.error.message}`));
  else request.resolve(message.result ?? {});
});
const command = (method, params = {}) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({ id, method, params }));
});

await command('Page.enable');
await command('Page.navigate', { url: 'https://discord.com/channels/@me' });
await new Promise((resolve) => setTimeout(resolve, settleMs));
const refreshedTargets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const refreshed = refreshedTargets.find((entry) => entry.type === 'page');
let routeClass = 'unknown';
let targetOrigin = 'unknown';
try {
  const parsed = new URL(String(refreshed?.url ?? ''));
  targetOrigin = parsed.origin === 'https://discord.com' ? parsed.origin : 'unknown';
  if (parsed.origin === 'https://discord.com' && parsed.pathname.startsWith('/channels/')) routeClass = 'discord-channels';
  else if (parsed.origin === 'https://discord.com' && (parsed.pathname === '/app' || parsed.pathname.startsWith('/app/'))) routeClass = 'discord-app';
  else if (parsed.pathname === '/login' || parsed.pathname.startsWith('/login/')) routeClass = 'login';
} catch {}
socket.close();

await fs.writeFile(outputPath, JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  policy: 'Sanitized route checkpoint. Only an allowlisted route class and target origin are written; raw URLs, IDs, page text, cookies, and tokens are never written.',
  routeClass,
  targetOrigin,
}, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, routeClass, targetOrigin }));
