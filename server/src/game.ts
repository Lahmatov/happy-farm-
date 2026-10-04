import type { DatabaseSync } from 'node:sqlite';
import { randomBytes } from 'node:crypto';
import {
  CROP_BY_ID, CROPS, PLOT_UNLOCK_PRICE, START_COINS, START_PLOTS, STEAL_MAX_SHARE,
  STEAL_SLICE, TOTAL_PLOTS, levelForXp,
} from './catalog.ts';

export class GameError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

interface UserRow { id: number; name: string; token: string; coins: number; xp: number; unlocked_plots: number }
interface PlotRow { idx: number; crop_id: string | null; planted_at: number | null; stolen_share: number }

export class Game {
  private db: DatabaseSync;
  private now: () => number;

  constructor(db: DatabaseSync, now: () => number = () => Math.floor(Date.now() / 1000)) {
    this.db = db;
    this.now = now;
  }

  register(name: string) {
    name = name.trim();
    if (name.length < 2 || name.length > 20) throw new GameError(400, 'name must be 2-20 chars');
    if (this.db.prepare('SELECT 1 FROM users WHERE name = ?').get(name)) throw new GameError(409, 'name taken');
    const token = randomBytes(24).toString('hex');
    const { lastInsertRowid } = this.db
      .prepare('INSERT INTO users (name, token, coins, unlocked_plots) VALUES (?, ?, ?, ?)')
      .run(name, token, START_COINS, START_PLOTS);
    const ins = this.db.prepare('INSERT INTO plots (user_id, idx) VALUES (?, ?)');
    for (let i = 0; i < TOTAL_PLOTS; i++) ins.run(lastInsertRowid, i);
    return { token, farm: this.farm(Number(lastInsertRowid)) };
  }

  authenticate(token: string | undefined): number {
    const row = token && (this.db.prepare('SELECT id FROM users WHERE token = ?').get(token) as { id: number } | undefined);
    if (!row) throw new GameError(401, 'unauthorized');
    return row.id;
  }

  private user(id: number): UserRow {
    const u = this.db.prepare('SELECT * FROM users WHERE id = ?').get(id) as UserRow | undefined;
    if (!u) throw new GameError(404, 'user not found');
    return u;
  }

  private plot(userId: number, idx: number): PlotRow {
    const p = this.db.prepare('SELECT idx, crop_id, planted_at, stolen_share FROM plots WHERE user_id = ? AND idx = ?')
      .get(userId, idx) as PlotRow | undefined;
    if (!p) throw new GameError(400, 'bad plot');
    return p;
  }

  private ready(p: PlotRow): boolean {
    if (!p.crop_id || p.planted_at == null) return false;
    return this.now() >= p.planted_at + CROP_BY_ID.get(p.crop_id)!.growSeconds;
  }

  farm(userId: number) {
    const u = this.user(userId);
    const plots = (this.db.prepare('SELECT idx, crop_id, planted_at, stolen_share FROM plots WHERE user_id = ? ORDER BY idx')
      .all(userId) as unknown as PlotRow[]).map((p) => ({
        index: p.idx,
        unlocked: p.idx < u.unlocked_plots,
        cropId: p.crop_id,
        plantedAt: p.planted_at,
        readyAt: p.crop_id ? p.planted_at! + CROP_BY_ID.get(p.crop_id)!.growSeconds : null,
        ready: this.ready(p),
        stolenShare: p.stolen_share,
      }));
    return {
      id: u.id, name: u.name, coins: u.coins, xp: u.xp, level: levelForXp(u.xp), plots,
      plotUnlockPrice: PLOT_UNLOCK_PRICE, serverTime: this.now(),
    };
  }

  catalog() {
    return CROPS;
  }

  plant(userId: number, idx: number, cropId: string) {
    const u = this.user(userId);
    const crop = CROP_BY_ID.get(cropId);
    if (!crop) throw new GameError(400, 'unknown crop');
    if (levelForXp(u.xp) < crop.unlockLevel) throw new GameError(403, 'level too low');
    if (idx >= u.unlocked_plots) throw new GameError(403, 'plot locked');
    if (this.plot(userId, idx).crop_id) throw new GameError(409, 'plot busy');
    if (u.coins < crop.seedPrice) throw new GameError(402, 'not enough coins');
    this.db.prepare('UPDATE users SET coins = coins - ? WHERE id = ?').run(crop.seedPrice, userId);
    this.db.prepare('UPDATE plots SET crop_id = ?, planted_at = ?, stolen_share = 0 WHERE user_id = ? AND idx = ?')
      .run(cropId, this.now(), userId, idx);
    return this.farm(userId);
  }

