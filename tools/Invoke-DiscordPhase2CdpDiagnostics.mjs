import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9222);
const durationSeconds = Math.max(1, Math.min(60, Number(process.argv[3] ?? 10)));
const outputPath = process.argv[4];
if (!outputPath) throw new Error('Output path is required.');

const base = `http://127.0.0.1:${port}`;
const list = await (await fetch(`${base}/json/list`)).json();
const target = list.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
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
  const { resolve, reject } = pending.get(message.id);
  pending.delete(message.id);
  if (message.error) reject(new Error(`${message.error.code}: ${message.error.message}`));
  else resolve(message.result ?? {});
});

function command(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

async function optionalCommand(method, params = {}) {
  try {
    return { available: true, result: await command(method, params) };
  } catch (error) {
    return { available: false, error: String(error.message ?? error) };
  }
}

function metricMap(metrics) {
  return Object.fromEntries((metrics ?? []).map((metric) => [metric.name, metric.value]));
}

function summarizeProfile(profile) {
  const nodes = [];
  const walk = (node) => {
    if (!node) return;
    nodes.push(node);
    for (const child of node.children ?? []) walk(child);
  };
  walk(profile?.head);
  return {
    sampleCount: Array.isArray(profile?.samples) ? profile.samples.length : null,
    nodeCount: nodes.length,
    sampledBytes: nodes.reduce((sum, node) => sum + Number(node.total ?? node.selfSize ?? 0), 0),
    samplingIntervalBytes: profile?.samplingInterval ?? null,
  };
}

function summarizeNativeMemoryProfile(profile) {
  const samples = Array.isArray(profile?.samples) ? profile.samples : [];
  const sizes = samples.map((sample) => Number(sample.size ?? 0)).filter(Number.isFinite);
  return {
    sampleCount: samples.length,
    sampledBytes: sizes.reduce((sum, size) => sum + size, 0),
    largestSampleBytes: sizes.length > 0 ? Math.max(...sizes) : 0,
    moduleCount: Array.isArray(profile?.modules) ? profile.modules.length : null,
  };
}

const result = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  targetType: target.type,
  targetCount: list.length,
  policy: 'Aggregate-only diagnostic. No page text, URLs, cookies, tokens, heap objects, or raw profiles are written.',
};

try {
  await command('Runtime.enable');
  await command('Performance.enable');
  result.heapUsage = (await optionalCommand('Runtime.getHeapUsage')).result ?? null;
  const metrics = await optionalCommand('Performance.getMetrics');
  result.performanceMetrics = metrics.available ? metricMap(metrics.result.metrics) : { error: metrics.error };
  const nativeMemory = await optionalCommand('Memory.getAllTimeSamplingProfile');
  result.nativeMemorySampling = nativeMemory.available
    ? summarizeNativeMemoryProfile(nativeMemory.result.profile)
    : { error: nativeMemory.error };
  const browserNativeMemory = await optionalCommand('Memory.getBrowserSamplingProfile');
  result.browserNativeMemorySampling = browserNativeMemory.available
    ? summarizeNativeMemoryProfile(browserNativeMemory.result.profile)
    : { error: browserNativeMemory.error };
  const aggregate = await optionalCommand('Runtime.evaluate', {
    expression: `(() => ({
      domNodeCount: document.getElementsByTagName('*').length,
      frameCount: window.top === window ? window.frames.length + 1 : null,
      imageElementCount: document.images.length,
      videoElementCount: document.getElementsByTagName('video').length,
      canvasElementCount: document.getElementsByTagName('canvas').length
    }))()`,
    returnByValue: true,
    awaitPromise: false,
  });
  result.documentAggregates = aggregate.result?.result?.value ?? { error: aggregate.error };

  const started = await optionalCommand('HeapProfiler.startSampling', { samplingInterval: 32768 });
  if (started.available) {
    await new Promise((resolve) => setTimeout(resolve, durationSeconds * 1000));
    const stopped = await optionalCommand('HeapProfiler.stopSampling');
    result.heapSampling = stopped.available ? summarizeProfile(stopped.result.profile) : { error: stopped.error };
  } else {
    result.heapSampling = { error: started.error };
  }
} finally {
  socket.close();
}

await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, targetCount: result.targetCount, heapSampling: result.heapSampling }));
