const port = Number(process.argv[2] ?? 9241);
const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No clipboard probe page target was found.');

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
    const clipboard = globalThis.DiscordNative?.clipboard;
    const names = ['copy', 'copyImage', 'copyFile', 'cut', 'paste', 'read', 'hasMixedContent'];
    const syntheticText = 'track-b-synthetic-clipboard-test';
    clipboard.copy(syntheticText);
    const roundTrip = clipboard.read();
    return {
      discordNativePresent: Boolean(globalThis.DiscordNative),
      clipboardPresent: Boolean(clipboard),
      methods: Object.fromEntries(names.map((name) => [name, typeof clipboard?.[name]])),
      roundTrip,
      syntheticRoundTripPassed: roundTrip === syntheticText,
      noUserClipboardAccess: true,
    };
  })()`,
  returnByValue: true,
});
const state = result.result?.value;
if (!state) throw new Error('Clipboard bridge state query returned no value.');
const expected = ['copy', 'copyImage', 'copyFile', 'cut', 'paste', 'read', 'hasMixedContent'];
const methodsPassed = expected.every((name) => state.methods[name] === 'function');
const passed = state.discordNativePresent && state.clipboardPresent && methodsPassed
  && state.syntheticRoundTripPassed && state.noUserClipboardAccess;
console.log(JSON.stringify({ port, targetType: target.type, state, passed }));
socket.close();
if (!passed) process.exitCode = 2;
