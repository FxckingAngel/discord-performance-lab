import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');

const base = `http://127.0.0.1:${port}`;
const version = await (await fetch(`${base}/json/version`)).json();
if (!version.webSocketDebuggerUrl) throw new Error('No browser WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(version.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP browser WebSocket error')));
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

try {
  const result = await command('SystemInfo.getProcessInfo');
  const processes = (result.processInfo ?? []).map((process) => ({
    type: process.type ?? null,
    id: process.id ?? null,
    osProcessId: process.osProcessId ?? null,
    cpuTime: process.cpuTime ?? null,
  }));
  const output = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    policy: 'Aggregate-only diagnostic. No command lines, page content, URLs, cookies, tokens, or heap objects are written.',
    processes,
  };
  await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, processCount: processes.length }));
} finally {
  socket.close();
}
