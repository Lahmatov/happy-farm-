import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openDb } from '../src/db.ts';
import { Game } from '../src/game.ts';

function setup() {
  let t = 1000;
  const db = openDb(':memory:');
  const game = new Game(db, () => t);
  const player = (name: string) => game.authenticate(game.register(name).token);
  const setCoins = (id: number, coins: number, xp = 0) =>
    db.prepare('UPDATE users SET coins = ?, xp = ? WHERE id = ?').run(coins, xp, id);
  return { game, db, player, setCoins, advance: (s: number) => { t += s; } };
}

test('buy a chicken, wait, collect: pays coins and xp, then the timer restarts', () => {
  const { game, player, advance } = setup();
  const a = player('Anna');
  const bought = game.buyAnimal(a, 0, 'chicken');
  assert.equal(bought.coins, 100);
  assert.equal(bought.animals[0].ready, false);
  assert.throws(() => game.collectAnimal(a, 0), /not ready/);
  advance(600);
  const r = game.collectAnimal(a, 0);
  assert.equal(r.earned, 40);
  assert.equal(r.farm.coins, 140);
  assert.equal(r.farm.xp, 8);
  assert.throws(() => game.collectAnimal(a, 0), /not ready/); // no double collect
  advance(600);
  assert.equal(game.collectAnimal(a, 0).farm.coins, 180);
});

test('buy rules: slot range, busy slot, coins, level, unknown kind', () => {
  const { game, player, setCoins } = setup();
  const a = player('Anna');
  assert.throws(() => game.buyAnimal(a, 4, 'chicken'), /bad slot/);
  assert.throws(() => game.buyAnimal(a, -1, 'chicken'), /bad slot/);
  assert.throws(() => game.buyAnimal(a, 0, 'dragon'), /unknown animal/);
  assert.throws(() => game.buyAnimal(a, 0, 'cow'), /level too low/);
  game.buyAnimal(a, 0, 'chicken');
  assert.throws(() => game.buyAnimal(a, 0, 'chicken'), /slot busy/);
  setCoins(a, 50);
  assert.throws(() => game.buyAnimal(a, 1, 'chicken'), /not enough coins/);
  assert.equal(game.farm(a).coins, 50); // a failed purchase takes nothing
});

test('animals are private to their owner', () => {
  const { game, player, advance } = setup();
  const a = player('Anna');
  const b = player('Boris');
  game.buyAnimal(a, 0, 'chicken');
  advance(600);
  assert.throws(() => game.collectAnimal(b, 0), /no animal here/);
  assert.equal(game.farm(b).animals.length, 0);
});

test('every animal pays back its price within a handful of collections', () => {
  const { game } = setup();
  for (const k of game.animalCatalog()) {
    const collections = Math.ceil(k.price / k.value);
    assert.ok(collections >= 2 && collections <= 4, `${k.id}: ${collections}`);
  }
});
