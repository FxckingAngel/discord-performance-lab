import fs from 'node:fs/promises';
import path from 'node:path';

const port = Number(process.argv[2]);
const staticUrl = process.argv[3];
const mediaUrl = process.argv[4];
const settleSeconds = Number(process.argv[5] ?? 30);
const outputDirectory = process.argv[6];
if (!Number.isInteger(port) || !staticUrl || !mediaUrl || !outputDirectory) {
  throw new Error('Usage: node Probe-TrackBAllocationFamilyDecay.mjs <port> <static-url> <media-url> <settle-seconds> <output-directory>');
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

const aggregateExpression = `(() => {
  const images = [...document.images];
  const visible = images.filter((image) => {
    const rect = image.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0;
  });
  const videos = [...document.querySelectorAll('video')];
  return {
    viewport: { innerWidth, innerHeight, devicePixelRatio, visualViewportWidth: visualViewport?.width ?? null, visualViewportHeight: visualViewport?.height ?? null },
    dom: { nodes: document.getElementsByTagName('*').length, images: images.length, visibleImages: visible.length, decodedImages: images.filter((image) => image.complete && image.naturalWidth > 0).length, videos: videos.length, playingVideos: videos.filter((video) => !video.paused && video.readyState >= 2).length, canvases: document.querySelectorAll('canvas').length },
    readiness: { documentReady: document.readyState === 'complete', mountPresent: Boolean(document.querySelector('#app-mount')), mountChildren: document.querySelector('#app-mount')?.children.length ?? 0 },
  };
})()`;

async function snapshot(label, delaySeconds) {
  if (delaySeconds > 0) await new Promise((resolve) => setTimeout(resolve, delaySeconds * 1000));
  const [heap, metrics, aggregate, location] = await Promise.all([
    command('Runtime.getHeapUsage'),
    command('Performance.getMetrics').catch(() => ({ metrics: [] })),
    command('Runtime.evaluate', { expression: aggregateExpression, returnByValue: true }),
    command('Runtime.evaluate', { expression: 'location.pathname', returnByValue: true }),
  ]);
  const value = aggregate.result?.value ?? {};
  return {
    label,
    delaySeconds,
    capturedAt: new Date().toISOString(),
    routeClass: String(location.result?.value ?? '').startsWith('/channels/') ? 'discord-channels' : 'other',
    heapUsage: { usedSize: heap.usedSize ?? null, totalSize: heap.totalSize ?? null, embedderHeapUsedSize: heap.embedderHeapUsedSize ?? null, backingStorageSize: heap.backingStorageSize ?? null },
    performanceMetrics: Object.fromEntries((metrics.metrics ?? []).filter((metric) => ['Documents', 'Frames', 'Nodes', 'JSEventListeners', 'LayoutObjects', 'TaskDuration', 'ScriptDuration'].includes(metric.name)).map((metric) => [metric.name, metric.value])),
    aggregate: value,
  };
}

async function waitForReady(label, delaySeconds = 0, settle = true) {
  const deadline = Date.now() + 120000;
  while (Date.now() < deadline) {
    const result = await command('Runtime.evaluate', { expression: `(() => { const mount = document.querySelector('#app-mount'); return { ready: document.readyState === 'complete' && Boolean(mount) && mount.children.length > 0 && document.getElementsByTagName('*').length >= 2000 }; })()`, returnByValue: true });
    if (result.result?.value?.ready) {
      if (settle) await new Promise((resolve) => setTimeout(resolve, settleSeconds * 1000));
      const state = await snapshot(label, delaySeconds);
      await fs.writeFile(path.join(outputDirectory, `checkpoint-${label}.ready`), 'ready\n', 'utf8');
      const proceed = path.join(outputDirectory, `checkpoint-${label}.continue`);
      while (true) {
        try { await fs.access(proceed); break; } catch { await new Promise((resolve) => setTimeout(resolve, 250)); }
      }
      return state;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Application readiness was not reached for ${label}.`);
}

await fs.mkdir(outputDirectory, { recursive: true });
await command('Runtime.enable');
await command('Performance.enable');
const states = [];
await command('Page.navigate', { url: staticUrl });
states.push(await waitForReady('static-before'));
await command('Page.navigate', { url: mediaUrl });
states.push(await waitForReady('media-visible'));
await command('Page.navigate', { url: staticUrl });
states.push(await waitForReady('static-after-30s', 30, false));
states.push(await waitForReady('static-after-120s', 90, false));
states.push(await waitForReady('static-after-300s', 180, false));
await fs.writeFile(path.join(outputDirectory, 'allocation-family-decay-cdp.json'), JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  policy: 'Same-renderer aggregate decay probe. Input URLs are not written. No page text, account data, IDs, tokens, cookies, URLs, or media pixels are written.',
  states,
}, null, 2), 'utf8');
socket.close();
console.log(JSON.stringify({ outputDirectory, stateCount: states.length }));
