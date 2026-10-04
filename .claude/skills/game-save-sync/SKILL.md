---
name: game-save-sync
description: Persisting and syncing farm state between the iPhone client and the server - versioned schemas, migrations, offline handling. Use when touching the DB schema, API payloads, or client-side caching.
---

# Save and sync

Adapted from the `save-systems` skill in [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) (Apache-2.0), rewritten for a server-authoritative farm.

- **The server DB is the save.** The client holds only a cache and the auth token. Never trust a client-supplied farm state.
- **Version the schema.** Add a `schema_version` (SQLite `PRAGMA user_version`) before the first schema change after release; write migrations as ordered pure steps, each tested against a DB built at the previous version. Today the schema is `CREATE TABLE IF NOT EXISTS`, which cannot alter tables, so the first change must introduce migrations.
- **Save data, not objects.** Store ids and numbers (`crop_id`, `planted_at`), not computed state. `ready`, `readyAt` are derived on read from the server clock.
- **Use timestamps, not timers.** Growth is `planted_at + grow_seconds` compared to server time. The client renders from `serverTime` returned with each response, correcting for its own clock offset.
- **Atomic changes.** One request = one DB transaction (coins, xp and plot change together or not at all).
- **Client cache.** Cache the last farm response so the app opens instantly offline; show it read-only with an offline banner, never queue mutations for later replay without idempotency keys.
- **Token storage.** iOS Keychain (`flutter_secure_storage`), not `shared_preferences`.
- **Verify by round trip:** change state, restart the server, fetch, compare. Test loading data created by the previous schema version.
