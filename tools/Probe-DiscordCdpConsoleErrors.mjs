import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
const durationSeconds = Math.max(1, Math.min(60, Number(process.argv[3] ?? 10)));
const outputPath = process.argv[4];
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
const events = [];
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (message.method === 'Runtime.exceptionThrown') {
    events.push({ kind: 'exception', text: message.params.exceptionDetails?.text ?? 'unknown' });
  } else if (message.method === 'Log.entryAdded') {
    events.push({ kind: 'log', level: message.params.entry?.level ?? 'unknown', text: message.params.entry?.text ?? 'unknown' });
  } else if (message.method === 'Runtime.consoleAPICalled') {
    events.push({ kind: 'console', type: message.params.type ?? 'unknown' });
  }
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
  await command('Runtime.enable');
  await command('Log.enable');
  await command('Page.enable');
  await command('Page.reload', { ignoreCache: false });
  await new Promise((resolve) => setTimeout(resolve, durationSeconds * 1000));
  const aggregate = events.reduce((result, event) => {
    result[event.kind] = (result[event.kind] ?? 0) + 1;
    return result;
  }, {});
  const output = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    targetType: target.type,
    policy: 'Private diagnostic console and exception capture. Raw event text stays local and must not be published because it may contain page or account data.',
    durationSeconds,
    aggregate,
    events,
  };
  await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, aggregate }));
} finally {
  socket.close();
}
