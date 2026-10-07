const port = Number(process.argv[2] ?? 9239);
const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
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

await command('Runtime.enable');
const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const mount = document.querySelector('#app-mount');
    return {
      readyState: document.readyState,
      titlePresent: Boolean(document.title),
      bodyChildCount: document.body?.children.length ?? 0,
      appMountPresent: Boolean(mount),
      appMountChildCount: mount?.children.length ?? 0,
      appMountTextLength: mount?.textContent?.length ?? 0,
      appMountRect: mount ? { width: mount.getBoundingClientRect().width, height: mount.getBoundingClientRect().height } : null,
      documentElementRect: { width: document.documentElement.clientWidth, height: document.documentElement.clientHeight },
      missingContractAccesses: Array.from(new Set(globalThis.__trackBBootContractAccess?.missing ?? [])).slice(0, 100),
      contractCallSequence: (globalThis.__trackBBootContractAccess?.calls ?? []).slice(0, 100),
      contractReturns: (globalThis.__trackBBootContractAccess?.returnShapes ?? []).slice(0, 100),
      contractErrors: Array.from(new Set(globalThis.__trackBBootContractAccess?.errors ?? [])).slice(0, 100),
      moduleRequests: Array.from(new Set(globalThis.__trackBModuleRequests ?? [])).slice(0, 20),
    };
  })()`,
  returnByValue: true,
  awaitPromise: false,
});
const value = result.result?.value;
if (!value) throw new Error('Boot-contract state query returned no value.');
console.log(JSON.stringify({ port, targetType: target.type, state: value }));
socket.close();
