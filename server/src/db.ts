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
  return db;
}
