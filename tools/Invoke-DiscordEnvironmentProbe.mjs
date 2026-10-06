import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9222);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');

const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
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
  const has = (name) => typeof globalThis[name] !== 'undefined';
  const safeType = (name) => {
    try { return typeof globalThis[name]; } catch { return 'error'; }
  };
  const native = navigator.userAgentData ?? null;
  const globalNames = [
    'DiscordNative', 'electron', 'require', 'process', 'module', 'chrome',
    'webkit', 'Windows', 'msBrowser', 'browser'
  ];
  return {
    userAgent: navigator.userAgent,
    appVersion: navigator.appVersion,
    platform: navigator.platform,
    userAgentData: native ? {
      brands: native.brands?.map((brand) => brand.brand) ?? [],
      platform: native.platform,
      mobile: native.mobile
    } : null,
    viewport: {
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      outerWidth: window.outerWidth,
      outerHeight: window.outerHeight,
      devicePixelRatio: window.devicePixelRatio,
      visualViewportWidth: window.visualViewport?.width ?? null,
      visualViewportHeight: window.visualViewport?.height ?? null
    },
    mediaQueries: {
      hover: matchMedia('(hover: hover)').matches,
      finePointer: matchMedia('(pointer: fine)').matches,
      reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches,
      dark: matchMedia('(prefers-color-scheme: dark)').matches
    },
    capabilities: {
      notifications: has('Notification'),
      mediaDevices: Boolean(navigator.mediaDevices),
      getUserMedia: Boolean(navigator.mediaDevices?.getUserMedia),
      getDisplayMedia: Boolean(navigator.mediaDevices?.getDisplayMedia),
      clipboard: Boolean(navigator.clipboard),
      filePicker: has('showOpenFilePicker'),
      download: has('showSaveFilePicker'),
      dragDrop: has('DataTransfer'),
      visualViewport: has('VisualViewport')
    },
    globalPresence: Object.fromEntries(globalNames.map((name) => [name, {
      present: has(name),
      type: safeType(name)
    }]))
  };
})()`;

try {
  const result = await command('Runtime.evaluate', {
    expression,
    returnByValue: true,
    awaitPromise: false,
  });
  const value = result.result?.value;
  if (!value) throw new Error('Environment probe returned no value.');
  const output = {
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    endpoint: `127.0.0.1:${port}`,
    targetType: target.type,
    policy: 'Sanitized environment probe. No page text, URL, cookies, tokens, heap objects, or native object values are written.',
    environment: value,
  };
  await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify({ outputPath, targetType: target.type }));
} finally {
  socket.close();
}
