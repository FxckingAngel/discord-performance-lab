const port = Number(process.argv[2] ?? 9232);
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
const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const kinds = ['audioinput', 'audiooutput', 'videoinput'];
    const permissionNames = ['microphone', 'camera', 'notifications'];
    return Promise.all([
      navigator.mediaDevices?.enumerateDevices?.().then((devices) => ({
        total: devices.length,
        byKind: Object.fromEntries(kinds.map((kind) => [kind, devices.filter((device) => device.kind === kind).length])),
        labelsExposed: devices.filter((device) => device.label).length,
      })).catch((error) => ({ error: error?.name ?? 'error' })),
      Promise.all(permissionNames.map(async (name) => {
        try { return [name, (await navigator.permissions.query({ name })).state]; }
        catch (error) { return [name, 'unsupported:' + (error?.name ?? 'error')]; }
      })).then(Object.fromEntries),
    ]).then(([devices, permissions]) => ({
      mediaDevicesPresent: Boolean(navigator.mediaDevices),
      getUserMedia: typeof navigator.mediaDevices?.getUserMedia === 'function',
      getDisplayMedia: typeof navigator.mediaDevices?.getDisplayMedia === 'function',
      devices,
      permissions,
    }));
  })()`,
  returnByValue: true,
  awaitPromise: true,
});
const value = result.result?.value;
if (!value) throw new Error('Media capability probe returned no result.');
console.log(JSON.stringify({ port, policy: 'Sanitized capability counts and permission states only; no labels, URLs, account data, or media are retained.', result: value }));
socket.close();
