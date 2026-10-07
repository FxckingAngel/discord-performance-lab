import fs from 'node:fs/promises';

const [officialPortText, trackBPortText, nativePath, outputPath] = process.argv.slice(2);
if (!officialPortText || !trackBPortText || !nativePath || !outputPath) {
  throw new Error('Usage: node Probe-DiscordDesktopParityOracle.mjs <officialPort> <trackBPort> <nativeJson> <outputJson>');
}

const native = JSON.parse((await fs.readFile(nativePath, 'utf8')).replace(/^\uFEFF/, ''));
const readPage = async (portText) => {
  const port = Number(portText);
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
  if (!target) throw new Error(`No page target was found on port ${port}.`);
  const socket = await new Promise((resolve, reject) => {
    const ws = new WebSocket(target.webSocketDebuggerUrl);
    ws.addEventListener('open', () => resolve(ws));
    ws.addEventListener('error', () => reject(new Error(`CDP WebSocket error on port ${port}.`)));
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
  const expression = `(() => ({
    devicePixelRatio,
    innerWidth,
    innerHeight,
    outerWidth,
    outerHeight,
    screen: { width: screen.width, height: screen.height, availWidth: screen.availWidth, availHeight: screen.availHeight },
    visualViewport: { width: visualViewport?.width ?? null, height: visualViewport?.height ?? null, scale: visualViewport?.scale ?? null },
    visualViewportScale: visualViewport?.scale ?? null,
    zoomFactor: null,
    cssPixelToDevicePixelScale: devicePixelRatio * (visualViewport?.scale ?? 1),
    titlebarOffset: { x: window.screenX, y: window.screenY, outerToInnerX: outerWidth - innerWidth, outerToInnerY: outerHeight - innerHeight }
  }))()`;
  try {
    const result = await command('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: false });
    return { port, targetType: target.type, page: result.result?.value ?? null };
  } finally { socket.close(); }
};

const [official, trackB] = await Promise.all([readPage(officialPortText), readPage(trackBPortText)]);
const output = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  policy: 'Sanitized desktop parity oracle. Only runtime geometry, scale, DPI, and process-role facts are written. No page text, URLs, IDs, cookies, tokens, account data, or message data are written.',
  expected: { official, native: native.official },
  candidate: { trackB, native: native.trackB },
  comparison: {
    pageDevicePixelRatioEqual: official.page?.devicePixelRatio === trackB.page?.devicePixelRatio,
    logicalViewportEqual: official.page?.innerWidth === trackB.page?.innerWidth && official.page?.innerHeight === trackB.page?.innerHeight,
    nativeDpiEqual: native.official?.dpi === native.trackB?.dpi,
    systemDpiEqual: native.official?.systemDpi === native.trackB?.systemDpi,
    windowsScaleEqual: native.official?.windowsScalePercent === native.trackB?.windowsScalePercent,
    nativeWindowSizeEqual: native.official?.window?.width === native.trackB?.window?.width && native.official?.window?.height === native.trackB?.window?.height,
    nativeClientSizeEqual: native.official?.client?.width === native.trackB?.client?.width && native.official?.client?.height === native.trackB?.client?.height,
    pageScaleEqual: official.page?.devicePixelRatio === trackB.page?.devicePixelRatio && official.page?.visualViewportScale === trackB.page?.visualViewportScale,
    dpiAwarenessEqual: native.official?.dpiAwareness === native.trackB?.dpiAwareness,
    refreshRateEqual: native.official?.monitor?.refreshRateHz === native.trackB?.monitor?.refreshRateHz,
    clientOriginEqual: native.official?.titlebarClientOffset?.x === native.trackB?.titlebarClientOffset?.x && native.official?.titlebarClientOffset?.y === native.trackB?.titlebarClientOffset?.y,
    monitorGeometryEqual: native.official?.monitor?.width === native.trackB?.monitor?.width && native.official?.monitor?.height === native.trackB?.monitor?.height,
    titlebarGeometryEqual: native.official?.nonClient?.width === native.trackB?.nonClient?.width && native.official?.nonClient?.height === native.trackB?.nonClient?.height
  }
};
await fs.writeFile(outputPath, JSON.stringify(output, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath }));