  harvest(userId: number, idx: number) {
    const u = this.user(userId);
    const p = this.plot(userId, idx);
    if (!p.crop_id) throw new GameError(409, 'nothing planted');
    if (!this.ready(p)) throw new GameError(409, 'not ready');
    const crop = CROP_BY_ID.get(p.crop_id)!;
    const remaining = Math.floor(crop.yieldCount * (1 - p.stolen_share));
    const earned = remaining * crop.sellPrice;
    this.db.prepare('UPDATE users SET coins = coins + ?, xp = xp + ? WHERE id = ?').run(earned, crop.xp, userId);
    this.db.prepare('UPDATE plots SET crop_id = NULL, planted_at = NULL, stolen_share = 0 WHERE user_id = ? AND idx = ?')
      .run(userId, idx);
    this.db.prepare('DELETE FROM steals WHERE plot_user_id = ? AND plot_idx = ?').run(userId, idx);
    return { earned, xp: crop.xp, farm: this.farm(userId), levelUp: levelForXp(u.xp + crop.xp) > levelForXp(u.xp) };
  }

  steal(thiefId: number, ownerId: number, idx: number) {
    if (thiefId === ownerId) throw new GameError(400, 'cannot steal from yourself');
    if (!this.areFriends(thiefId, ownerId)) throw new GameError(403, 'not friends');
    const p = this.plot(ownerId, idx);
    if (!p.crop_id || !this.ready(p)) throw new GameError(409, 'nothing to steal');
    const already = this.db.prepare('SELECT 1 FROM steals WHERE plot_user_id = ? AND plot_idx = ? AND planted_at = ? AND thief_id = ?')
      .get(ownerId, idx, p.planted_at, thiefId);
    if (already) throw new GameError(409, 'already stolen from this plot');
    if (p.stolen_share + STEAL_SLICE > STEAL_MAX_SHARE + 1e-9) throw new GameError(409, 'plot picked clean');
    const crop = CROP_BY_ID.get(p.crop_id)!;
    const amount = Math.max(1, Math.floor(crop.yieldCount * STEAL_SLICE));
    const earned = amount * crop.sellPrice;
    this.db.prepare('UPDATE plots SET stolen_share = stolen_share + ? WHERE user_id = ? AND idx = ?').run(STEAL_SLICE, ownerId, idx);
    this.db.prepare('INSERT INTO steals VALUES (?, ?, ?, ?)').run(ownerId, idx, p.planted_at, thiefId);
    const xp = Math.max(1, Math.floor(crop.xp / 5));
    this.db.prepare('UPDATE users SET coins = coins + ?, xp = xp + ? WHERE id = ?').run(earned, xp, thiefId);
    return { amount, earned, xp, farm: this.farm(thiefId) };
  }

  unlockPlot(userId: number) {
    const u = this.user(userId);
    if (u.unlocked_plots >= TOTAL_PLOTS) throw new GameError(409, 'all plots unlocked');
    if (u.coins < PLOT_UNLOCK_PRICE) throw new GameError(402, 'not enough coins');
    this.db.prepare('UPDATE users SET coins = coins - ?, unlocked_plots = unlocked_plots + 1 WHERE id = ?')
      .run(PLOT_UNLOCK_PRICE, userId);
    return this.farm(userId);
  }

  areFriends(a: number, b: number): boolean {
    return !!this.db.prepare('SELECT 1 FROM friends WHERE user_id = ? AND friend_id = ?').get(a, b);
  }

  addFriend(userId: number, friendName: string) {
    const f = this.db.prepare('SELECT id FROM users WHERE name = ?').get(friendName) as { id: number } | undefined;
    if (!f) throw new GameError(404, 'user not found');
    if (f.id === userId) throw new GameError(400, 'cannot befriend yourself');
    const ins = this.db.prepare('INSERT OR IGNORE INTO friends VALUES (?, ?)');
    ins.run(userId, f.id); // friendship is mutual, as in VK
    ins.run(f.id, userId);
    return this.friends(userId);
  }

  friends(userId: number) {
    return this.db.prepare(
      'SELECT u.id, u.name, u.xp FROM friends f JOIN users u ON u.id = f.friend_id WHERE f.user_id = ? ORDER BY u.name',
    ).all(userId).map((r: any) => ({ id: r.id, name: r.name, level: levelForXp(r.xp) }));
  }

  friendFarm(userId: number, friendId: number) {
    if (!this.areFriends(userId, friendId)) throw new GameError(403, 'not friends');
    return this.farm(friendId);
  }
}
