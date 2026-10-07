const base = `http://127.0.0.1:${Number(process.argv[2] ?? 9237)}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No safe-storage probe page was found.');

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
    const storage = globalThis.DiscordNative.safeStorage;
    const plainText = 'track-b-safe-storage-round-trip';
    const available = storage.isEncryptionAvailable();
    const encrypted = storage.encryptString(plainText);
    const decrypted = storage.decryptString(encrypted);
    return JSON.stringify({
      available: available === true,
      encryptedType: typeof encrypted,
      encryptedLength: typeof encrypted === 'string' ? encrypted.length : null,
      roundTrip: decrypted === plainText,
    });
  })()`,
  returnByValue: true,
  awaitPromise: true,
});

const value = result.result?.value;
if (!value) throw new Error(`Safe-storage probe returned no result: ${JSON.stringify(result)}`);
console.log(value);
socket.close();
