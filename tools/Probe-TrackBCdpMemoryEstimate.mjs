import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
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

const expression = `(${async () => {
  const memory = globalThis.performance?.measureUserAgentSpecificMemory;
  const result = {
    supported: typeof memory === 'function',
    crossOriginIsolated: globalThis.crossOriginIsolated === true,
  };
  if (!result.supported) return result;
  try {
    const sample = await memory.call(globalThis.performance);
    result.bytes = Number(sample.bytes);
    result.breakdown = Array.isArray(sample.breakdown)
      ? sample.breakdown.map((entry) => ({
          bytes: Number(entry.bytes),
          types: Array.isArray(entry.types) ? entry.types.map((type) => String(type)) : [],
          attribution: Array.isArray(entry.attribution)
            ? entry.attribution.map((item) => ({
                scope: String(item.scope ?? ''),
                originClass: item.url === 'cross-origin-url' ? 'cross-origin' : 'same-origin-or-opaque',
              }))
            : [],
        }))
      : [];
  } catch (error) {
    result.errorName = String(error?.name ?? 'Error');
    result.errorMessage = String(error?.message ?? 'Unknown error');
  }
  return result;
}})()`;

try {
  const evaluated = await command('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  const heap = await command('Runtime.getHeapUsage');
  const result = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    policy: 'Aggregate-only diagnostic. URLs, page text, cookies, tokens, scripts, heap objects, and raw attribution are not written.',
    heapUsage: {
      usedSize: Number(heap.usedSize),
      totalSize: Number(heap.totalSize),
      limit: Number(heap.heapSizeLimit),
    },
    userAgentSpecificMemory: evaluated.result?.result?.value ?? null,
  };
  await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, supported: result.userAgentSpecificMemory?.supported ?? false }));
} finally {
  socket.close();
}
