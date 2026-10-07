import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
const rawSnapshotPath = process.argv[3];
const summaryPath = process.argv[4];
if (!rawSnapshotPath || !summaryPath) {
  throw new Error('Usage: node Capture-TrackBCdpHeapSnapshot.mjs <port> <private-raw-snapshot> <sanitized-summary>');
}

const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP WebSocket error')));
});

let nextId = 1;
const pending = new Map();
const chunks = [];
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (message.method === 'HeapProfiler.addHeapSnapshotChunk') {
    chunks.push(message.params.chunk);
    return;
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

function summarize(snapshot, rawBytes) {
  const fields = snapshot.snapshot?.meta?.node_fields ?? [];
  const types = snapshot.snapshot?.meta?.node_types?.[0] ?? [];
  const nodes = snapshot.nodes ?? [];
  const width = fields.length;
  const typeIndex = fields.indexOf('type');
  const selfSizeIndex = fields.indexOf('self_size');
  const detachednessIndex = fields.indexOf('detachedness');
  if (width <= 0 || typeIndex < 0 || selfSizeIndex < 0 || nodes.length % width !== 0) {
    throw new Error('Unsupported or malformed heap snapshot schema.');
  }
  const byType = new Map();
  let detachedNodes = 0;
  let totalSelfBytes = 0;
  for (let offset = 0; offset < nodes.length; offset += width) {
    const type = String(types[nodes[offset + typeIndex]] ?? 'unknown');
    const selfSize = Number(nodes[offset + selfSizeIndex] ?? 0);
    const current = byType.get(type) ?? { type, count: 0, selfBytes: 0 };
    current.count += 1;
    current.selfBytes += Number.isFinite(selfSize) ? selfSize : 0;
    byType.set(type, current);
    totalSelfBytes += Number.isFinite(selfSize) ? selfSize : 0;
    if (detachednessIndex >= 0 && Number(nodes[offset + detachednessIndex]) > 0) detachedNodes += 1;
  }
  const typeSummary = [...byType.values()]
    .sort((left, right) => right.selfBytes - left.selfBytes)
    .map((row) => ({
      type: row.type,
      count: row.count,
      selfBytes: row.selfBytes,
      selfMiB: row.selfBytes / (1024 * 1024),
    }));
  return {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    targetType: target.type,
    policy: 'Sanitized aggregate-only summary. Raw snapshot is local/private; names, strings, URLs, page text, cookies, tokens, and heap objects are not emitted.',
    rawSnapshotBytes: rawBytes,
    nodeCount: nodes.length / width,
    totalSelfBytes,
    totalSelfMiB: totalSelfBytes / (1024 * 1024),
    detachedNodeCount: detachedNodes,
    nodeFieldNames: fields,
    byType: typeSummary,
  };
}

try {
  await command('HeapProfiler.enable');
  await command('HeapProfiler.takeHeapSnapshot', {
    captureNumericValue: false,
    exposeInternals: false,
    reportProgress: false,
  });
} finally {
  socket.close();
}

const raw = chunks.join('');
await fs.writeFile(rawSnapshotPath, raw, 'utf8');
const snapshot = JSON.parse(raw);
const summary = summarize(snapshot, Buffer.byteLength(raw, 'utf8'));
await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2), 'utf8');
console.log(JSON.stringify({ summaryPath, rawSnapshotPath, nodeCount: summary.nodeCount, totalSelfMiB: summary.totalSelfMiB }));
