// Draws the geometry guide for new art: the 128x128 canvas shared by plots, pens, crops and
// animals, with the tile diamond the game uses for placement and tap targets.
// Output: docs/art-template-tile.png (512x512, magenta guides on white).
import { renderAll } from './render.mjs';
import { CX, CY, TILE_W, TILE_H, diamond, svg } from './art.mjs';

const W = TILE_W - 4, H = TILE_H - 2; // the diamond as drawn (124 x 62)
const body =
  `<rect width="128" height="128" fill="#ffffff"/>` +
  `<rect x="0.5" y="0.5" width="127" height="127" fill="none" stroke="#999" stroke-width="1" stroke-dasharray="3 2"/>` +
  `<polygon points="${diamond(CX, CY, W, H)}" fill="#ffe6f6" fill-opacity="0.6" stroke="#e0007a" stroke-width="1.4"/>` +
  // slab depth (the visible side faces)
  `<polyline points="${CX - W / 2},${CY} ${CX - W / 2},${CY + 10} ${CX},${CY + H / 2 + 10} ${CX + W / 2},${CY + 10} ${CX + W / 2},${CY}" fill="none" stroke="#e0007a" stroke-width="1" stroke-dasharray="2 2"/>` +
  `<line x1="${CX}" y1="${CY - 6}" x2="${CX}" y2="${CY + 6}" stroke="#e0007a" stroke-width="1"/><line x1="${CX - 6}" y1="${CY}" x2="${CX + 6}" y2="${CY}" stroke="#e0007a" stroke-width="1"/>` +
  `<text x="64" y="9" font-family="sans-serif" font-size="4.2" text-anchor="middle" fill="#555">canvas 128x128 (export 4x = 512x512), transparent</text>` +
  `<text x="64" y="15" font-family="sans-serif" font-size="3.6" text-anchor="middle" fill="#555">plants and animals may rise to the top edge</text>` +
  `<text x="64" y="21" font-family="sans-serif" font-size="3.6" text-anchor="middle" fill="#555">dashed = side faces of the tile, 10 deep</text>` +
  `<text x="64" y="${CY + 14}" font-family="sans-serif" font-size="3.8" text-anchor="middle" fill="#e0007a">centre (64, 88) - diamond 124 x 62</text>`;

await renderAll({ 'art-template-tile': { w: 128, h: 128, svg: svg(128, 128, body) } }, new URL('../../docs', import.meta.url).pathname, 4);
console.log('template written');
