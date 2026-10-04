export interface Crop {
  id: string;
  name: string;
  seedPrice: number;
  growSeconds: number;
  yieldCount: number;
  sellPrice: number;
  xp: number;
  unlockLevel: number;
}

// Values are tuned for a short first session, like the original game.
export const CROPS: Crop[] = [
  { id: 'radish', name: 'Редис', seedPrice: 10, growSeconds: 60, yieldCount: 10, sellPrice: 2, xp: 5, unlockLevel: 1 },
  { id: 'wheat', name: 'Пшеница', seedPrice: 20, growSeconds: 300, yieldCount: 20, sellPrice: 2, xp: 10, unlockLevel: 1 },
  { id: 'carrot', name: 'Морковь', seedPrice: 40, growSeconds: 900, yieldCount: 30, sellPrice: 3, xp: 18, unlockLevel: 2 },
  { id: 'strawberry', name: 'Клубника', seedPrice: 90, growSeconds: 3600, yieldCount: 45, sellPrice: 4, xp: 40, unlockLevel: 3 },
  { id: 'corn', name: 'Кукуруза', seedPrice: 200, growSeconds: 7200, yieldCount: 60, sellPrice: 6, xp: 80, unlockLevel: 5 },
];

export const CROP_BY_ID = new Map(CROPS.map((c) => [c.id, c]));

export const TOTAL_PLOTS = 24;
export const START_PLOTS = 6;
export const START_COINS = 200;
export const PLOT_UNLOCK_PRICE = 500;
// A neighbour can steal this share of the crop in total, each thief takes a slice.
export const STEAL_MAX_SHARE = 0.5;
export const STEAL_SLICE = 0.1;

export function xpForLevel(level: number): number {
  return 50 * level * level;
}

export function levelForXp(xp: number): number {
  let level = 1;
  while (xp >= xpForLevel(level)) level++;
  return level;
}
