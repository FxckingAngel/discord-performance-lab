import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9230);
const durationSeconds = Number(process.argv[3] ?? 30);
const outputPath = process.argv[4];
if (!outputPath) throw new Error('Output path is required.');
if (!Number.isInteger(durationSeconds) || durationSeconds < 1 || durationSeconds > 600) {
  throw new Error('Duration must be an integer from 1 to 600 seconds.');
}

const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No page target with a WebSocket debugger URL was found.');

const socket = await new Promise((resolve, reject) => {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  ws.addEventListener('open', () => resolve(ws));
  ws.addEventListener('error', () => reject(new Error('CDP WebSocket error')));
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

const install = `(() => {
  const state = globalThis.__trackBNativeCallTrace ?? {
    calls: [],
    wrapped: new Set(),
    blocked: new Set(),
    timer: null,
  };
  globalThis.__trackBNativeCallTrace = state;
  const scan = () => {
    const native = globalThis.DiscordNative;
    if (!native || (typeof native !== 'object' && typeof native !== 'function')) return;
    for (const groupName of Object.getOwnPropertyNames(native)) {
      if (state.wrapped.has(groupName + '.__group__')) continue;
      let group;
      try { group = native[groupName]; } catch { continue; }
      if (!group || (typeof group !== 'object' && typeof group !== 'function')) continue;
      const descriptor = Object.getOwnPropertyDescriptor(native, groupName);
      if (!descriptor || (!descriptor.configurable && !descriptor.writable)) {
        state.blocked.add(groupName);
        continue;
      }
      const proxy = new Proxy(group, {
        get(target, property, receiver) {
          const value = Reflect.get(target, property, receiver);
          if (typeof value !== 'function' || typeof property !== 'string') return value;
          const key = groupName + '.' + property;
          return function (...args) {
            if (state.calls.length < 1000) state.calls.push(key);
            return Reflect.apply(value, this, args);
          };
        }
      });
      try {
        if (descriptor.configurable) {
          Object.defineProperty(native, groupName, { ...descriptor, value: proxy });
        } else {
          native[groupName] = proxy;
        }
        state.wrapped.add(groupName + '.__group__');
      } catch {}
    }
  };
  scan();
  if (!state.timer) state.timer = setInterval(scan, 500);
})();`;

await command('Page.enable');
await command('Page.addScriptToEvaluateOnNewDocument', { source: install });
await command('Page.reload', { ignoreCache: false });
await new Promise((resolve) => setTimeout(resolve, durationSeconds * 1000));
const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const state = globalThis.__trackBNativeCallTrace;
    return {
      calls: Array.from(new Set(state?.calls ?? [])).sort(),
      callCount: state?.calls?.length ?? 0,
      wrappedCount: state?.wrapped?.size ?? 0,
      blockedGroups: Array.from(state?.blocked ?? []).sort(),
    };
  })()`,
  returnByValue: true,
  awaitPromise: false,
});
const value = result.result?.value;
if (!value) throw new Error('Native call trace returned no value.');
await fs.writeFile(outputPath, JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  durationSeconds,
  targetType: target.type,
  policy: 'Sanitized method-name trace. Arguments, return values, page data, URLs, cookies, tokens, and native object values are never written.',
  trace: value,
}, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, callCount: value.callCount, uniqueMethods: value.calls.length }));
socket.close();
