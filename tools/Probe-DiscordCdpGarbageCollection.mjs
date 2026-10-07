import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9224);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');

const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', (event) => reject(new Error(`CDP WebSocket error: ${event.message ?? 'unknown'}`)));
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

async function heapUsage() {
  const result = await command('Runtime.getHeapUsage');
  return result;
}

try {
  await command('Runtime.enable');
  const before = await heapUsage();
  await command('HeapProfiler.collectGarbage');
  const after = await heapUsage();
  const output = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    targetType: target.type,
    policy: 'Diagnostic-only local garbage-collection probe. No page text, URLs, cookies, tokens, heap objects, or snapshots are written.',
    before,
    after,
    releasedUsedBytes: Math.max(0, Number(before.usedSize ?? 0) - Number(after.usedSize ?? 0)),
    releasedCapacityBytes: Math.max(0, Number(before.totalSize ?? 0) - Number(after.totalSize ?? 0)),
  };
  await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, releasedUsedBytes: output.releasedUsedBytes }));
} finally {
  socket.close();
}
