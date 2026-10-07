import fs from 'node:fs/promises';
import path from 'node:path';

const port = Number(process.argv[2]);
const staticUrl = process.argv[3];
const mediaUrl = process.argv[4];
const settleSeconds = Number(process.argv[5] ?? 30);
const outputDirectory = process.argv[6];
const clearCacheAfterMedia = process.argv.includes('--clear-cache-after-media');
if (!Number.isInteger(port) || !staticUrl || !mediaUrl || !outputDirectory) {
  throw new Error('Usage: node Probe-TrackBRouteTransition.mjs <port> <static-url> <media-url> <settle-seconds> <output-directory>');
}
if (!Number.isInteger(settleSeconds) || settleSeconds < 5 || settleSeconds > 600) {
  throw new Error('Settle seconds must be an integer from 5 to 600.');
}

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
const command = (method, params = {}) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({ id, method, params }));
});

function classifyRoute(rawUrl) {
  try {
    const pathName = new URL(String(rawUrl || '')).pathname.toLowerCase();
    if (pathName.startsWith('/channels/')) return 'discord-channels';
    if (pathName === '/settings' || pathName.startsWith('/settings/')) return 'settings';
    if (pathName === '/app' || pathName.startsWith('/app/')) return 'discord-app';
    return 'other';
  } catch {
    return 'unknown';
  }
}

const aggregateExpression = `(() => {
  const bucket = (value) => {
    if (!Number.isFinite(value) || value <= 0) return 'none';
    if (value <= 64) return '0-64';
    if (value <= 256) return '65-256';
    if (value <= 1024) return '257-1024';
    if (value <= 2048) return '1025-2048';
    return '2049+';
  };
  const images = [...document.images];
  const visibleImages = images.filter((image) => {
    const rect = image.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0;
  });
  const naturalPixels = (items) => items.reduce((total, image) => {
    const pixels = Number(image.naturalWidth || 0) * Number(image.naturalHeight || 0);
    return Number.isFinite(pixels) ? total + pixels : total;
  }, 0);
  const imageWidths = images.map((image) => Number(image.naturalWidth || 0)).filter((value) => value > 0);
  const videos = [...document.querySelectorAll('video')];
  return {
    viewport: { innerWidth, innerHeight, devicePixelRatio, visualViewportWidth: visualViewport?.width ?? null, visualViewportHeight: visualViewport?.height ?? null },
    dom: { nodes: document.getElementsByTagName('*').length, images: images.length, visibleImages: visibleImages.length, decodedImages: images.filter((image) => image.complete && image.naturalWidth > 0).length, naturalImagePixels: naturalPixels(images), visibleNaturalImagePixels: naturalPixels(visibleImages), maxNaturalImageWidth: imageWidths.length ? Math.max(...imageWidths) : 0, imageWidthBuckets: Object.fromEntries([...new Set(imageWidths.map(bucket))].sort().map((key) => [key, imageWidths.filter((value) => bucket(value) === key).length])), videos: videos.length, playingVideos: videos.filter((video) => !video.paused && video.readyState >= 2).length, canvases: document.querySelectorAll('canvas').length },
    readiness: { documentReady: document.readyState === 'complete', mountPresent: Boolean(document.querySelector('#app-mount')), mountChildren: document.querySelector('#app-mount')?.children.length ?? 0 },
  };
})()`;

async function snapshot(label) {
  const [heap, metrics, aggregate] = await Promise.all([
    command('Runtime.getHeapUsage'),
    command('Performance.getMetrics').catch(() => ({ metrics: [] })),
    command('Runtime.evaluate', { expression: aggregateExpression, returnByValue: true, awaitPromise: false }),
  ]);
  const value = aggregate.result?.value ?? {};
  const safeUrl = String((await command('Runtime.evaluate', { expression: 'location.href', returnByValue: true })).result?.value ?? '');
  return {
    label,
    capturedAt: new Date().toISOString(),
    routeClass: classifyRoute(safeUrl),
    heapUsage: { usedSize: heap.usedSize ?? null, totalSize: heap.totalSize ?? null, embedderHeapUsedSize: heap.embedderHeapUsedSize ?? null, backingStorageSize: heap.backingStorageSize ?? null },
    performanceMetrics: Object.fromEntries((metrics.metrics ?? []).filter((metric) => ['Documents', 'Frames', 'Nodes', 'JSEventListeners', 'LayoutObjects', 'TaskDuration', 'ScriptDuration'].includes(metric.name)).map((metric) => [metric.name, metric.value])),
    aggregate: value,
  };
}

async function waitForReady(label) {
  const deadline = Date.now() + 120000;
  while (Date.now() < deadline) {
    const result = await command('Runtime.evaluate', { expression: `(() => { const mount = document.querySelector('#app-mount'); return { ready: document.readyState === 'complete' && Boolean(mount) && mount.children.length > 0 && document.getElementsByTagName('*').length >= 2000, route: location.pathname }; })()`, returnByValue: true });
    if (result.result?.value?.ready) {
      await new Promise((resolve) => setTimeout(resolve, settleSeconds * 1000));
      const marker = path.join(outputDirectory, `checkpoint-${label}.ready`);
      await fs.writeFile(marker, 'ready\n', 'utf8');
      const proceed = path.join(outputDirectory, `checkpoint-${label}.continue`);
      while (true) {
        try { await fs.access(proceed); break; } catch { await new Promise((resolve) => setTimeout(resolve, 250)); }
      }
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Application readiness was not reached for ${label}.`);
}

await fs.mkdir(outputDirectory, { recursive: true });
await command('Runtime.enable');
await command('Performance.enable');
if (clearCacheAfterMedia) await command('Network.enable');
const states = [];
for (const [label, url] of [['static-before', staticUrl], ['media-visible', mediaUrl], ['static-after', staticUrl]]) {
  if (label === 'static-after' && clearCacheAfterMedia) {
    await command('Network.clearBrowserCache');
  }
  await command('Page.navigate', { url });
  await waitForReady(label);
  states.push(await snapshot(label));
}
await fs.writeFile(path.join(outputDirectory, 'route-transition-cdp.json'), JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  policy: 'Same-renderer aggregate transition probe. Input URLs are not written. No page text, account data, IDs, tokens, cookies, URLs, or media pixels are written.',
  clearCacheAfterMedia,
  states,
}, null, 2), 'utf8');
socket.close();
console.log(JSON.stringify({ outputDirectory, stateCount: states.length }));
