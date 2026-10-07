import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
const durationSeconds = Math.max(5, Math.min(600, Number(process.argv[3] ?? 60)));
const intervalSeconds = Math.max(1, Math.min(30, Number(process.argv[4] ?? 5)));
const outputPath = process.argv[5];
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

function metricMap(metrics) {
  return Object.fromEntries((metrics ?? []).map((metric) => [metric.name, Number(metric.value)]));
}

const names = [
  'TaskDuration', 'ScriptDuration', 'LayoutDuration', 'RecalcStyleDuration',
  'TaskOtherDuration', 'ThreadTime', 'ProcessTime', 'LayoutCount',
  'RecalcStyleCount', 'JSHeapUsedSize', 'JSHeapTotalSize', 'Nodes', 'Documents', 'Frames',
];
function selectMetrics(metrics) {
  const selected = metricMap(metrics);
  return Object.fromEntries(names.filter((name) => Number.isFinite(selected[name])).map((name) => [name, selected[name]]));
}
function delta(previous, current) {
  return Object.fromEntries(Object.keys(current).map((name) => [name, current[name] - (previous[name] ?? current[name])]));
}
function quantile(values, probability) {
  const ordered = [...values].sort((a, b) => a - b);
  if (ordered.length === 0) return null;
  const position = (ordered.length - 1) * probability;
  const lower = Math.floor(position);
  const upper = Math.ceil(position);
  return lower === upper ? ordered[lower] : ordered[lower] + ((ordered[upper] - ordered[lower]) * (position - lower));
}

try {
  const timeDomain = await command('Performance.setTimeDomain', { timeDomain: 'threadTicks' }).then(() => 'threadTicks').catch(() => 'timeTicks');
  await command('Performance.enable');
  const startedAt = Date.now();
  let previous = selectMetrics((await command('Performance.getMetrics')).metrics);
  const samples = [];
  while ((Date.now() - startedAt) < durationSeconds * 1000) {
    await new Promise((resolve) => setTimeout(resolve, intervalSeconds * 1000));
    const current = selectMetrics((await command('Performance.getMetrics')).metrics);
    samples.push({
      capturedAt: new Date().toISOString(),
      durationSeconds: intervalSeconds,
      deltas: delta(previous, current),
      current,
    });
    previous = current;
  }
  const result = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    timeDomain,
    targetType: target.type,
    policy: 'Aggregate-only diagnostic. No page text, URLs, cookies, tokens, scripts, or stack traces are written.',
    durationSeconds: (Date.now() - startedAt) / 1000,
    intervalSeconds,
    samples,
    summary: Object.fromEntries(['TaskDuration', 'ScriptDuration', 'LayoutDuration', 'RecalcStyleDuration', 'TaskOtherDuration', 'ThreadTime', 'ProcessTime'].map((name) => {
      const values = samples.map((sample) => sample.deltas[name]).filter(Number.isFinite);
      return [name, { median: quantile(values, 0.5), p95: quantile(values, 0.95), total: values.reduce((sum, value) => sum + value, 0) }];
    })),
  };
  await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, sampleCount: samples.length, timeDomain }));
} finally {
  socket.close();
}
