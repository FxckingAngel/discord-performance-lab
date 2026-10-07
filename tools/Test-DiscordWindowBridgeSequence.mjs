const port = Number(process.argv[2] ?? 9226);
const actions = ['focus', 'maximize', 'restore', 'minimize', 'restore', 'focus'];
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

const evaluate = (expression) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({ id, method: 'Runtime.evaluate', params: { expression, returnByValue: true, awaitPromise: false } }));
});

const results = [];
for (const action of actions) {
  const result = await evaluate(`(() => { const fn = globalThis.DiscordNative?.window?.${action}; if (typeof fn !== 'function') throw new Error('Bridge action unavailable: ${action}'); fn(); return 'called'; })()`);
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text ?? `Window action failed: ${action}`);
  results.push({ action, result: result.result?.value ?? null });
}
socket.close();
console.log(JSON.stringify({ port, actions: results, closeExcluded: true }));
