import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9222);
const durationSeconds = Number(process.argv[3] ?? 10);
const outputPath = process.argv[4];
if (!outputPath) throw new Error('Output path is required.');
if (!Number.isInteger(durationSeconds) || durationSeconds < 1 || durationSeconds > 60) {
  throw new Error('Duration must be an integer from 1 to 60 seconds.');
}

const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = list.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP WebSocket error')));
});
let nextId = 1;
const pending = new Map();
let traceComplete;
let resolveTraceComplete;
const traceEvents = [];
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (message.method === 'Tracing.dataCollected') {
    for (const traceEvent of message.params?.value ?? []) {
      if (traceEvents.length < 1000000) traceEvents.push(traceEvent);
    }
    return;
  }
  if (message.method === 'Tracing.tracingComplete') {
    resolveTraceComplete?.(message.params ?? {});
    return;
  }
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

function summarize(events) {
  const categoryCounts = new Map();
  const nameCounts = new Map();
  const durations = new Map();
  const phases = new Map();
  const memoryDumpScalars = new Map();
  let memoryDumpEventCount = 0;

  function addMemoryDumpScalars(value, path = [], depth = 0) {
    if (depth > 8 || value === null || value === undefined) return;
    if (typeof value === 'number' && Number.isFinite(value)) {
      const metricName = String(path.at(-1) ?? '').toLowerCase();
      if (!/(size|bytes|resident|private|committed|allocated|used|count|objects)/.test(metricName)) return;
      const safePath = path
        .map((part) => String(part).replace(/[^a-zA-Z0-9_.-]/g, '_'))
        .join('/');
      if (safePath) {
        const previous = memoryDumpScalars.get(safePath) ?? { count: 0, value: 0 };
        memoryDumpScalars.set(safePath, {
          count: previous.count + 1,
          value: previous.value + value,
        });
      }
      return;
    }
    if (typeof value !== 'object') return;
    for (const [key, child] of Object.entries(value)) {
      addMemoryDumpScalars(child, [...path, key], depth + 1);
    }
  }

  for (const event of events) {
    const category = typeof event.cat === 'string' ? event.cat : 'unknown';
    const name = typeof event.name === 'string' ? event.name : 'unknown';
    categoryCounts.set(category, (categoryCounts.get(category) ?? 0) + 1);
    nameCounts.set(name, (nameCounts.get(name) ?? 0) + 1);
    if (Number.isFinite(event.dur)) durations.set(name, (durations.get(name) ?? 0) + event.dur);
    if (typeof event.ph === 'string') phases.set(event.ph, (phases.get(event.ph) ?? 0) + 1);
    if (name === 'memory_dump' || name === 'periodic_interval') {
      const argumentsObject = event.args;
      if (argumentsObject && typeof argumentsObject === 'object') {
        memoryDumpEventCount++;
        addMemoryDumpScalars(argumentsObject, ['args']);
      }
    }
  }
  const top = (map, limit = 40) => [...map.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([key, count]) => ({ key, count }));
  return {
    receivedEventCount: events.length,
    categoryCounts: top(categoryCounts),
    topEventNames: top(nameCounts),
    eventDurationsMicroseconds: top(durations),
    phaseCounts: top(phases),
    memoryDumpEventCount,
    memoryDumpScalars: [...memoryDumpScalars.entries()]
      .sort((a, b) => b[1].value - a[1].value)
      .slice(0, 100)
      .map(([path, stats]) => ({ path, count: stats.count, value: stats.value })),
    selectedCounts: Object.fromEntries(
      ['RunTask', 'EvaluateScript', 'FunctionCall', 'UpdateLayoutTree', 'Layout', 'Paint', 'CompositeLayers', 'DrawFrame', 'memory_dump', 'periodic_interval']
        .map((name) => [name, nameCounts.get(name) ?? 0]),
    ),
  };
}

const result = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  targetType: target.type,
  durationSeconds,
  policy: 'Aggregate-only CDP trace. Raw trace events, page text, URLs, cookies, tokens, and arguments are discarded.',
};

try {
  await command('Tracing.start', {
    transferMode: 'ReportEvents',
    traceConfig: {
      includedCategories: [
        'toplevel',
        'blink',
        'devtools.timeline',
        'disabled-by-default-devtools.timeline',
        'disabled-by-default-memory-infra',
      ],
      enableSampling: true,
      recordMode: 'recordUntilFull',
      traceBufferSizeInKb: 65536,
    },
  });
  try {
    const memoryDump = await command('Tracing.requestMemoryDump', {
      deterministic: false,
      levelOfDetail: 'detailed',
    });
    result.memoryDumpRequested = memoryDump.success === true;
  } catch (error) {
    result.memoryDumpRequested = false;
    result.memoryDumpError = String(error.message ?? error);
  }
  await new Promise((resolve) => setTimeout(resolve, durationSeconds * 1000));
  traceComplete = new Promise((resolve) => { resolveTraceComplete = resolve; });
  await command('Tracing.end');
  const completion = await Promise.race([
    traceComplete,
    new Promise((_, reject) => setTimeout(() => reject(new Error('Tracing completion timed out.')), 10000)),
  ]);
  result.dataLossOccurred = Boolean(completion?.dataLossOccurred);
  result.summary = summarize(traceEvents);
  const traceDuration = Math.max(1, Number(durationSeconds));
  result.summary.eventRatesPerSecond = Object.fromEntries(
    Object.entries(result.summary.selectedCounts)
      .map(([name, count]) => [name, count / traceDuration]),
  );
} finally {
  socket.close();
}

await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, receivedEventCount: result.summary?.receivedEventCount ?? 0, dataLossOccurred: result.dataLossOccurred ?? null }));
