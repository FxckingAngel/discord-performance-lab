const port = Number(process.argv[2] ?? 9239);
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
const events = [];
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (message.method === 'Runtime.exceptionThrown') {
    const details = message.params.exceptionDetails ?? {};
    const description = details.exception?.description ?? '';
    events.push({
      type: 'exception',
      name: description.split(/\r?\n/, 1)[0]?.slice(0, 160) || 'unknown',
      line: details.lineNumber ?? null,
      column: details.columnNumber ?? null,
      stackLines: description.split(/\r?\n/).slice(1, 3).map((line) => line.slice(0, 240)),
    });
  } else if (message.method === 'Runtime.consoleAPICalled') {
    events.push({ type: 'console', level: message.params.type });
  }
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
await command('Log.enable');
await command('Page.enable');
await command('Page.reload', { ignoreCache: false });
await new Promise((resolve) => setTimeout(resolve, 10000));
const stateResult = await command('Runtime.evaluate', {
  expression: `(() => { const mount = document.querySelector('#app-mount'); return { readyState: document.readyState, titlePresent: Boolean(document.title), appMountChildren: mount?.children.length ?? 0, appMountHeight: mount?.getBoundingClientRect().height ?? 0 }; })()`,
  returnByValue: true,
});
console.log(JSON.stringify({ port, events, state: stateResult.result?.value ?? null }));
socket.close();
