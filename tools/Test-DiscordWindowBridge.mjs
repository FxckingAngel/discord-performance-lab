const port = Number(process.argv[2] ?? 9226);
const action = process.argv[3] ?? 'focus';
const allowed = new Set(['minimize', 'maximize', 'restore', 'close', 'focus']);
if (!allowed.has(action)) throw new Error(`Unsupported diagnostic action: ${action}`);

const targets = await (await fetch(`http://localhost:${port}/json/list`)).json();
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

const result = await new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({
    id,
    method: 'Runtime.evaluate',
    params: {
      expression: `(() => { const fn = globalThis.DiscordNative?.window?.${action}; if (typeof fn !== 'function') throw new Error('Bridge action unavailable'); fn(); return 'called'; })()`,
      returnByValue: true,
      awaitPromise: false,
    },
  }));
});
socket.close();
if (result.exceptionDetails) throw new Error(result.exceptionDetails.text ?? 'Bridge action failed.');
console.log(JSON.stringify({ port, action, result: result.result?.value ?? null }));
