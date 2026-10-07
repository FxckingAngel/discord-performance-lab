const port = Number(process.argv[2] ?? 9226);
const base = `http://127.0.0.1:${port}`;
const targets = await (await fetch(`${base}/json/list`)).json();
const target = targets.find((entry) => entry.type === 'page' && entry.webSocketDebuggerUrl);
if (!target) throw new Error('No window probe page target was found.');

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
  expression: `(async () => {
    const bridge = globalThis.DiscordNative?.window;
    const methods = ['minimize', 'maximize', 'restore', 'close', 'focus', 'setAlwaysOnTop', 'isAlwaysOnTop', 'setMinimumSize', 'fullscreen'];
    const methodTypes = Object.fromEntries(methods.map((name) => [name, typeof bridge?.[name]]));
    if (typeof bridge?.isAlwaysOnTop !== 'function' || typeof bridge?.setAlwaysOnTop !== 'function') {
      return { methodTypes, passed: false, reason: 'missing-always-on-top-methods' };
    }
    const initial = await bridge.isAlwaysOnTop();
    await bridge.setAlwaysOnTop(!initial);
    await new Promise((resolve) => setTimeout(resolve, 75));
    const changed = await bridge.isAlwaysOnTop();
    await bridge.setAlwaysOnTop(initial);
    await new Promise((resolve) => setTimeout(resolve, 75));
    const restored = await bridge.isAlwaysOnTop();
    await bridge.setMinimumSize(Math.max(320, innerWidth), Math.max(240, innerHeight));
    const fullscreenOff = await bridge.fullscreen(false);
    const fullscreenOn = await bridge.fullscreen(true);
    await new Promise((resolve) => setTimeout(resolve, 100));
    const fullscreenOffAgain = await bridge.fullscreen(false);
    return {
      methodTypes,
      initialType: typeof initial,
      changedType: typeof changed,
      restoredType: typeof restored,
      minimumSizeCallCompleted: true,
      fullscreenTypes: [typeof fullscreenOff, typeof fullscreenOn, typeof fullscreenOffAgain],
      fullscreenTransitionPassed: fullscreenOff === false && fullscreenOn === true && fullscreenOffAgain === false,
      stateChanged: changed === !initial,
      stateRestored: restored === initial,
      passed: methodTypes.setAlwaysOnTop === 'function' && methodTypes.isAlwaysOnTop === 'function' && methodTypes.setMinimumSize === 'function' && methodTypes.fullscreen === 'function' && typeof initial === 'boolean' && changed === !initial && restored === initial && fullscreenOff === false && fullscreenOn === true && fullscreenOffAgain === false,
    };
  })()`,
  awaitPromise: true,
  returnByValue: true,
});
const state = result.result?.value;
if (!state) throw new Error('Window bridge state query returned no value.');
console.log(JSON.stringify({ port, targetType: target.type, state }));
socket.close();
if (!state.passed) process.exitCode = 2;
