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
const groups = [...initializer.matchAll(/(?:^|,)\s*([A-Za-z0-9_$]+):__webpack_require__\(\d+\)/g)]
  .map((match) => match[1])
  .filter((name) => name !== 'app')
  .concat(initializer.includes('app,') ? ['app'] : [])
  .concat(initializer.includes('isRenderer:') ? ['isRenderer'] : [])
  .concat(initializer.includes('setUncaughtExceptionHandler:') ? ['setUncaughtExceptionHandler'] : [])
  .sort();

const ipcEvents = [...source.matchAll(/IPCEvents\.([A-Z0-9_]+)/g)]
  .map((match) => match[1])
  .sort()
  .filter((name, index, all) => index === 0 || name !== all[index - 1]);

const result = {
  sourceFileName: sourcePath.split(/[\\/]/).pop(),
  sourceBytes: Buffer.byteLength(source, 'utf8'),
  discordNativeGroupCount: groups.length,
  discordNativeGroups: groups,
  ipcEventCount: ipcEvents.length,
  ipcEvents,
  collection: 'sanitized static contract; no arguments, return values, account data, URLs, cookies, or tokens',
};

await fs.writeFile(outputPath, `${JSON.stringify(result, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ outputPath, discordNativeGroupCount: groups.length, ipcEventCount: ipcEvents.length }));
