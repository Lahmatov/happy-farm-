import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import { createApp } from '../src/app.ts';
import { openDb } from '../src/db.ts';
import { Game } from '../src/game.ts';

test('responses declare UTF-8 so clients decode Cyrillic names correctly', async () => {
  const server = createApp(new Game(openDb(':memory:')));
  await new Promise<void>((r) => server.listen(0, r));
  try {
    const { port } = server.address() as AddressInfo;
    const res = await fetch(`http://localhost:${port}/register`, { method: 'POST', body: JSON.stringify({ name: 'Анна' }) });
    assert.equal(res.status, 201);
    assert.match(res.headers.get('content-type') ?? '', /charset=utf-8/i);
    assert.equal((await res.json()).farm.name, 'Анна');
  } finally {
    server.close();
  }
});
