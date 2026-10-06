import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9229);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');

const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP WebSocket error')));
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
function command(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const native = globalThis.DiscordNative;
    const groups = native && typeof native === 'object' ? Object.getOwnPropertyNames(native).sort() : [];
    const hasWindow = typeof native?.window?.minimize === 'function'
      && typeof native?.window?.maximize === 'function'
      && typeof native?.window?.restore === 'function'
      && typeof native?.window?.close === 'function'
      && typeof native?.window?.focus === 'function';
    const hasHardware = typeof native?.hardware?.getDisplayCount === 'function';
    return hasHardware
      ? native.hardware.getDisplayCount().then((displayCount) => ({ groups, hasWindow, hasHardware, displayCount }))
      : { groups, hasWindow, hasHardware, displayCount: null };
  })()`,
  awaitPromise: true,
  returnByValue: true,
});

const value = result.result?.value;
if (!value) throw new Error('Bridge probe returned no value.');
await fs.writeFile(outputPath, JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  policy: 'Local bridge-shape probe. No page text, URL, cookies, tokens, or native object values are written.',
  result: value,
  passed: value.hasWindow && value.hasHardware && Number.isInteger(value.displayCount) && value.displayCount > 0,
}, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, passed: value.hasWindow && value.hasHardware }));
socket.close();
