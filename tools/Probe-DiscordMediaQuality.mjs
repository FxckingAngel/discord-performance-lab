import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9222);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
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
const expression = `(() => {
  const bucket = (value) => {
    if (!Number.isFinite(value) || value <= 0) return 'none';
    if (value <= 64) return '0-64';
    if (value <= 128) return '65-128';
    if (value <= 256) return '129-256';
    if (value <= 512) return '257-512';
    if (value <= 1024) return '513-1024';
    if (value <= 2048) return '1025-2048';
    return '2049+';
  };
  const summarize = (items, read) => {
    const values = items.map(read).filter((value) => Number.isFinite(value) && value > 0).sort((a, b) => a - b);
    return { count: items.length, measured: values.length, min: values[0] ?? null, median: values.length ? values[Math.floor(values.length / 2)] : null, max: values.at(-1) ?? null, buckets: Object.fromEntries([...new Set(values.map(bucket))].sort().map((key) => [key, values.filter((value) => bucket(value) === key).length])) };
  };
  const images = [...document.images].map((image) => {
    const rect = image.getBoundingClientRect();
    let sourceHints = { hasWidth: false, hasHeight: false, hasQuality: false, widthBucket: 'none', heightBucket: 'none' };
    try {
      const parsed = new URL(image.currentSrc || image.src, location.href);
      const width = Number(parsed.searchParams.get('width'));
      const height = Number(parsed.searchParams.get('height'));
      sourceHints = { hasWidth: Number.isFinite(width) && width > 0, hasHeight: Number.isFinite(height) && height > 0, hasQuality: parsed.searchParams.has('quality'), widthBucket: bucket(width), heightBucket: bucket(height) };
    } catch {}
    return { naturalWidth: image.naturalWidth, naturalHeight: image.naturalHeight, displayedWidth: rect.width, displayedHeight: rect.height, complete: image.complete, decoded: image.complete && image.naturalWidth > 0, visible: rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0, sourceHints };
  });
  const visibleImages = images.filter((item) => item.visible);
  const videos = [...document.querySelectorAll('video')].map((video) => { const rect = video.getBoundingClientRect(); return { videoWidth: video.videoWidth, videoHeight: video.videoHeight, displayedWidth: rect.width, displayedHeight: rect.height, readyState: video.readyState, paused: video.paused, visible: rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.right > 0 }; });
  return {
    viewport: { innerWidth, innerHeight, outerWidth, outerHeight, devicePixelRatio, visualViewportWidth: visualViewport?.width ?? null, visualViewportHeight: visualViewport?.height ?? null, visualViewportScale: visualViewport?.scale ?? null },
    media: { imageCount: images.length, visibleImageCount: visibleImages.length, completeImageCount: images.filter((item) => item.complete).length, decodedImageCount: images.filter((item) => item.decoded).length, naturalWidth: summarize(images, (item) => item.naturalWidth), naturalHeight: summarize(images, (item) => item.naturalHeight), displayedWidth: summarize(images, (item) => item.displayedWidth), displayedHeight: summarize(images, (item) => item.displayedHeight), visibleNaturalWidth: summarize(visibleImages, (item) => item.naturalWidth), visibleNaturalHeight: summarize(visibleImages, (item) => item.naturalHeight), visibleDisplayedWidth: summarize(visibleImages, (item) => item.displayedWidth), visibleDisplayedHeight: summarize(visibleImages, (item) => item.displayedHeight), requestedSourceHints: { widthHintCount: images.filter((item) => item.sourceHints.hasWidth).length, heightHintCount: images.filter((item) => item.sourceHints.hasHeight).length, qualityHintCount: images.filter((item) => item.sourceHints.hasQuality).length, widthBuckets: Object.fromEntries([...new Set(images.map((item) => item.sourceHints.widthBucket))].sort().map((key) => [key, images.filter((item) => item.sourceHints.widthBucket === key).length])), heightBuckets: Object.fromEntries([...new Set(images.map((item) => item.sourceHints.heightBucket))].sort().map((key) => [key, images.filter((item) => item.sourceHints.heightBucket === key).length])) } },
    video: { count: videos.length, playingCount: videos.filter((item) => !item.paused && item.readyState >= 2).length, decoded: videos.filter((item) => item.videoWidth > 0 && item.videoHeight > 0).length, videoWidth: summarize(videos, (item) => item.videoWidth), videoHeight: summarize(videos, (item) => item.videoHeight), displayedWidth: summarize(videos, (item) => item.displayedWidth), displayedHeight: summarize(videos, (item) => item.displayedHeight) }
  };
})()`;
try {
  let gpuInfo = null;
  try {
    const gpuResult = await command('GPU.getInfo');
    const featureStatus = gpuResult.featureStatus ?? null;
    gpuInfo = featureStatus ? {
      featureStatus: Object.fromEntries(Object.entries(featureStatus).filter(([key]) => ['2d_canvas', 'gpu_compositing', 'rasterization', 'video_decode', 'webgl', 'webgl2'].includes(key)))
    } : null;
  } catch {}
  const result = await command('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: false });
  const value = result.result?.value;
  if (!value) throw new Error('Media quality probe returned no value.');
  await fs.writeFile(outputPath, JSON.stringify({ schemaVersion: 2, capturedAt: new Date().toISOString(), endpoint: `127.0.0.1:${port}`, targetType: target.type, policy: 'Sanitized media-quality probe. Only aggregate dimensions, scale values, GPU feature-status buckets, state counts, and coarse source-parameter buckets are written. No URLs, page text, message data, cookies, tokens, or image pixels are written.', mediaQuality: value, gpu: gpuInfo }, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, targetType: target.type }));
} finally { socket.close(); }
