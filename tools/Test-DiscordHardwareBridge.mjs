const port = Number(process.argv[2] ?? 9227);
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

const evaluate = (expression) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  socket.send(JSON.stringify({
    id,
    method: 'Runtime.evaluate',
    params: {
      expression,
      returnByValue: true,
      awaitPromise: true,
    },
  }));
});

const calls = [];
for (const expression of [
  'globalThis.DiscordNative?.hardware?.getDisplayCount?.()',
  'globalThis.DiscordNative?.hardware?.getDisplayCount?.()',
  'globalThis.DiscordNative?.hardware?.getDisplayCount?.({ diagnosticOnly: true })',
]) {
  const startedAt = performance.now();
  const result = await evaluate(expression);
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.text ?? 'Hardware bridge call failed.');
  calls.push({
    result: result.result?.value ?? null,
    type: result.result?.type ?? null,
    durationMs: Math.round((performance.now() - startedAt) * 1000) / 1000,
  });
}
const values = calls.map((call) => call.result);
const surfaceResult = await evaluate(`(() => {
  const hardware = globalThis.DiscordNative?.hardware;
  if (!hardware || typeof hardware.getDisplayCount !== 'function') throw new Error('Display-count bridge is unavailable.');
  return {
    methodNames: Object.getOwnPropertyNames(hardware).sort(),
    displayMetricsExposed: typeof hardware.getDisplayMetrics === 'function' || typeof hardware.getDisplayBounds === 'function',
  };
})()`);
if (surfaceResult.exceptionDetails) throw new Error(surfaceResult.exceptionDetails.text ?? 'Hardware surface inspection failed.');
const surface = surfaceResult.result?.value;
if (!surface || surface.displayMetricsExposed || surface.methodNames.join(',') !== 'getDisplayCount') process.exitCode = 2;
socket.close();
console.log(JSON.stringify({ port, calls, consistent: values.every((value) => value === values[0]), displayCount: values[0] ?? null, ...surface }));
