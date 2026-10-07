import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9234);
const action = String(process.argv[3] ?? 'snapshot');
const outputPath = process.argv[4];
const argument = process.argv[5] ?? '';
if (!outputPath) throw new Error('Output path is required.');
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid CDP port.');
if (!['blank', 'navigate', 'wait-ready', 'snapshot'].includes(action)) throw new Error(`Unsupported action: ${action}`);

const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
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

function command(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

async function optional(method, params = {}) {
  try { return { available: true, result: await command(method, params) }; }
  catch (error) { return { available: false, error: String(error.message ?? error) }; }
}

function metricMap(metrics) {
  return Object.fromEntries((metrics ?? []).map((metric) => [metric.name, metric.value]));
}

function classifyRoute(route) {
  try {
    const path = new URL(String(route || '')).pathname;
    if (path === '/app' || path === '/') return 'discord-app';
    if (path.startsWith('/channels/')) return 'discord-channels';
    if (path.startsWith('/settings')) return 'settings';
    if (path.startsWith('/login')) return 'discord-login';
    return 'discord-other';
  } catch {
    return 'unknown';
  }
}

async function snapshot(label) {
  await command('Runtime.enable');
  await command('Performance.enable');
  const heap = await optional('Runtime.getHeapUsage');
  const dom = await optional('Memory.getDOMCounters');
  const performance = await optional('Performance.getMetrics');
  const aggregate = await optional('Runtime.evaluate', {
    expression: `(() => {
      const images = Array.from(document.images);
      const videos = Array.from(document.getElementsByTagName('video'));
      const canvases = Array.from(document.getElementsByTagName('canvas'));
      const mount = document.querySelector('#app-mount');
      return {
        documentReadyState: document.readyState,
        domNodeCount: document.getElementsByTagName('*').length,
        frameCount: window.top === window ? window.frames.length + 1 : null,
        discordMountPresent: Boolean(mount),
        discordMountChildCount: mount?.childElementCount ?? 0,
        imageElementCount: images.length,
        decodedImageCount: images.filter((image) => image.complete && image.naturalWidth > 0).length,
        visibleImageCount: images.filter((image) => { const rect = image.getBoundingClientRect(); return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0; }).length,
        videoElementCount: videos.length,
        playingVideoCount: videos.filter((video) => !video.paused && !video.ended && video.readyState >= 2).length,
        canvasElementCount: canvases.length,
        canvasPixelCount: canvases.reduce((sum, canvas) => sum + (canvas.width * canvas.height), 0)
      };
    })()`,
    returnByValue: true,
    awaitPromise: false,
  });
  const documentAggregates = aggregate.result?.result?.value ?? null;
  const routeClass = classifyRoute(target.url);
  const mountReady = documentAggregates?.discordMountPresent === true && Number(documentAggregates.discordMountChildCount ?? 0) > 0;
  const routeReady = ['discord-app', 'discord-channels', 'settings'].includes(routeClass);
  const domReady = Number(documentAggregates?.domNodeCount ?? 0) >= 2000;
  return {
    label,
    capturedAt: new Date().toISOString(),
    targetType: target.type,
    routeClass,
    heapUsage: heap.available ? heap.result : null,
    domCounters: dom.available ? dom.result : null,
    performanceMetrics: performance.available ? metricMap(performance.result.metrics) : null,
    documentAggregates,
    applicationReadiness: {
      routeReady,
      documentReady: documentAggregates?.documentReadyState === 'complete',
      mountReady,
      domReady,
      ready: routeReady && documentAggregates?.documentReadyState === 'complete' && mountReady && domReady,
      policy: 'Aggregate-only readiness. No page text, account data, tokens, message data, private URLs, or heap objects are written.'
    },
  };
}

async function sleep(milliseconds) {
  await new Promise((resolve) => setTimeout(resolve, milliseconds));
}

if (action === 'blank') {
  await command('Page.enable');
  await command('Page.navigate', { url: 'about:blank' });
  await sleep(1000);
} else if (action === 'navigate') {
  if (!/^https:\/\/(?:[^/]+\.)?discord\.com(?:\/|$)/i.test(argument)) throw new Error('The canonical route must be an HTTPS Discord URL.');
  await command('Page.enable');
  await command('Page.navigate', { url: argument });
  await sleep(1500);
} else if (action === 'wait-ready') {
  const timeoutSeconds = Math.max(5, Math.min(300, Number(argument || 120)));
  const deadline = Date.now() + timeoutSeconds * 1000;
  let current = await snapshot('readiness-poll');
  while (!current.applicationReadiness.ready && Date.now() < deadline) {
    await sleep(1000);
    current = await snapshot('readiness-poll');
  }
  if (!current.applicationReadiness.ready) throw new Error('The Discord application did not satisfy the readiness predicate before the timeout.');
}

const result = await snapshot(action === 'wait-ready' ? 'application-shell-ready' : action);
socket.close();
await fs.writeFile(outputPath, JSON.stringify({
  schemaVersion: 1,
  action,
  policy: 'Diagnostic-only aggregate CDP checkpoint. The URL is used only for local navigation and is never written.',
  checkpoint: result,
}, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, action, ready: result.applicationReadiness.ready, routeClass: result.routeClass }));
