// Builds one contact sheet of every sprite on a grass background, for eyeballing the art.
import { createRequire } from 'node:module';
import { readdirSync, readFileSync } from 'node:fs';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const dir = process.argv[2];
const out = process.argv[3];
const cols = Number(process.argv[4] ?? 6);
const files = readdirSync(dir).filter((f) => f.endsWith('.png')).sort();
const cells = files.map((f) => {
  const b64 = readFileSync(`${dir}/${f}`).toString('base64');
  return `<div style="display:inline-block;text-align:center;font:11px sans-serif;margin:4px"><img src="data:image/png;base64,${b64}" style="height:128px"><br>${f.replace('.png', '')}</div>`;
}).join('');
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: cols * 150, height: 400 } });
await page.setContent(`<body style="margin:0;background:#7cb342">${cells}</body>`);
await page.screenshot({ path: out, fullPage: true });
await browser.close();
