const port = Number(process.argv[2] ?? 9240);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No file-dialog probe page was found.');

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
    const fileManager = globalThis.DiscordNative?.fileManager;
    const invalid = fileManager?.showOpenDialog?.({ properties: ['openDirectory'] })
      .then(() => ({ rejected: false }))
      .catch((error) => ({ rejected: true, errorName: error?.name ?? 'Error' }));
    const malformed = fileManager?.showOpenDialog?.({ filters: [{ name: 'Images', extensions: ['|'] }] })
      .then(() => ({ rejected: false }))
      .catch((error) => ({ rejected: true, errorName: error?.name ?? 'Error' }));
    const invalidItem = fileManager?.showItemInFolder?.('')
      .then(() => ({ rejected: false }))
      .catch((error) => ({ rejected: true, errorName: error?.name ?? 'Error' }));
    return Promise.all([invalid, malformed, invalidItem]).then(([invalidResult, malformedResult, invalidItemResult]) => ({
      groupPresent: Boolean(fileManager),
      methodType: typeof fileManager?.showOpenDialog,
      showItemInFolderType: typeof fileManager?.showItemInFolder,
      saveWithDialogType: typeof fileManager?.saveWithDialog,
      saveWithDialog2Type: typeof fileManager?.saveWithDialog2,
      invalidPropertyRejected: invalidResult?.rejected === true,
      invalidPropertyErrorName: invalidResult?.errorName ?? null,
      malformedFilterRejected: malformedResult?.rejected === true,
      malformedFilterErrorName: malformedResult?.errorName ?? null,
      invalidItemRejected: invalidItemResult?.rejected === true,
      invalidItemErrorName: invalidItemResult?.errorName ?? null,
      noDialogOpened: true,
    }));
  })()`,
  returnByValue: true,
  awaitPromise: true,
});
const value = result.result?.value;
if (!value) throw new Error(`File-dialog probe returned no result: ${JSON.stringify(result)}`);
console.log(JSON.stringify(value));
if (!value.groupPresent || value.methodType !== 'function' || value.showItemInFolderType !== 'function' || value.saveWithDialogType !== 'function' || value.saveWithDialog2Type !== 'function' || !value.invalidPropertyRejected || !value.malformedFilterRejected || !value.invalidItemRejected || !value.noDialogOpened) {
  process.exitCode = 2;
}
socket.close();
