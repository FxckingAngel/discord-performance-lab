const port = Number(process.argv[2] ?? 9242);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No power-monitor probe page was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP connection failed.')));
});
let nextId = 1;
const pending = new Map();
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (!message.id || !pending.has(message.id)) return;
  const request = pending.get(message.id);
  pending.delete(message.id);
  if (message.error) request.reject(new Error(message.error.message));
  else request.resolve(message.result ?? {});
});
const command = (method, params = {}) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({ id, method, params }));
});

const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const powerMonitor = globalThis.DiscordNative?.powerMonitor;
    const methodType = typeof powerMonitor?.getSystemIdleTimeMs;
    return Promise.resolve().then(() => powerMonitor?.getSystemIdleTimeMs?.()).then((idleMs) => ({
      groupPresent: Boolean(powerMonitor),
      methodType,
      valueType: typeof idleMs,
      nonNegativeFinite: Number.isFinite(idleMs) && idleMs >= 0,
    }));
  })()`,
  returnByValue: true,
  awaitPromise: true,
});
const value = result.result?.value;
if (!value) throw new Error(`Power-monitor probe returned no result: ${JSON.stringify(result)}`);
console.log(JSON.stringify(value));
if (!value.groupPresent || value.methodType !== 'function' || value.valueType !== 'number' || !value.nonNegativeFinite) process.exitCode = 2;
socket.close();
