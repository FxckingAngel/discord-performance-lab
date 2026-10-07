import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9224);
const settleMs = Math.max(1000, Math.min(30000, Number(process.argv[3] ?? 5000)));
const outputPath = process.argv[4];
if (!outputPath) throw new Error('Output path is required.');

const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

async function openChannel(url) {
  const socket = await new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
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
  return {
    socket,
    command(method, params = {}) {
      return new Promise((resolve, reject) => {
        const id = nextId++;
        pending.set(id, { resolve, reject });
        socket.send(JSON.stringify({ id, method, params }));
      });
    },
  };
}

const channel = await openChannel(target.webSocketDebuggerUrl);
const command = channel.command;
const optional = async (method, params = {}) => {
  try { return { available: true, result: await command(method, params) }; }
  catch (error) { return { available: false, error: String(error.message ?? error) }; }
};

function metricsMap(metrics) {
  return Object.fromEntries((metrics ?? []).map((metric) => [metric.name, metric.value]));
}

async function snapshot(label) {
  const heap = await optional('Runtime.getHeapUsage');
  const dom = await optional('Memory.getDOMCounters');
  const performance = await optional('Performance.getMetrics');
  const aggregate = await optional('Runtime.evaluate', {
    expression: `(() => ({
      nodeCount: document.getElementsByTagName('*').length,
      frameCount: window.top === window ? window.frames.length + 1 : null,
      imageCount: document.images.length,
      videoCount: document.getElementsByTagName('video').length,
      canvasCount: document.getElementsByTagName('canvas').length
    }))()`,
    returnByValue: true,
  });
  return {
    label,
    heapUsage: heap.available ? heap.result : null,
    domCounters: dom.available ? dom.result : null,
    performanceMetrics: performance.available ? metricsMap(performance.result.metrics) : null,
    documentAggregates: aggregate.result?.result?.value ?? null,
  };
}

await command('Runtime.enable');
await command('Performance.enable');
await command('Page.enable');
const originalUrl = String(target.url ?? '');
const states = [];
states.push(await snapshot('discord-loaded-before-transition'));
await command('Page.navigate', { url: 'about:blank' });
await new Promise((resolve) => setTimeout(resolve, settleMs));
states.push(await snapshot('blank-same-renderer-after-navigation'));
if (originalUrl) {
  await command('Page.navigate', { url: originalUrl });
  await new Promise((resolve) => setTimeout(resolve, settleMs));
  states.push(await snapshot('discord-restored-after-navigation'));
}
channel.socket.close();

await fs.writeFile(outputPath, JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  targetType: target.type,
  policy: 'Aggregate-only same-renderer navigation probe. The original URL is used locally for restoration and is never written to the output.',
  settleMs,
  states,
}, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, stateCount: states.length }));
