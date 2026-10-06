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
  const functionBytes = new Map();
  let selfBytes = 0;
  for (const node of nodes) {
    const bytes = Number(node.selfSize ?? 0);
    if (!Number.isFinite(bytes) || bytes <= 0) continue;
    selfBytes += bytes;
    const frame = node.callFrame ?? {};
    const name = String(frame.functionName || frame.url || '(anonymous)');
    functionBytes.set(name, (functionBytes.get(name) ?? 0) + bytes);
  }
  const topFunctions = [...functionBytes.entries()]
    .sort((left, right) => right[1] - left[1])
    .slice(0, 20)
    .map(([name, bytes]) => ({ name, bytes }));
  return {
    sampleCount: Array.isArray(profile?.samples) ? profile.samples.length : null,
    nodeCount: nodes.length,
    selfBytes,
    sampledBytes: selfBytes,
    samplingIntervalBytes: profile?.samplingInterval ?? null,
    topFunctions,
  };
}

function parseAddress(value) {
  const text = String(value ?? '').trim();
  if (!text) return null;
  const parsed = /^0x[0-9a-f]+$/i.test(text) ? Number.parseInt(text, 16) : Number(text);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : null;
}

function moduleNamesForStack(stack, modules) {
  const names = [];
  for (const frame of Array.isArray(stack) ? stack : []) {
    const address = parseAddress(frame);
    if (address === null) continue;
    const module = modules.find((candidate) => address >= candidate.base && address < candidate.base + candidate.size);
    if (module?.name) names.push(module.name);
  }
  return names;
}

function nativeCategory(stack, moduleNames = []) {
  const text = [...(Array.isArray(stack) ? stack : []), ...moduleNames].join(' ').toLowerCase();
  if (/v8|javascript|blink::v8|heap/.test(text)) return 'v8';
  if (/blink|dom|layout|style|paint|compositor/.test(text)) return 'blink';
  if (/skia|gpu|gl|d3d|texture|raster/.test(text)) return 'gpu-graphics';
  if (/webrtc|audio|video|media|mojo::/.test(text)) return 'media-webrtc';
  if (/image|png|jpeg|webp|gif|bitmap/.test(text)) return 'image-media';
  if (/net|http|url|cache|disk_cache/.test(text)) return 'network-cache';
  if (/partitionalloc|malloc|calloc|allocator|base::|msedgewebview2|chrome|chromium|edge/.test(text)) return 'chromium-native';
  return 'other';
}

function sanitizedModuleName(name) {
  const baseName = String(name ?? '').split(/[\\/]/).pop() ?? '';
  const sanitized = baseName.replace(/[^A-Za-z0-9._-]/g, '').slice(0, 80);
  return sanitized || 'unknown-module';
}

function summarizeNativeMemoryProfile(profile) {
  const samples = Array.isArray(profile?.samples) ? profile.samples : [];
  const modules = (Array.isArray(profile?.modules) ? profile.modules : []).map((module) => ({
    name: String(module.name ?? ''),
    base: parseAddress(module.baseAddress),
    size: Number(module.size ?? 0),
  })).filter((module) => module.name && module.base !== null && Number.isFinite(module.size) && module.size > 0);
  const sizes = samples.map((sample) => Number(sample.size ?? 0)).filter(Number.isFinite);
  const totals = samples.map((sample) => Number(sample.total ?? sample.size ?? 0)).filter(Number.isFinite);
  const stackDepths = samples.map((sample) => Array.isArray(sample.stack) ? sample.stack.length : 0);
  const categories = new Map();
  const moduleTotals = new Map();
  let mappedFrames = 0;
  let totalFrames = 0;
  for (const sample of samples) {
    const bytes = Number(sample.size ?? 0);
    if (!Number.isFinite(bytes) || bytes <= 0) continue;
    const stack = Array.isArray(sample.stack) ? sample.stack : [];
    const moduleNames = moduleNamesForStack(stack, modules);
    totalFrames += stack.length;
    mappedFrames += moduleNames.length;
    const category = nativeCategory(stack, moduleNames);
    const current = categories.get(category) ?? { category, sampledBytes: 0, sampleCount: 0 };
    current.sampledBytes += bytes;
    current.sampleCount += 1;
    categories.set(category, current);
    const primaryModule = sanitizedModuleName(moduleNames[0]);
    const moduleCurrent = moduleTotals.get(primaryModule) ?? {
      module: primaryModule,
      sampledBytes: 0,
      sampleCount: 0,
    };
    moduleCurrent.sampledBytes += bytes;
    moduleCurrent.sampleCount += 1;
    moduleTotals.set(primaryModule, moduleCurrent);
  }
  return {
    available: true,
    sampleStatus: samples.length > 0 ? 'samples-collected' : 'no-samples',
    sampleCount: samples.length,
    sampledBytes: sizes.reduce((sum, size) => sum + size, 0),
    attributedBytes: totals.reduce((sum, size) => sum + size, 0),
    largestSampleBytes: sizes.length > 0 ? Math.max(...sizes) : 0,
    maximumStackDepth: stackDepths.length > 0 ? Math.max(...stackDepths) : 0,
    moduleCount: Array.isArray(profile?.modules) ? profile.modules.length : null,
    moduleMappedFrameCount: mappedFrames,
    moduleFrameCount: totalFrames,
    nativeAllocationCategories: [...categories.values()].sort((left, right) => right.sampledBytes - left.sampledBytes),
    nativeAllocationModules: [...moduleTotals.values()]
      .sort((left, right) => right.sampledBytes - left.sampledBytes)
      .slice(0, 20),
  };
}

