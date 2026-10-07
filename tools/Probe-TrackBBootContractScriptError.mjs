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
const scripts = new Map();
const exceptions = [];
socket.addEventListener('message', (event) => {
  const message = JSON.parse(String(event.data));
  if (message.method === 'Debugger.scriptParsed' && typeof message.params.url === 'string' && message.params.url.includes('discord.com/assets/')) {
    scripts.set(message.params.scriptId, message.params);
  }
  if (message.method === 'Runtime.exceptionThrown') {
    const details = message.params.exceptionDetails ?? {};
    exceptions.push({
      name: details.exception?.description?.split(/\r?\n/, 1)[0]?.slice(0, 160) ?? 'unknown',
      scriptId: details.scriptId ?? null,
      line: details.lineNumber ?? null,
      column: details.columnNumber ?? null,
    });
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
await command('Debugger.enable');
await command('Page.enable');
await command('Page.reload', { ignoreCache: false });
await new Promise((resolve) => setTimeout(resolve, 8000));
const matches = [];
for (const exception of exceptions.filter((item) => item.scriptId && item.column !== null)) {
  const script = scripts.get(exception.scriptId);
  if (!script) continue;
  let sourceResult;
  try { sourceResult = await command('Debugger.getScriptSource', { scriptId: exception.scriptId }); } catch { continue; }
  const source = sourceResult.scriptSource ?? '';
  const lines = source.split(/\r?\n/);
  const line = lines[exception.line ?? 0] ?? '';
  const start = Math.max(0, (exception.column ?? 0) - 240);
  matches.push({
    name: exception.name,
    urlKind: script.url.includes('/assets/') ? 'discord-asset' : 'other',
    lineLength: line.length,
    sourceWindow: line.slice(start, start + 480),
  });
}
console.log(JSON.stringify({ port, exceptionCount: exceptions.length, exceptions: exceptions.slice(0, 20), matches: matches.slice(0, 5) }));
socket.close();
