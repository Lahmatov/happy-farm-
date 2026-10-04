import { DatabaseSync } from 'node:sqlite';

export function openDb(path: string): DatabaseSync {
  const db = new DatabaseSync(path);
  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      token TEXT NOT NULL UNIQUE,
      coins INTEGER NOT NULL,
      xp INTEGER NOT NULL DEFAULT 0,
      unlocked_plots INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS plots (
      user_id INTEGER NOT NULL REFERENCES users(id),
      idx INTEGER NOT NULL,
      crop_id TEXT,
      planted_at INTEGER,
      stolen_share REAL NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, idx)
    );
    CREATE TABLE IF NOT EXISTS steals (
      plot_user_id INTEGER NOT NULL,
      plot_idx INTEGER NOT NULL,
      planted_at INTEGER NOT NULL,
      thief_id INTEGER NOT NULL,
      PRIMARY KEY (plot_user_id, plot_idx, planted_at, thief_id)
    );
    CREATE TABLE IF NOT EXISTS friends (
      user_id INTEGER NOT NULL REFERENCES users(id),
      friend_id INTEGER NOT NULL REFERENCES users(id),
      PRIMARY KEY (user_id, friend_id)
    );
  `);
  migrate(db);
  return db;
}

// Ordered, append-only. PRAGMA user_version records how many have run, so each
// runs exactly once on any existing database. Never edit a shipped migration.
const MIGRATIONS: string[] = [
  // 1: lets a retried /register (lost reply) return the same account instead of "name taken"
  'ALTER TABLE users ADD COLUMN client_id TEXT',
  // 2: animals. A row exists only once the animal is bought.
  `CREATE TABLE animals (
    user_id INTEGER NOT NULL REFERENCES users(id),
    slot INTEGER NOT NULL,
    kind TEXT NOT NULL,
    last_collected_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, slot)
  )`,
];

function migrate(db: DatabaseSync): void {
  const row = db.prepare('PRAGMA user_version').get() as { user_version: number };
  for (let v = row.user_version; v < MIGRATIONS.length; v++) {
    db.exec('BEGIN');
    try {
      db.exec(MIGRATIONS[v]);
      db.exec(`PRAGMA user_version = ${v + 1}`);
      db.exec('COMMIT');
    } catch (e) {
      db.exec('ROLLBACK');
      throw e;
    }
  }
}
