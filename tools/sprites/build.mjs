import { renderAll } from './render.mjs';
import * as art from './art.mjs';

const OUT = new URL('../../app/assets/sprites', import.meta.url).pathname;
const only = process.argv[2];

const sprites = {
  soil_dry: { w: 128, h: 128, svg: art.soil('dry') },
  soil_wet: { w: 128, h: 128, svg: art.soil('wet') },
  soil_locked: { w: 128, h: 128, svg: art.lockedSoil() },
  soil_next: { w: 128, h: 128, svg: art.nextSoil() },
};
for (const id of art.CROP_IDS) {
  for (let st = 0; st < 4; st++) sprites[`crop_${id}_${st}`] = { w: 128, h: 128, svg: art.crop(id, st) };
}
Object.assign(sprites, {
  pen: { w: 128, h: 128, svg: art.pen() },
  animal_chicken: { w: 128, h: 128, svg: art.chicken() },
  animal_sheep: { w: 128, h: 128, svg: art.sheep() },
  animal_cow: { w: 128, h: 128, svg: art.cow() },
  decor_tree: { w: 128, h: 160, svg: art.tree() },
  decor_bush: { w: 80, h: 60, svg: art.bush() },
  decor_flowers: { w: 66, h: 56, svg: art.flowers() },
  decor_tuft: { w: 36, h: 26, svg: art.tuft() },
  decor_barn: { w: 180, h: 160, svg: art.barn() },
  icon_coin: { w: 48, h: 48, svg: art.coin() },
  icon_star: { w: 48, h: 48, svg: art.star() },
  fx_sparkle: { w: 40, h: 40, svg: art.sparkle() },
});
for (const [k, fn] of Object.entries(art.bubbles)) sprites[`bubble_${k}`] = { w: 64, h: 64, svg: fn() };
const pick = only ? Object.fromEntries(Object.entries(sprites).filter(([k]) => k.startsWith(only))) : sprites;
await renderAll(pick, OUT);
console.log(`rendered ${Object.keys(pick).length} sprites to ${OUT}`);
