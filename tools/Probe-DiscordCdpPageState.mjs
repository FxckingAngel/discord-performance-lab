import fs from 'node:fs/promises';

const port = Number(process.argv[2] ?? 9228);
const outputPath = process.argv[3];
if (!outputPath) throw new Error('Output path is required.');

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
socket.addEventListener('message', (event) => {
  const message = JSON.parse(event.data);
  const resolve = pending.get(message.id);
  if (!resolve) return;
  pending.delete(message.id);
  resolve(message);
});

const command = (method, params = {}) => new Promise((resolve) => {
  const id = nextId++;
  pending.set(id, resolve);
  socket.send(JSON.stringify({ id, method, params }));
});

const result = await command('Runtime.evaluate', {
  expression: `(() => {
    const root = document.documentElement;
    const body = document.body;
    const visible = (element) => {
      if (!element) return false;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== 'none'
        && style.visibility !== 'hidden'
        && Number(style.opacity) > 0
        && rect.width > 0
        && rect.height > 0;
    };
    return {
      readyState: document.readyState,
      title: document.title,
      htmlChildCount: root?.children.length ?? 0,
      bodyChildCount: body?.children.length ?? 0,
      bodyChildTags: body ? [...body.children].map((element) => {
        const style = getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return {
          tag: element.tagName,
          childCount: element.children.length,
          display: style.display,
          visibility: style.visibility,
          opacity: style.opacity,
          width: rect.width,
          height: rect.height,
        };
      }) : [],
      scriptCount: document.scripts.length,
      stylesheetCount: document.styleSheets.length,
      bodyTextLength: body?.innerText?.length ?? 0,
      bodyHtmlLength: body?.innerHTML?.length ?? 0,
      visibleBodyChildCount: body ? [...body.children].filter(visible).length : 0,
      bodyBackground: body ? getComputedStyle(body).backgroundColor : null,
      rootClassPresent: Boolean(root?.className),
      viewport: { width: innerWidth, height: innerHeight, devicePixelRatio },
    };
  })()`,
  returnByValue: true,
});

const value = result.result?.result?.value;
if (!value) throw new Error('CDP did not return page-state data.');

await fs.writeFile(outputPath, `${JSON.stringify({
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  endpoint: `127.0.0.1:${port}`,
  targetType: target.type,
  policy: 'Sanitized page-state diagnostic. No page text, URLs, cookies, tokens, DOM attributes, or account data are written.',
  pageState: value,
}, null, 2)}\n`);

socket.close();
console.log(JSON.stringify({ outputPath, pageState: value }));