function unavailableNativeMemory(error) {
  return {
    available: false,
    sampleStatus: 'unavailable',
    sampleCount: null,
    error,
    nativeAllocationCategories: [],
    nativeAllocationModules: [],
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
    : unavailableNativeMemory(nativeMemory.error);
  const browserNativeMemory = await optionalCommand('Memory.getBrowserSamplingProfile');
  result.browserNativeMemorySampling = browserNativeMemory.available
    ? summarizeNativeMemoryProfile(browserNativeMemory.result.profile)
    : unavailableNativeMemory(browserNativeMemory.error);
  const aggregate = await optionalCommand('Runtime.evaluate', {
    expression: `(() => ({
      domNodeCount: document.getElementsByTagName('*').length,
      frameCount: window.top === window ? window.frames.length + 1 : null,
      imageElementCount: document.images.length,
      imageNaturalPixelCount: Array.from(document.images).reduce((sum, image) => sum + (image.naturalWidth * image.naturalHeight), 0),
      videoElementCount: document.getElementsByTagName('video').length,
      videoPixelCount: Array.from(document.getElementsByTagName('video')).reduce((sum, video) => sum + (video.videoWidth * video.videoHeight), 0),
      canvasElementCount: document.getElementsByTagName('canvas').length,
      canvasPixelCount: Array.from(document.getElementsByTagName('canvas')).reduce((sum, canvas) => sum + (canvas.width * canvas.height), 0)
    }))()`,
    returnByValue: true,
    awaitPromise: false,
  });
  result.documentAggregates = aggregate.result?.result?.value ?? { error: aggregate.error };
  const domCounters = await optionalCommand('Memory.getDOMCounters');
  result.domCounters = domCounters.available ? domCounters.result : { error: domCounters.error };

  const nativeWindow = await optionalCommand('Memory.startSampling', { samplingInterval: 32768, suppressRandomness: true });
  const started = await optionalCommand('HeapProfiler.startSampling', { samplingInterval: 32768 });
  await new Promise((resolve) => setTimeout(resolve, durationSeconds * 1000));
  const nativeStopped = nativeWindow.available
    ? await optionalCommand('Memory.stopSampling')
    : { available: false, error: nativeWindow.error };
  const nativeProfile = nativeWindow.available
    ? await optionalCommand('Memory.getSamplingProfile')
    : { available: false, error: nativeWindow.error };
  const stopProfile = nativeStopped.available ? summarizeNativeMemoryProfile(nativeStopped.result.profile) : unavailableNativeMemory(nativeStopped.error);
  const getProfile = nativeProfile.available ? summarizeNativeMemoryProfile(nativeProfile.result.profile) : unavailableNativeMemory(nativeProfile.error);
  const primaryProfile = nativeProfile.available ? getProfile : stopProfile;
  result.nativeMemorySamplingWindow = {
    ...primaryProfile,
    sourceMethod: nativeProfile.available ? 'Memory.getSamplingProfile' : 'Memory.stopSampling',
    stopSampling: stopProfile,
    getSamplingProfile: getProfile,
  };
  if (started.available) {
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
