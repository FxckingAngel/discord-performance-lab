import fs from 'node:fs/promises';

const sourcePath = process.argv[2];
const outputPath = process.argv[3];
if (!sourcePath || !outputPath) {
  throw new Error('Usage: node Extract-DiscordPreloadContract.mjs <mainScreenPreload.js> <output.json>');
}

const source = await fs.readFile(sourcePath, 'utf8');
const marker = 'let app=__webpack_require__';
const start = source.indexOf(marker);
if (start < 0) throw new Error('The compiled DiscordNative initializer was not found.');

const end = source.indexOf('},crashReporterSetup=', start);
if (end < 0) throw new Error('The DiscordNative initializer boundary was not found.');

const initializer = source.slice(start, end);
const groupEntries = [...initializer.matchAll(/(?:^|,)\s*([A-Za-z0-9_$]+):__webpack_require__\((\d+)\)/g)]
  .map((match) => ({ name: match[1], moduleId: match[2] }));
const appModuleMatch = initializer.match(/let app=__webpack_require__\((\d+)\)/);
const moduleEntries = appModuleMatch
  ? [{ name: 'app', moduleId: appModuleMatch[1] }, ...groupEntries]
  : groupEntries;
const groups = groupEntries
  .map((entry) => entry.name)
  .filter((name) => name !== 'app')
  .concat(initializer.includes('app,') ? ['app'] : [])
  .concat(initializer.includes('isRenderer:') ? ['isRenderer'] : [])
  .concat(initializer.includes('setUncaughtExceptionHandler:') ? ['setUncaughtExceptionHandler'] : [])
  .sort();

const moduleStarts = [...source.matchAll(/(?:^|,)(\d{1,5})\(/g)]
  .map((match) => ({ moduleId: match[1], offset: match.index + (match[0].startsWith(',') ? 1 : 0) }))
  .sort((left, right) => left.offset - right.offset);

function moduleSource(moduleId) {
  const start = moduleStarts.findIndex((entry) => entry.moduleId === moduleId);
  if (start < 0) return '';
  const startOffset = moduleStarts[start].offset;
  const endOffset = moduleStarts[start + 1]?.offset ?? source.length;
  return source.slice(startOffset, endOffset);
}

const staticModuleIpcEvents = Object.fromEntries(moduleEntries.map(({ name, moduleId }) => {
  const moduleText = moduleSource(moduleId);
  const seen = new Set();
  const events = [];
  for (const match of moduleText.matchAll(/IPCEvents\.([A-Z0-9_]+)/g)) {
    const event = match[1];
    if (!seen.has(event)) {
      seen.add(event);
      events.push(event);
    }
  }
  const exports = [];
  const seenExports = new Set();
  for (const match of moduleText.matchAll(/exports\.([A-Za-z0-9_$]+)=/g)) {
    const exportName = match[1];
    if (!seenExports.has(exportName)) {
      seenExports.add(exportName);
      exports.push(exportName);
    }
  }
  return [name, { moduleId: Number(moduleId), exports, ipcEvents: events }];
}));

const discordNativeObjectStart = initializer.indexOf('DiscordNative={');
const discordNativeObject = discordNativeObjectStart >= 0
  ? initializer.slice(discordNativeObjectStart)
  : '';
const staticInitializationOrder = groups
  .map((name) => ({ name, offset: discordNativeObject.indexOf(`${name}:`) }))
  .filter((entry) => entry.offset >= 0)
  .sort((left, right) => left.offset - right.offset)
  .map(({ name }) => name);

const ipcEvents = [...source.matchAll(/IPCEvents\.([A-Z0-9_]+)/g)]
  .map((match) => match[1])
  .sort()
  .filter((name, index, all) => index === 0 || name !== all[index - 1]);

const staticIpcEventOrder = [];
const seenStaticIpcEvents = new Set();
for (const match of source.matchAll(/IPCEvents\.([A-Z0-9_]+)/g)) {
  const name = match[1];
  if (!seenStaticIpcEvents.has(name)) {
    seenStaticIpcEvents.add(name);
    staticIpcEventOrder.push(name);
  }
}

const result = {
  sourceFileName: sourcePath.split(/[\\/]/).pop(),
  sourceBytes: Buffer.byteLength(source, 'utf8'),
  discordNativeGroupCount: groups.length,
  discordNativeGroups: groups,
  staticModuleIpcEvents,
  staticInitializationOrder,
  ipcEventCount: ipcEvents.length,
  ipcEvents,
  staticIpcEventOrder,
  runtimeCallSequence: null,
  runtimeCallSequenceStatus: 'not captured; CDP page injection cannot wrap the official non-configurable preload descriptors',
  collection: 'sanitized static contract; no arguments, return values, account data, URLs, cookies, or tokens',
};

await fs.writeFile(outputPath, `${JSON.stringify(result, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ outputPath, discordNativeGroupCount: groups.length, ipcEventCount: ipcEvents.length }));
