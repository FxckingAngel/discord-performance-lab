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

const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const expected = ['app', 'ipc', 'isRenderer', 'nativeModules', 'os', 'process', 'processUtils', 'safeStorage', 'setUncaughtExceptionHandler'];
    const native = globalThis.DiscordNative;
    const groups = native && typeof native === 'object' ? Object.keys(native).sort() : [];
    const marker = globalThis.__trackBBootContractActivation ?? null;
    const domNodeCount = document.querySelectorAll('*').length;
    const appMount = document.querySelector('#app-mount');
    const state = {
      readyState: document.readyState,
      domNodeCount,
      appMountChildCount: appMount?.children.length ?? 0,
      appMountRect: appMount ? {
        width: appMount.getBoundingClientRect().width,
        height: appMount.getBoundingClientRect().height,
      } : null,
      marker,
      discordNativePresent: Boolean(native),
      groups,
      missingGroups: expected.filter((name) => !groups.includes(name)),
      unexpectedGroups: groups.filter((name) => !expected.includes(name)),
      missingContractAccesses: Array.from(new Set(globalThis.__trackBBootContractAccess?.missing ?? [])).slice(0, 100),
      contractCallSequence: (globalThis.__trackBBootContractAccess?.calls ?? []).slice(0, 100),
      contractReturns: (globalThis.__trackBBootContractAccess?.returnShapes ?? []).slice(0, 100),
      contractErrors: Array.from(new Set(globalThis.__trackBBootContractAccess?.errors ?? [])).slice(0, 100),
      argumentShapes: (globalThis.__trackBBootContractAccess?.argumentShapes ?? []).slice(0, 100),
      stringFingerprints: globalThis.__trackBBootContractAccess?.stringFingerprints ?? [],
      moduleRequests: Array.from(new Set(globalThis.__trackBModuleRequests ?? [])).slice(0, 20),
    };
    state.atomicShape = marker?.shape === 'atomic-candidate'
      && marker?.mode === 'diagnostic-only'
      && marker?.bootContractVersion === 1
      && marker?.implementation === 'isolated-capabilities-composed-for-diagnostic-activation'
      && marker?.activation === 'atomic-only'
      && Array.isArray(marker?.groups)
      && marker.groups.length === expected.length
      && Array.isArray(marker?.unsupportedModules)
      && marker.unsupportedModules.length === 0
      && Array.isArray(marker?.placeholderPaths)
      && marker.placeholderPaths.length === 0
      && state.missingGroups.length === 0
      && state.unexpectedGroups.length === 0
      && expected.every((name) => marker.groups.includes(name));
    state.frontendInitialized = state.readyState === 'complete'
      && state.appMountChildCount > 0
      && state.domNodeCount >= 100
      && state.appMountRect !== null
      && state.appMountRect.width > 0
      && state.appMountRect.height > 0;
    state.activationPassed = state.atomicShape
      && state.frontendInitialized
      && state.contractErrors.length === 0;
    return state;
  })()`,
  returnByValue: true,
});
const state = result.result?.value;
if (!state) throw new Error('Boot-contract activation state query returned no value.');
console.log(JSON.stringify({ port, targetType: target.type, state }));
socket.close();

if (!state.activationPassed) process.exitCode = 2;
