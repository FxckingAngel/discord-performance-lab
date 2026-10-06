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
  ws.addEventListener('error', (event) => reject(new Error(`CDP WebSocket error: ${event.message ?? 'unknown'}`)));
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

const expression = `(() => {
  const candidates = ${JSON.stringify([
    'window',
    'window.minimize',
    'window.maximize',
    'window.restore',
    'window.close',
    'window.focus',
    'window.getMediaSourceId',
    'hardware.getDisplayCount',
    'desktopCapture.getDesktopCaptureSources',
    'fileManager.showOpenDialog',
    'fileManager.saveWithDialog',
    'clipboard.read',
    'clipboard.copy',
    'powerMonitor.getSystemIdleTimeMs',
    'safeStorage.isEncryptionAvailable'
  ])};
  const supports = globalThis.DiscordNative?.features?.supports;
  if (typeof supports !== 'function') {
    return { registryAvailable: false, features: Object.fromEntries(candidates.map((name) => [name, { status: 'registry-unavailable' }])) };
  }
  return {
    registryAvailable: true,
    features: Object.fromEntries(candidates.map((name) => {
      try { return [name, { status: 'reported', value: Boolean(supports(name)) }]; }
      catch (error) { return [name, { status: 'error', error: String(error?.message ?? error) }]; }
    })),
  };
})()`;

try {
  const result = await command('Runtime.evaluate', {
    expression,
    returnByValue: true,
    awaitPromise: false,
  });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text ?? 'Feature probe failed.');
  const value = result.result?.value;
  if (!value) throw new Error('Feature probe returned no value.');
  const output = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    targetType: target.type,
    policy: 'Sanitized feature-support probe. Only fixed capability names and boolean/error results are written. No page data, URLs, cookies, tokens, or native values are written.',
    registryAvailable: value.registryAvailable,
    features: value.features,
  };
  await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, targetType: target.type }));
} finally {
  socket.close();
}
