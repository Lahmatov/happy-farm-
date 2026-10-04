import { createApp } from './app.ts';
import { openDb } from './db.ts';
import { Game } from './game.ts';

const port = Number(process.env.PORT ?? 3000);
createApp(new Game(openDb(process.env.DB_PATH ?? 'farm.db'))).listen(port, () => {
  console.log(`Happy Farm server on :${port}`);
});
