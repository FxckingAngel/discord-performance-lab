const port = Number(process.argv[2] ?? 9238);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No erlpack bridge probe page was found.');

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
    const module = DiscordNative.nativeModules.requireModule('discord_erlpack');
    const input = { hello: 'world', number: 42, nested: [true, null, 'x'] };
    const packed = module.pack(input);
    const bytes = Array.from(packed);
    const unpacked = module.unpack(new Uint8Array(bytes));
    return JSON.stringify({
      exportedMethods: ['pack', 'unpack'],
      packedType: Object.prototype.toString.call(packed),
      packedLength: bytes.length,
      packedHex: bytes.map((value) => value.toString(16).padStart(2, '0')).join(''),
      roundTrip: JSON.stringify(unpacked) === JSON.stringify(input),
    });
  })()`,
  returnByValue: true,
  awaitPromise: true,
});

const value = result.result?.value;
if (!value) throw new Error(`Erlpack probe returned no result: ${JSON.stringify(result)}`);
console.log(value);
socket.close();
