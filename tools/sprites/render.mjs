// Renders SVG strings to transparent PNGs with headless Chromium.
// Usage: NODE_PATH=<dir containing playwright> node render.mjs
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

export async function renderAll(sprites, outDir, scale = 3) {
  mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ deviceScaleFactor: scale });
  const page = await ctx.newPage();
  for (const [name, { w, h, svg }] of Object.entries(sprites)) {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(
      `<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    const png = await page.screenshot({ omitBackground: true, clip: { x: 0, y: 0, width: w, height: h } });
    writeFileSync(`${outDir}/${name}.png`, png);
  }
  await browser.close();
}
