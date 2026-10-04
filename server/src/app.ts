import { createServer, type IncomingMessage, type Server } from 'node:http';
import type { Game } from './game.ts';
import { GameError } from './game.ts';

async function readJson(req: IncomingMessage): Promise<any> {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 1e5) throw new GameError(413, 'body too large');
  }
  try { return raw ? JSON.parse(raw) : {}; } catch { throw new GameError(400, 'bad json'); }
}

const int = (v: unknown, name: string): number => {
  if (typeof v !== 'number' || !Number.isInteger(v)) throw new GameError(400, `${name} must be an integer`);
  return v;
};

export function createApp(game: Game): Server {
  return createServer(async (req, res) => {
    const send = (status: number, body: unknown) => {
      res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(body));
    };
    try {
      const url = new URL(req.url ?? '/', 'http://x');
      const route = `${req.method} ${url.pathname}`;
      const body = req.method === 'POST' ? await readJson(req) : {};
      const auth = () => game.authenticate(req.headers.authorization?.replace(/^Bearer /, ''));

      if (route === 'POST /register') return send(201, game.register(String(body.name ?? '')));
      if (route === 'GET /catalog') return send(200, game.catalog());
      if (route === 'GET /farm') return send(200, game.farm(auth()));
      if (route === 'POST /plant') return send(200, game.plant(auth(), int(body.plot, 'plot'), String(body.cropId)));
      if (route === 'POST /harvest') return send(200, game.harvest(auth(), int(body.plot, 'plot')));
      if (route === 'POST /unlock-plot') return send(200, game.unlockPlot(auth()));
      if (route === 'GET /friends') return send(200, game.friends(auth()));
      if (route === 'POST /friends') return send(200, game.addFriend(auth(), String(body.name ?? '')));
      let m = url.pathname.match(/^\/friends\/(\d+)\/farm$/);
      if (m && req.method === 'GET') return send(200, game.friendFarm(auth(), Number(m[1])));
      m = url.pathname.match(/^\/friends\/(\d+)\/steal$/);
      if (m && req.method === 'POST') return send(200, game.steal(auth(), Number(m[1]), int(body.plot, 'plot')));
      send(404, { error: 'not found' });
    } catch (e) {
      if (e instanceof GameError) return send(e.status, { error: e.message });
      console.error(e);
      send(500, { error: 'internal error' });
    }
  });
}
