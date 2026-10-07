import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9222);
const durationSeconds = Math.max(1, Math.min(60, Number(process.argv[3] ?? 10)));
const outputPath = process.argv[4];
const collectGarbage = process.argv.includes('--collect-garbage');
const reloadBeforeSampling = process.argv.includes('--reload-before-sampling');
if (!outputPath) throw new Error('Output path is required.');

const base = `http://127.0.0.1:${port}`;
const list = await (await fetch(`${base}/json/list`)).json();
const target = list.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

async function openChannel(url) {
  const socket = await new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
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

const pageChannel = await openChannel(target.webSocketDebuggerUrl);
const socket = pageChannel.socket;
const command = pageChannel.command;
let browserChannel = null;
try {
  const version = await (await fetch(`${base}/json/version`)).json();
  if (version.webSocketDebuggerUrl) browserChannel = await openChannel(version.webSocketDebuggerUrl);
} catch {
  browserChannel = null;
}

async function optionalCommandOn(channel, method, params = {}) {
  try {
    return { available: true, result: await channel.command(method, params) };
  } catch (error) {
    return { available: false, error: String(error.message ?? error) };
  }
}

async function optionalCommand(method, params = {}) {
  return optionalCommandOn(pageChannel, method, params);
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
    const rawName = String(frame.functionName || frame.url || '(anonymous)');
    const name = /^(?:[a-z]+:|\/\/|[a-z]:[\\/])/i.test(rawName)
      ? '(redacted-url-or-path)'
      : rawName.slice(0, 120);
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

function summarizeUserAgentSpecificMemory(value) {
  if (!value || typeof value !== 'object') {
    return { available: false, reason: 'no-result' };
  }
  const totals = new Map();
  for (const row of Array.isArray(value.breakdown) ? value.breakdown : []) {
    const bytes = Number(row.bytes ?? 0);
    if (!Number.isFinite(bytes) || bytes < 0) continue;
    const labels = Array.isArray(row.types) ? row.types.map((type) => String(type).toLowerCase()) : [];
    const category = labels.some((type) => type.includes('javascript'))
      ? 'javascript'
      : labels.some((type) => type.includes('dom'))
        ? 'dom'
        : labels.some((type) => type.includes('shared'))
          ? 'shared'
          : 'other';
    const current = totals.get(category) ?? { category, bytes: 0, entries: 0 };
    current.bytes += bytes;
    current.entries += 1;
    totals.set(category, current);
  }
  return {
    available: true,
    totalBytes: Number(value.bytes ?? 0),
    categories: [...totals.values()].sort((left, right) => right.bytes - left.bytes),
  };
}

const result = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  targetType: target.type,
  targetCount: list.length,
  reloadBeforeSampling,
  browserTargetAvailable: browserChannel !== null,
  policy: 'Aggregate-only diagnostic. No page text, URLs, cookies, tokens, heap objects, or raw profiles are written.',
};

try {
  const browserSamplingStart = browserChannel
    ? await optionalCommandOn(browserChannel, 'Memory.startSampling', { samplingInterval: 32768, suppressRandomness: true })
    : { available: false, error: 'Browser CDP target unavailable.' };
  await command('Runtime.enable');
  await command('Performance.enable');
  if (reloadBeforeSampling) {
    await command('Page.enable');
    await command('Page.reload', { ignoreCache: false });
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }
  result.heapUsage = (await optionalCommand('Runtime.getHeapUsage')).result ?? null;
  if (collectGarbage) {
    const before = result.heapUsage;
    const collected = await optionalCommand('HeapProfiler.collectGarbage');
    await new Promise((resolve) => setTimeout(resolve, 3000));
    const after = (await optionalCommand('Runtime.getHeapUsage')).result ?? null;
    result.gcProbe = {
      requested: true,
      available: collected.available,
      error: collected.error ?? null,
      before,
      after,
      usedSizeDeltaBytes: before && after ? Number(after.usedSize ?? 0) - Number(before.usedSize ?? 0) : null,
      totalSizeDeltaBytes: before && after ? Number(after.totalSize ?? 0) - Number(before.totalSize ?? 0) : null,
    };
  } else {
    result.gcProbe = { requested: false };
  }
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
    expression: `(() => {
      const images = Array.from(document.images);
      const videos = Array.from(document.getElementsByTagName('video'));
      const animatedImageHintCount = images.filter((image) => {
        const source = String(image.currentSrc || '').toLowerCase();
        return /\\.(?:gif|apng)(?:$|[?#])/.test(source) || source.startsWith('data:image/gif');
      }).length;
      return ({
      domNodeCount: document.getElementsByTagName('*').length,
      frameCount: window.top === window ? window.frames.length + 1 : null,
      imageElementCount: images.length,
      imageNaturalPixelCount: images.reduce((sum, image) => sum + (image.naturalWidth * image.naturalHeight), 0),
      animatedImageHintCount,
      videoElementCount: videos.length,
      playingVideoCount: videos.filter((video) => !video.paused && !video.ended && video.readyState >= 2).length,
      videoReadyStateCounts: videos.reduce((counts, video) => {
        const key = String(video.readyState);
        counts[key] = (counts[key] || 0) + 1;
        return counts;
      }, {}),
      videoPixelCount: videos.reduce((sum, video) => sum + (video.videoWidth * video.videoHeight), 0),
      canvasElementCount: document.getElementsByTagName('canvas').length,
      canvasPixelCount: Array.from(document.getElementsByTagName('canvas')).reduce((sum, canvas) => sum + (canvas.width * canvas.height), 0)
      });
    })()`,
    returnByValue: true,
    awaitPromise: false,
  });
  result.documentAggregates = aggregate.result?.result?.value ?? { error: aggregate.error };
  const userAgentMemory = await optionalCommand('Runtime.evaluate', {
    expression: `performance.measureUserAgentSpecificMemory ? performance.measureUserAgentSpecificMemory() : null`,
    returnByValue: true,
    awaitPromise: true,
  });
  result.userAgentSpecificMemory = userAgentMemory.available
    ? summarizeUserAgentSpecificMemory(userAgentMemory.result?.result?.value)
    : { available: false, error: userAgentMemory.error };
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
  if (browserSamplingStart.available) {
    const browserProfile = await optionalCommandOn(browserChannel, 'Memory.getSamplingProfile');
    const browserStop = await optionalCommandOn(browserChannel, 'Memory.stopSampling');
    result.browserNativeMemorySampling = browserProfile.available
      ? {
        ...summarizeNativeMemoryProfile(browserProfile.result.profile),
        sourceMethod: 'browser-target-Memory.getSamplingProfile',
        stopSampling: browserStop.available ? summarizeNativeMemoryProfile(browserStop.result.profile) : unavailableNativeMemory(browserStop.error),
      }
      : unavailableNativeMemory(browserProfile.error);
  } else {
    result.browserNativeMemorySampling = unavailableNativeMemory(browserSamplingStart.error);
  }
} finally {
  socket.close();
  if (browserChannel) browserChannel.socket.close();
}

await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, targetCount: result.targetCount, heapSampling: result.heapSampling }));
