import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { openDb } from '../src/db.ts';

test('migrations upgrade a database created before client_id existed, and run once', () => {
  const path = join(mkdtempSync(join(tmpdir(), 'farm-')), 't.db');
  // A v0 database, as shipped before migrations were introduced.
  const old = new DatabaseSync(path);
  old.exec(`CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
    token TEXT NOT NULL UNIQUE, coins INTEGER NOT NULL, xp INTEGER NOT NULL DEFAULT 0, unlocked_plots INTEGER NOT NULL);
    INSERT INTO users (name, token, coins, unlocked_plots) VALUES ('Old', 't', 5, 6);`);
  old.close();

  for (let i = 0; i < 2; i++) { // second open must not re-run the migration
    const db = openDb(path);
    const cols = (db.prepare('PRAGMA table_info(users)').all() as { name: string }[]).map((c) => c.name);
    assert.ok(cols.includes('client_id'));
    assert.equal((db.prepare('SELECT coins FROM users').get() as { coins: number }).coins, 5);
    assert.equal((db.prepare('PRAGMA user_version').get() as { user_version: number }).user_version, 1);
    db.close();
  }
});
