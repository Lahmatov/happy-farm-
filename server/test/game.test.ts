import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openDb } from '../src/db.ts';
import { Game, GameError } from '../src/game.ts';

function setup() {
  let t = 1000;
  const game = new Game(openDb(':memory:'), () => t);
  return { game, advance: (s: number) => { t += s; } };
}
const id = (g: Game, token: string) => g.authenticate(token);

test('plant, wait, harvest pays coins and xp', () => {
  const { game, advance } = setup();
  const a = id(game, game.register('Anna').token);
  game.plant(a, 0, 'radish');
  assert.throws(() => game.harvest(a, 0), /not ready/);
  advance(60);
  const r = game.harvest(a, 0);
  assert.equal(r.earned, 20);
  assert.equal(r.farm.coins, 200 - 10 + 20);
  assert.equal(r.farm.xp, 5);
});

test('cannot plant on locked plot, busy plot, or without coins', () => {
  const { game } = setup();
  const a = id(game, game.register('Anna').token);
  assert.throws(() => game.plant(a, 6, 'radish'), /locked/);
  game.plant(a, 0, 'radish');
  assert.throws(() => game.plant(a, 0, 'radish'), /busy/);
  assert.throws(() => game.plant(a, 1, 'carrot'), /level/);
});

test('stealing needs friendship, once per thief, capped at 50%', () => {
  const { game, advance } = setup();
  const a = id(game, game.register('Anna').token);
  const b = id(game, game.register('Boris').token);
  game.plant(a, 0, 'radish');
  advance(60);
  assert.throws(() => game.steal(b, a, 0), /not friends/);
  game.addFriend(b, 'Anna');
  const s = game.steal(b, a, 0);
  assert.equal(s.amount, 1);
  assert.throws(() => game.steal(b, a, 0), /already stolen/);
  // owner harvests the remainder: 10 * (1 - 0.1) = 9
  assert.equal(game.harvest(a, 0).earned, 18);
});

test('cap on total stolen share', () => {
  const { game, advance } = setup();
  const a = id(game, game.register('Anna').token);
  game.plant(a, 0, 'radish');
  advance(60);
  let stolen = 0;
  for (let i = 0; i < 8; i++) {
    const t = id(game, game.register(`Thief${i}`).token);
    game.addFriend(t, 'Anna');
    try { game.steal(t, a, 0); stolen++; } catch (e) { assert.ok(e instanceof GameError); }
  }
  assert.equal(stolen, 5);
});

test('unlock plot costs coins', () => {
  const { game } = setup();
  const a = id(game, game.register('Anna').token);
  assert.throws(() => game.unlockPlot(a), /not enough coins/);
});

test('farm tells the client the plot unlock price', () => {
  const { game } = setup();
  const a = id(game, game.register('Anna').token);
  assert.equal(game.farm(a).plotUnlockPrice, 500);
});

const CID = 'a'.repeat(32);

test('retrying register with the same clientId returns the same account', () => {
  const { game } = setup();
  const first = game.register('Anna', CID);
  const retry = game.register('Anna', CID);
  assert.equal(retry.token, first.token);
  assert.equal(retry.farm.id, first.farm.id);
});

test('register with another clientId, or none, is still "name taken"', () => {
  const { game } = setup();
  game.register('Anna', CID);
  assert.throws(() => game.register('Anna', 'b'.repeat(32)), /name taken/);
  assert.throws(() => game.register('Anna'), /name taken/);
});

test('a malformed clientId is rejected', () => {
  const { game } = setup();
  assert.throws(() => game.register('Anna', 'short'), /bad clientId/);
});
