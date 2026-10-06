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

try {
  const metrics = await command('Runtime.evaluate', {
    expression: `(() => ({
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      devicePixelRatio: window.devicePixelRatio,
      route: location.pathname
    }))()`,
    returnByValue: true,
    awaitPromise: false,
  });
  const screenshot = await command('Page.captureScreenshot', { format: 'png', fromSurface: true });
  if (!screenshot.data) throw new Error('CDP returned no screenshot data.');
  await fs.writeFile(outputPath, Buffer.from(screenshot.data, 'base64'));
  const dimensions = metrics.result?.value ?? {};
  console.log(JSON.stringify({ outputPath, port, targetType: target.type, ...dimensions }));
} finally {
  socket.close();
}
