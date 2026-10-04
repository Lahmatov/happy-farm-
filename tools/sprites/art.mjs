// Original vector art for Happy Farm, in the spirit of the old isometric VK farm games:
// saturated flat colours, thick dark outlines, 2:1 isometric tiles.
// Every plot/pen sprite shares one 128x128 canvas whose tile diamond is centred at (64, 88),
// so layers (soil, crop, pen, animal) stack by simply drawing them at the same rect.

export const INK = '#3d2a12';
export const TILE_W = 128;
export const TILE_H = 64;
export const CX = 64;
export const CY = 88;

const f = (n) => Number(n.toFixed(2));
export const svg = (w, h, body, defs = '') =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">` +
  `<defs>${defs}</defs>${body}</svg>`;

export function diamond(cx, cy, w, h) {
  return `${f(cx)},${f(cy - h / 2)} ${f(cx + w / 2)},${f(cy)} ${f(cx)},${f(cy + h / 2)} ${f(cx - w / 2)},${f(cy)}`;
}

/** An isometric slab: top diamond plus two visible side faces of the given depth. */
export function slab(cx, cy, w, h, depth, top, left, right, stroke = INK, sw = 3) {
  const t = diamond(cx, cy, w, h);
  return (
    `<polygon points="${f(cx - w / 2)},${f(cy)} ${f(cx)},${f(cy + h / 2)} ${f(cx)},${f(cy + h / 2 + depth)} ${f(cx - w / 2)},${f(cy + depth)}" fill="${left}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>` +
    `<polygon points="${f(cx + w / 2)},${f(cy)} ${f(cx)},${f(cy + h / 2)} ${f(cx)},${f(cy + h / 2 + depth)} ${f(cx + w / 2)},${f(cy + depth)}" fill="${right}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>` +
    `<polygon points="${t}" fill="${top}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`
  );
}

const ellipse = (cx, cy, rx, ry, fill, sw = 2.5) =>
  `<ellipse cx="${f(cx)}" cy="${f(cy)}" rx="${f(rx)}" ry="${f(ry)}" fill="${fill}" stroke="${INK}" stroke-width="${sw}"/>`;
const path = (d, fill, sw = 2.5, extra = '') =>
  `<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;

// ---------------------------------------------------------------- soil

const soilDefs = `
  <linearGradient id="soilTop" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#b57a43"/><stop offset="1" stop-color="#93602d"/>
  </linearGradient>
  <linearGradient id="soilWet" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#7d4c24"/><stop offset="1" stop-color="#623a1b"/>
  </linearGradient>`;

/** Isometric tile coords (u, v in -0.5..0.5) to canvas coords. */
export const iso = (u, v) => [CX + (u - v) * (TILE_W / 2), CY + (u + v) * (TILE_H / 2)];

export function soil(kind) {
  const wet = kind === 'wet';
  const top = wet ? 'url(#soilWet)' : 'url(#soilTop)';
  const W = TILE_W - 4, H = TILE_H - 2;
  let body = slab(CX, CY, W, H, 10, top, wet ? '#5a3719' : '#6b4423', wet ? '#472c13' : '#563619');
  const clip = `<clipPath id="tclip"><polygon points="${diamond(CX, CY, W, H)}"/></clipPath>`;
  // Furrows: lines of constant v running along u. Dark groove, light ridge beside it.
  let rows = '';
  for (const v of [-0.34, -0.17, 0, 0.17, 0.34]) {
    const [x1, y1] = iso(-0.6, v), [x2, y2] = iso(0.6, v);
    rows += `<line x1="${f(x1)}" y1="${f(y1)}" x2="${f(x2)}" y2="${f(y2)}" stroke="${wet ? '#3b240f' : '#5a3818'}" stroke-width="4.2" stroke-linecap="round"/>`;
    const [a1, b1] = iso(-0.6, v - 0.055), [a2, b2] = iso(0.6, v - 0.055);
    rows += `<line x1="${f(a1)}" y1="${f(b1)}" x2="${f(a2)}" y2="${f(b2)}" stroke="${wet ? '#8a5a30' : '#c98d55'}" stroke-width="2" stroke-linecap="round" opacity="0.8"/>`;
  }
  // A few crumbs so the soil is not flat.
  let crumbs = '';
  for (const [u, v] of [[-0.38, -0.08], [0.22, 0.26], [0.34, -0.3], [-0.12, 0.38], [0.05, -0.4], [-0.4, 0.3]]) {
    const [x, y] = iso(u, v);
    crumbs += `<ellipse cx="${f(x)}" cy="${f(y)}" rx="2.4" ry="1.3" fill="${wet ? '#4a2e15' : '#b57a45'}" opacity="0.9"/>`;
  }
  body += `<g clip-path="url(#tclip)">${rows}${crumbs}</g>`;
  body += `<polygon points="${diamond(CX, CY, W, H)}" fill="none" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  // Light rim on the two upper edges.
  body += `<polyline points="${f(CX - W / 2 + 3)},${f(CY)} ${f(CX)},${f(CY - H / 2 + 2)} ${f(CX + W / 2 - 3)},${f(CY)}" fill="none" stroke="${wet ? '#7a4a22' : '#d9a066'}" stroke-width="1.6" stroke-linecap="round" opacity="0.8"/>`;
  return svg(128, 128, body, soilDefs + clip);
}

function grassTile(withSign) {
  const defs = `<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fbf3a"/><stop offset="1" stop-color="#68a928"/></linearGradient>`;
  let body = slab(CX, CY, TILE_W - 4, TILE_H - 2, 9, 'url(#g)', '#4f8f22', '#437a1d');
  const tufts = [[-0.3, -0.1], [0.25, 0.2], [0.05, 0.32], [0.34, -0.22], [-0.2, 0.28]];
  for (const [u, v] of tufts) {
    const [x, y] = iso(u, v);
    body += path(`M${x - 5},${y + 3} L${x - 3},${y - 6} L${x},${y + 1} L${x + 3},${y - 7} L${x + 5},${y + 3} Z`, '#4f9a1e', 1.8);
  }
  const [sx, sy] = iso(0.28, 0.1);
  body += ellipse(sx, sy, 6, 3.4, '#b9b9b9', 2);
  if (withSign) {
    body += `<rect x="${CX - 3}" y="${CY - 34}" width="6" height="30" rx="2" fill="#9a6a33" stroke="${INK}" stroke-width="2.5"/>`;
    body += `<rect x="${CX - 18}" y="${CY - 50}" width="36" height="22" rx="4" fill="#d9a05b" stroke="${INK}" stroke-width="2.5"/>`;
    body += `<path d="M${CX - 5},${CY - 40} v-4 a5,5 0 0 1 10,0 v4" fill="none" stroke="${INK}" stroke-width="2.6" stroke-linecap="round"/>`;
    body += `<rect x="${CX - 8}" y="${CY - 40}" width="16" height="11" rx="2.5" fill="#f2c230" stroke="${INK}" stroke-width="2.2"/>`;
    body += `<circle cx="${CX}" cy="${CY - 34.5}" r="1.8" fill="${INK}"/>`;
  }
  return svg(128, 128, body, defs);
}

export const lockedSoil = () => grassTile(false);
export const nextSoil = () => grassTile(true);

// ---------------------------------------------------------------- plants

const leaf = (ang, len, wid, fill, sw = 2) =>
  `<g transform="rotate(${ang})"><path d="M0,0 C${f(len * 0.3)},${-wid} ${f(len * 0.75)},${-wid} ${len},0 C${f(len * 0.75)},${wid} ${f(len * 0.3)},${wid} 0,0Z" fill="${fill}" stroke="${INK}" stroke-width="${sw}" stroke-linejoin="round"/>` +
  `<path d="M${f(len * 0.1)},0 L${f(len * 0.8)},0" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.2" stroke-linecap="round"/></g>`;

const shadow = (rx = 12) => `<ellipse cx="0" cy="1" rx="${rx}" ry="${f(rx * 0.45)}" fill="#2b1a08" opacity="0.28"/>`;

// Each drawer paints one plant with its base at (0,0), growing towards negative y.
// `st` is the growth stage 0..3 (3 = ripe).
const PLANTS = {
  radish(st) {
    const G = '#4cae2f', G2 = '#6cc83f';
    const k = [0.55, 0.8, 1, 1.1][st];
    let b = shadow(11 * k);
    if (st >= 2) b += ellipse(0, -3 * k, 7 * k, 7.5 * k, st === 3 ? '#e0344a' : '#c9788a');
    if (st === 3) b += `<path d="M-3.5,-6 q3,-3 7,0" stroke="#ffd0d6" stroke-width="2" fill="none" stroke-linecap="round"/>`;
    const L = 22 * k, W = 6 * k;
    b += `<g transform="translate(0,${f(-4 * k)})">${leaf(-150, L * 0.9, W, G)}${leaf(-30, L * 0.9, W, G)}${leaf(-105, L, W, G2)}${leaf(-75, L, W, G2)}${leaf(-90, L * 1.15, W * 1.1, G2)}</g>`;
    return b;
  },
  wheat(st) {
    const k = [0.5, 0.75, 0.95, 1][st];
    const stalk = st === 3 ? '#e1b43a' : st === 2 ? '#9ec63a' : '#5db52e';
    let b = shadow(12);
    for (const dx of [-8, -3, 2, 7, 11]) {
      const h = (30 + ((dx * 7) % 5)) * k;
      const lean = dx * 0.5;
      b += `<path d="M${dx},0 Q${dx + lean * 0.4},${-h * 0.6} ${dx + lean},${-h}" fill="none" stroke="${INK}" stroke-width="4" stroke-linecap="round"/>`;
      b += `<path d="M${dx},0 Q${dx + lean * 0.4},${-h * 0.6} ${dx + lean},${-h}" fill="none" stroke="${stalk}" stroke-width="2" stroke-linecap="round"/>`;
      if (st >= 2) {
        const ear = st === 3 ? '#f2c94c' : '#b8d54a';
        for (let i = 0; i < 4; i++) {
          const y = -h - i * 4.4 + 1;
          b += `<ellipse cx="${f(dx + lean - 2.6)}" cy="${f(y + 2)}" rx="2.4" ry="3.4" transform="rotate(-25 ${f(dx + lean - 2.6)} ${f(y + 2)})" fill="${ear}" stroke="${INK}" stroke-width="1.3"/>`;
          b += `<ellipse cx="${f(dx + lean + 2.6)}" cy="${f(y + 2)}" rx="2.4" ry="3.4" transform="rotate(25 ${f(dx + lean + 2.6)} ${f(y + 2)})" fill="${ear}" stroke="${INK}" stroke-width="1.3"/>`;
        }
        b += `<ellipse cx="${f(dx + lean)}" cy="${f(-h - 17)}" rx="2.4" ry="3.6" fill="${ear}" stroke="${INK}" stroke-width="1.3"/>`;
      } else {
        b += leaf(-50, 10 * k, 3, '#6cc83f', 1.5).replace('<g', `<g transform="translate(${dx},${f(-h * 0.5)})" `) ;
      }
    }
    return b;
  },
  carrot(st) {
    const k = [0.5, 0.75, 1, 1.1][st];
    let b = shadow(11 * k);
    if (st >= 2) {
      b += `<path d="M-5,-2 Q0,-9 5,-2 Q3,4 0,5 Q-3,4 -5,-2Z" fill="${st === 3 ? '#ff8a1f' : '#e8a35f'}" stroke="${INK}" stroke-width="2"/>`;
      if (st === 3) b += `<path d="M-2.5,-3 q2.5,-2.5 5,0" stroke="#ffd29a" stroke-width="1.6" fill="none" stroke-linecap="round"/>`;
    }
    const G = '#3fae3a', G2 = '#62cb4a';
    const L = 26 * k, W = 3.2 * k;
    b += `<g transform="translate(0,${f(-4 * k)})">${[-125, -108, -90, -72, -55].map((a, i) => leaf(a, L * (1 - Math.abs(i - 2) * 0.1), W, i % 2 ? G : G2, 1.8)).join('')}${leaf(-140, L * 0.7, W, G, 1.6)}${leaf(-40, L * 0.7, W, G, 1.6)}</g>`;
    return b;
  },
  strawberry(st) {
    const k = [0.5, 0.75, 0.95, 1][st];
    let b = shadow(13 * k);
    const G = '#3da53a', G2 = '#5dc24a';
    const trefoil = (x, y, s, ang) =>
      `<g transform="translate(${x},${y}) scale(${s})">${leaf(ang - 35, 15, 6.5, G, 2)}${leaf(ang + 35, 15, 6.5, G, 2)}${leaf(ang, 17, 7, G2, 2)}</g>`;
    b += trefoil(-8 * k, -2, k, -150) + trefoil(8 * k, -2, k, -30) + trefoil(0, -6 * k, k * 1.1, -90);
    if (st === 2) {
      for (const [x, y] of [[-8, -14], [7, -10], [1, -20]]) {
        b += `<g transform="translate(${x * k},${y * k})">${[0, 72, 144, 216, 288].map((a) => `<ellipse cx="0" cy="-3" rx="2.2" ry="3" transform="rotate(${a})" fill="#fff" stroke="${INK}" stroke-width="1.1"/>`).join('')}<circle r="1.8" fill="#ffd54a" stroke="${INK}" stroke-width="0.8"/></g>`;
      }
    }
    if (st === 3) {
      for (const [x, y] of [[-10, -4], [9, -2], [0, -8], [-3, 2]]) {
        const bx = x * k, by = y * k;
        b += `<path d="M${f(bx - 5.5)},${f(by - 5)} Q${f(bx)},${f(by - 8)} ${f(bx + 5.5)},${f(by - 5)} Q${f(bx + 4.5)},${f(by + 5)} ${f(bx)},${f(by + 8)} Q${f(bx - 4.5)},${f(by + 5)} ${f(bx - 5.5)},${f(by - 5)}Z" fill="#e8283c" stroke="${INK}" stroke-width="2"/>`;
        for (const [dx, dy] of [[-2.5, -2], [2.5, -1], [0, 2], [-1.5, 4.5], [2, 4]]) b += `<ellipse cx="${f(bx + dx)}" cy="${f(by + dy)}" rx="0.8" ry="1.1" fill="#ffe27a"/>`;
        b += `<path d="M${f(bx - 4)},${f(by - 5.5)} l4,-3 l4,3 l-2,0 l-2,-1.5 l-2,1.5Z" fill="#3da53a" stroke="${INK}" stroke-width="1.2"/>`;
        b += `<ellipse cx="${f(bx - 2.5)}" cy="${f(by - 2.5)}" rx="1.6" ry="1" fill="#ff9aa6" opacity="0.8"/>`;
      }
    }
    return b;
  },
  corn(st) {
    const k = [0.5, 0.72, 0.92, 1][st];
    let b = shadow(12);
    const G = '#3fa534', G2 = '#5fc345';
    const h = 52 * k;
    b += `<path d="M0,0 L0,${-h}" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M0,0 L0,${-h}" stroke="#7bc94a" stroke-width="3" stroke-linecap="round"/>`;
    for (const [y, a, l] of [[0.15, -160, 26], [0.2, -20, 26], [0.45, -150, 28], [0.5, -30, 28], [0.75, -140, 22], [0.8, -40, 22]]) {
      b += `<g transform="translate(0,${f(-h * y)})">${leaf(a + (a < -90 ? 0 : 0), l * k, 5 * k + 1, y > 0.6 ? G2 : G, 2)}</g>`;
    }
    if (st >= 2) {
      const cob = st === 3 ? '#ffd23a' : '#d9d96a';
      b += `<g transform="translate(9,${f(-h * 0.46)}) rotate(16) scale(1.35)"><path d="M-5,2 Q-6,-16 0,-19 Q6,-16 5,2 Q0,6 -5,2Z" fill="${cob}" stroke="${INK}" stroke-width="2"/>` +
        `<path d="M-5,2 Q-9,-8 -2,-12 L0,-2Z" fill="#4fb43c" stroke="${INK}" stroke-width="1.8"/><path d="M5,2 Q9,-8 2,-12 L0,-2Z" fill="#62c94a" stroke="${INK}" stroke-width="1.8"/>` +
        (st === 3 ? [-8, -12, -16].map((y) => `<line x1="-2.5" y1="${y}" x2="2.5" y2="${y}" stroke="#e0a800" stroke-width="1"/>`).join('') : '') + `</g>`;
    }
    if (st === 3) b += `<path d="M0,${-h} l-3,-7 M0,${-h} l0,-9 M0,${-h} l3,-7" stroke="#e8c04a" stroke-width="2" stroke-linecap="round"/>`;
    return b;
  },
};

// Planting spots, back to front so nearer plants overlap farther ones.
const SPOTS = [[-0.0, -0.27], [-0.27, 0.0], [0.27, 0.0], [0.0, 0.27], [0.0, 0.0]];
const CORN_SPOTS = [[-0.12, -0.2], [0.24, 0.0], [-0.22, 0.14]]; // stalks are big, so fewer

export function crop(id, stage) {
  const spots = (id === 'corn' ? CORN_SPOTS : SPOTS).map(([u, v]) => iso(u, v)).sort((a, b) => a[1] - b[1]);
  const scale = [1.0, 0.92, 0.9, 0.92][stage];
  const body = spots.map(([x, y]) => `<g transform="translate(${f(x)},${f(y + 2)}) scale(${scale})">${PLANTS[id](stage)}</g>`).join('');
  return svg(128, 128, body);
}

export const CROP_IDS = Object.keys(PLANTS);

// ---------------------------------------------------------------- pens and animals

export function pen() {
  const W = TILE_W - 4, H = TILE_H - 2;
  const defs = `<linearGradient id="straw" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1cf72"/><stop offset="1" stop-color="#dcb256"/></linearGradient>`;
  let b = slab(CX, CY, W, H, 10, 'url(#straw)', '#a9772f', '#8e6124');
  // straw strokes
  const clip = `<clipPath id="pclip"><polygon points="${diamond(CX, CY, W, H)}"/></clipPath>`;
  let strokes = '';
  for (const [u, v] of [[-0.3, -0.2], [0.1, -0.3], [0.3, 0.1], [-0.1, 0.25], [0.2, 0.3], [-0.35, 0.15], [0.0, 0.0], [0.38, -0.2]]) {
    const [x, y] = iso(u, v);
    strokes += `<path d="M${f(x - 7)},${f(y)} l7,-2.5 M${f(x - 5)},${f(y + 3)} l8,-1.5" stroke="#b98a35" stroke-width="2" stroke-linecap="round" fill="none"/>`;
  }
  b += `<g clip-path="url(#pclip)">${strokes}</g>`;
  // Fence along the two back edges: posts + two rails.
  const rail = (from, to, y0) => {
    const [x1, y1] = from, [x2, y2] = to;
    return `<line x1="${f(x1)}" y1="${f(y1 - y0)}" x2="${f(x2)}" y2="${f(y2 - y0)}" stroke="${INK}" stroke-width="6.5" stroke-linecap="round"/>` +
      `<line x1="${f(x1)}" y1="${f(y1 - y0)}" x2="${f(x2)}" y2="${f(y2 - y0)}" stroke="#d99a52" stroke-width="3.2" stroke-linecap="round"/>`;
  };
  const top = [CX, CY - H / 2 + 1], left = [CX - W / 2 + 2, CY], right = [CX + W / 2 - 2, CY];
  let fence = rail(left, top, 7) + rail(left, top, 15) + rail(top, right, 7) + rail(top, right, 15);
  const post = ([x, y]) => `<rect x="${f(x - 3.2)}" y="${f(y - 21)}" width="6.4" height="23" rx="2" fill="#c98842" stroke="${INK}" stroke-width="2.4"/>`;
  const mid = (a, b2) => [(a[0] + b2[0]) / 2, (a[1] + b2[1]) / 2];
  fence += post(left) + post(mid(left, top)) + post(top) + post(mid(top, right)) + post(right);
  return svg(128, 128, b + fence, defs + clip);
}

export function chicken() {
  let b = `<ellipse cx="64" cy="94" rx="20" ry="7" fill="#2b1a08" opacity="0.25"/>`;
  // legs
  b += `<path d="M57,88 v8 M71,88 v8" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M57,88 v8 M71,88 v8" stroke="#ff9a1f" stroke-width="2.4" stroke-linecap="round"/>`;
  b += `<path d="M52,97 h6 M66,97 h6" stroke="#ff9a1f" stroke-width="3" stroke-linecap="round"/>`;
  // tail
  b += path('M82,66 Q96,48 88,60 Q100,56 86,72 Q96,66 84,78Z', '#f4f0e6');
  // body
  b += ellipse(64, 72, 24, 21, '#fffdf5', 3);
  b += `<path d="M56,66 Q64,60 72,66" stroke="#ffffff" stroke-opacity="0.9" stroke-width="3" fill="none" stroke-linecap="round"/>`;
  // wing
  b += path('M66,68 Q82,66 80,80 Q70,86 62,78Z', '#f1e3c3', 2.4);
  // head
  b += ellipse(46, 52, 13, 12.5, '#fffdf5', 3);
  // comb
  b += path('M38,42 Q36,32 42,36 Q44,28 49,35 Q54,30 54,41Z', '#e63946', 2.4);
  // wattle & beak
  b += path('M33,56 L24,59 L33,62Z', '#ffb703', 2.2);
  b += path('M38,63 Q36,72 42,70 Q44,66 42,62Z', '#e63946', 2);
  // eye
  b += `<circle cx="42" cy="51" r="3.2" fill="${INK}"/><circle cx="43" cy="50" r="1.1" fill="#fff"/>`;
  b += `<ellipse cx="50" cy="58" rx="3.6" ry="2.2" fill="#ffb3b8" opacity="0.75"/>`;
  return svg(128, 128, b);
}

export function sheep() {
  let b = `<ellipse cx="64" cy="96" rx="30" ry="8" fill="#2b1a08" opacity="0.25"/>`;
  // legs
  for (const x of [48, 58, 72, 82]) b += `<rect x="${x - 3}" y="84" width="6" height="14" rx="2.5" fill="#4a3b36" stroke="${INK}" stroke-width="2.2"/>`;
  // wool: overlapping puffs
  const puffs = [[40, 70, 14], [52, 62, 16], [66, 60, 16], [80, 66, 15], [86, 78, 12], [72, 82, 15], [56, 84, 15], [42, 82, 12], [64, 72, 18]];
  for (const [x, y, r] of puffs) b += `<circle cx="${x}" cy="${y}" r="${r}" fill="#fbf7ee" stroke="${INK}" stroke-width="2.6"/>`;
  for (const [x, y, r] of puffs.slice(0, 8)) b += `<circle cx="${x}" cy="${y}" r="${r - 2.6}" fill="#fbf7ee"/>`;
  for (const [x, y] of [[56, 60], [74, 64], [66, 78], [48, 76]]) b += `<path d="M${x - 4},${y} q4,-4 8,0" stroke="#e5ddcc" stroke-width="2" fill="none" stroke-linecap="round"/>`;
  // head
  b += `<ellipse cx="30" cy="66" rx="5" ry="3" transform="rotate(-30 30 66)" fill="#4a3b36" stroke="${INK}" stroke-width="2"/>`;
  b += `<ellipse cx="46" cy="58" rx="5" ry="3" transform="rotate(30 46 58)" fill="#4a3b36" stroke="${INK}" stroke-width="2"/>`;
  b += ellipse(38, 70, 12.5, 14, '#5b4a44', 2.8);
  b += `<circle cx="34" cy="66" r="3.4" fill="#fff" stroke="${INK}" stroke-width="1.5"/><circle cx="43" cy="66" r="3.4" fill="#fff" stroke="${INK}" stroke-width="1.5"/>`;
  b += `<circle cx="33.5" cy="66.5" r="1.7" fill="${INK}"/><circle cx="43.5" cy="66.5" r="1.7" fill="${INK}"/>`;
  b += `<ellipse cx="38.5" cy="76" rx="4.5" ry="3" fill="#e9b8a8" stroke="${INK}" stroke-width="1.6"/>`;
  b += `<path d="M30,52 Q38,46 46,52 Q44,57 38,56 Q32,57 30,52Z" fill="#fbf7ee" stroke="${INK}" stroke-width="2.2"/>`;
  return svg(128, 128, b);
}

export function cow() {
  let b = `<ellipse cx="64" cy="98" rx="34" ry="9" fill="#2b1a08" opacity="0.25"/>`;
  for (const x of [46, 56, 76, 86]) b += `<rect x="${x - 3.5}" y="82" width="7" height="17" rx="2.5" fill="#fffdf8" stroke="${INK}" stroke-width="2.4"/><rect x="${x - 3.5}" y="94" width="7" height="5" rx="2" fill="#3a2e2a" stroke="${INK}" stroke-width="2"/>`;
  // tail
  b += `<path d="M92,66 Q104,70 100,86" fill="none" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M92,66 Q104,70 100,86" fill="none" stroke="#fffdf8" stroke-width="2.4" stroke-linecap="round"/><ellipse cx="100" cy="88" rx="3.4" ry="4.6" fill="#3a2e2a" stroke="${INK}" stroke-width="1.8"/>`;
  // body
  b += `<path d="M42,62 Q44,50 66,50 Q92,50 94,68 Q96,86 82,88 L52,88 Q40,86 42,62Z" fill="#fffdf8" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  const clip = `<clipPath id="cb"><path d="M42,62 Q44,50 66,50 Q92,50 94,68 Q96,86 82,88 L52,88 Q40,86 42,62Z"/></clipPath>`;
  b += `<g clip-path="url(#cb)"><path d="M58,50 Q72,52 70,64 Q60,70 54,62Z" fill="#3a2e2a"/><path d="M78,66 Q94,64 96,80 Q88,92 76,84Z" fill="#3a2e2a"/><path d="M44,76 Q54,72 58,84 L44,88Z" fill="#3a2e2a"/></g>`;
  b += `<path d="M42,62 Q44,50 66,50 Q92,50 94,68 Q96,86 82,88 L52,88 Q40,86 42,62Z" fill="none" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<ellipse cx="62" cy="86" rx="7" ry="4" fill="#ffb3c0" stroke="${INK}" stroke-width="2"/>`;
  // head
  b += `<path d="M24,52 Q18,48 22,44 Q28,46 30,50Z" fill="#fffdf8" stroke="${INK}" stroke-width="2.2"/>`;
  b += `<path d="M52,52 Q58,48 54,44 Q48,46 46,50Z" fill="#fffdf8" stroke="${INK}" stroke-width="2.2"/>`;
  b += `<path d="M28,50 Q26,40 32,38 Q35,44 34,50Z" fill="#f7e3a1" stroke="${INK}" stroke-width="2.2"/><path d="M48,50 Q50,40 44,38 Q41,44 42,50Z" fill="#f7e3a1" stroke="${INK}" stroke-width="2.2"/>`;
  b += `<path d="M26,56 Q26,46 38,46 Q50,46 50,56 Q52,72 38,76 Q24,72 26,56Z" fill="#fffdf8" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<path d="M26,56 Q26,46 34,47 Q34,56 28,60Z" fill="#3a2e2a"/>`;
  b += `<path d="M26,56 Q26,46 38,46 Q50,46 50,56 Q52,72 38,76 Q24,72 26,56Z" fill="none" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += ellipse(38, 68, 9.5, 6.5, '#ffb3c0', 2.4);
  b += `<ellipse cx="34.5" cy="68" rx="1.5" ry="2" fill="${INK}"/><ellipse cx="41.5" cy="68" rx="1.5" ry="2" fill="${INK}"/>`;
  b += `<circle cx="31.5" cy="57" r="3.2" fill="#fff" stroke="${INK}" stroke-width="1.5"/><circle cx="44.5" cy="57" r="3.2" fill="#fff" stroke="${INK}" stroke-width="1.5"/><circle cx="31.8" cy="57.5" r="1.7" fill="${INK}"/><circle cx="44.2" cy="57.5" r="1.7" fill="${INK}"/>`;
  return svg(128, 128, b, clip);
}

// ---------------------------------------------------------------- product bubbles (ready markers)

function bubble(inner) {
  const b =
    `<path d="M32,6 C16,6 6,16 6,29 C6,42 16,52 32,52 C34,52 36,52 38,51.6 L44,60 L42,49.6 C52,46 58,38 58,29 C58,16 48,6 32,6Z" fill="#ffffff" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>` +
    `<path d="M14,18 Q20,10 30,10" stroke="#dff1ff" stroke-width="3" fill="none" stroke-linecap="round"/>` + inner;
  return svg(64, 64, b);
}

export const bubbles = {
  egg: () => bubble(`<ellipse cx="32" cy="30" rx="10.5" ry="13.5" fill="#fff6dc" stroke="${INK}" stroke-width="2.6"/><path d="M26,24 q2,-5 6,-5" stroke="#fff" stroke-width="2.6" fill="none" stroke-linecap="round"/>`),
  wool: () => bubble(`<circle cx="32" cy="30" r="12.5" fill="#ffd1e0" stroke="${INK}" stroke-width="2.6"/><path d="M22,26 q10,-8 20,0 M21,32 q11,-7 22,1 M24,38 q8,-5 16,0" stroke="#f08fb0" stroke-width="2" fill="none" stroke-linecap="round"/>`),
  milk: () => bubble(`<path d="M27,17 h10 v6 q6,4 6,10 v9 q0,3 -3,3 h-16 q-3,0 -3,-3 v-9 q0,-6 6,-10Z" fill="#f4fbff" stroke="${INK}" stroke-width="2.6" stroke-linejoin="round"/><rect x="26" y="13" width="12" height="6" rx="2" fill="#5db4f0" stroke="${INK}" stroke-width="2.2"/><path d="M25,32 h14 v8 h-14z" fill="#cfe8ff" opacity="0.9"/>`),
  crop: () => bubble(`<path d="M32,40 L32,24" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M32,40 L32,24" stroke="#5dc24a" stroke-width="3" stroke-linecap="round"/><g transform="translate(32,26)">${leaf(-150, 14, 5.5, '#5dc24a', 2)}${leaf(-30, 14, 5.5, '#4cae2f', 2)}</g><path d="M22,42 q10,6 20,0" stroke="${INK}" stroke-width="3" fill="none" stroke-linecap="round"/>`),
};

// ---------------------------------------------------------------- decor and HUD icons

export function tree() {
  let b = `<ellipse cx="64" cy="146" rx="30" ry="9" fill="#2b1a08" opacity="0.25"/>`;
  b += `<path d="M56,146 Q58,120 56,104 L72,104 Q70,120 74,146Z" fill="#9a6633" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<path d="M62,142 Q63,124 62,108" stroke="#c48a4a" stroke-width="3" fill="none" stroke-linecap="round"/>`;
  const blobs = [[64, 40, 30, '#3f9d2e'], [38, 62, 26, '#4aac36'], [90, 62, 26, '#4aac36'], [64, 70, 32, '#55b93f'], [46, 86, 20, '#4aac36'], [84, 88, 20, '#4aac36']];
  for (const [x, y, r, c] of blobs) b += `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}" stroke="${INK}" stroke-width="3.2"/>`;
  for (const [x, y, r, c] of blobs) b += `<circle cx="${x}" cy="${y}" r="${r - 3}" fill="${c}"/>`;
  for (const [x, y] of [[54, 34], [70, 52], [40, 56], [88, 58], [60, 76]]) b += `<ellipse cx="${x}" cy="${y}" rx="9" ry="6" fill="#7bd256" opacity="0.7"/>`;
  for (const [x, y] of [[48, 70], [76, 40], [90, 74], [56, 90]]) b += `<circle cx="${x}" cy="${y}" r="4.4" fill="#e63946" stroke="${INK}" stroke-width="1.8"/><circle cx="${x - 1.3}" cy="${y - 1.3}" r="1.2" fill="#ffb3ba"/>`;
  return svg(128, 160, b);
}

export function bush() {
  let b = `<ellipse cx="40" cy="52" rx="30" ry="6" fill="#2b1a08" opacity="0.25"/>`;
  const blobs = [[22, 38, 17, '#3f9d2e'], [58, 38, 17, '#3f9d2e'], [40, 30, 21, '#4aac36']];
  for (const [x, y, r, c] of blobs) b += `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}" stroke="${INK}" stroke-width="3"/>`;
  for (const [x, y, r, c] of blobs) b += `<circle cx="${x}" cy="${y}" r="${r - 2.8}" fill="${c}"/>`;
  b += `<ellipse cx="34" cy="24" rx="9" ry="5" fill="#7bd256" opacity="0.7"/>`;
  for (const [x, y, c] of [[26, 40, '#ff6fa5'], [50, 34, '#ffd23a'], [40, 44, '#ff6fa5'], [58, 44, '#ffffff']]) b += `<circle cx="${x}" cy="${y}" r="3.4" fill="${c}" stroke="${INK}" stroke-width="1.6"/>`;
  return svg(80, 60, b);
}

export function flowers() {
  let b = '';
  for (const [x, y, c] of [[14, 30, '#ff6fa5'], [34, 20, '#ffd23a'], [52, 32, '#ffffff'], [26, 40, '#ff8a3d']]) {
    b += `<path d="M${x},${y + 6} L${x},${y + 16}" stroke="${INK}" stroke-width="3.4" stroke-linecap="round"/><path d="M${x},${y + 6} L${x},${y + 16}" stroke="#4cae2f" stroke-width="1.6" stroke-linecap="round"/>`;
    for (let a = 0; a < 360; a += 72) b += `<ellipse cx="${x}" cy="${y - 4.4}" rx="3.1" ry="4.4" transform="rotate(${a} ${x} ${y})" fill="${c}" stroke="${INK}" stroke-width="1.5"/>`;
    b += `<circle cx="${x}" cy="${y}" r="3" fill="#ffb300" stroke="${INK}" stroke-width="1.4"/>`;
  }
  return svg(66, 56, b);
}

export function tuft() {
  let b = '';
  for (const [x, a] of [[10, -20], [16, 0], [22, 20]]) b += `<path d="M${x},22 Q${x + a * 0.3},10 ${x + a * 0.5},2 Q${x + 4},12 ${x + 4},22Z" fill="#5fb43a" stroke="#3b7f22" stroke-width="1.6" stroke-linejoin="round"/>`;
  return svg(36, 26, b);
}

export function barn() {
  const defs = `<linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d94a3d"/><stop offset="1" stop-color="#b23a30"/></linearGradient>`;
  let b = `<ellipse cx="90" cy="146" rx="70" ry="11" fill="#2b1a08" opacity="0.25"/>`;
  // right wall (lit) and left wall (shaded)
  b += `<polygon points="30,70 90,100 90,150 30,120" fill="#b53a30" stroke="${INK}" stroke-width="3.4" stroke-linejoin="round"/>`;
  b += `<polygon points="90,100 150,70 150,120 90,150" fill="#d6483c" stroke="${INK}" stroke-width="3.4" stroke-linejoin="round"/>`;
  // boards
  for (let i = 1; i < 6; i++) {
    b += `<line x1="${30 + i * 10}" y1="${70 + i * 5}" x2="${30 + i * 10}" y2="${120 + i * 5}" stroke="#8f2d25" stroke-width="1.6" opacity="0.6"/>`;
    b += `<line x1="${90 + i * 10}" y1="${100 - i * 5}" x2="${90 + i * 10}" y2="${150 - i * 5}" stroke="#a63a30" stroke-width="1.6" opacity="0.6"/>`;
  }
  // door on the right wall
  b += `<polygon points="108,106 134,93 134,130 108,143" fill="#f6f1e4" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<path d="M108,106 L134,130 M134,93 L108,143" stroke="#d6483c" stroke-width="3.2"/>`;
  // window on the left wall
  b += `<polygon points="46,92 72,105 72,122 46,109" fill="#bfe6ff" stroke="${INK}" stroke-width="2.8" stroke-linejoin="round"/><path d="M59,98 v18" stroke="${INK}" stroke-width="2"/>`;
  // roof
  b += `<polygon points="20,70 90,36 90,70 20,70" fill="none"/>`;
  b += `<polygon points="22,72 90,104 90,92 22,60" fill="#7a2a24" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<polygon points="22,60 90,26 158,60 90,92" fill="url(#roof)" stroke="${INK}" stroke-width="3.6" stroke-linejoin="round"/>`;
  b += `<polygon points="158,60 158,72 90,104 90,92" fill="#8f2d25" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
  b += `<line x1="90" y1="26" x2="90" y2="92" stroke="#e8685a" stroke-width="2.2" opacity="0.8"/>`;
  return svg(180, 160, b, defs);
}

export function coin() {
  const defs = `<radialGradient id="cg" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#fff2a8"/><stop offset="0.55" stop-color="#ffcf2e"/><stop offset="1" stop-color="#e09a0c"/></radialGradient>`;
  let b = `<circle cx="24" cy="24" r="20" fill="url(#cg)" stroke="${INK}" stroke-width="3"/><circle cx="24" cy="24" r="13.5" fill="none" stroke="#b9780a" stroke-width="2.2"/>`;
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? 5 : 11, ang = (-90 + i * 36) * Math.PI / 180;
    pts.push(`${f(24 + r * Math.cos(ang))},${f(25 + r * Math.sin(ang))}`);
  }
  b += `<polygon points="${pts.join(' ')}" fill="#e8a30c" stroke="#b9780a" stroke-width="1.6" stroke-linejoin="round"/>`;
  b += `<path d="M10,16 Q14,9 22,8" stroke="#fffbe0" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.9"/>`;
  return svg(48, 48, b, defs);
}

export function star() {
  const defs = `<linearGradient id="sg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9be15d"/><stop offset="1" stop-color="#4cae2f"/></linearGradient>`;
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? 10 : 21, a = (-90 + i * 36) * Math.PI / 180;
    pts.push(`${f(24 + r * Math.cos(a))},${f(25 + r * Math.sin(a))}`);
  }
  return svg(48, 48, `<polygon points="${pts.join(' ')}" fill="url(#sg)" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/><path d="M17,19 L24,8" stroke="#e8ffd0" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>`, defs);
}

export function sparkle() {
  const p = (cx, cy, r) => `M${cx},${cy - r} Q${cx + r * 0.2},${cy - r * 0.2} ${cx + r},${cy} Q${cx + r * 0.2},${cy + r * 0.2} ${cx},${cy + r} Q${cx - r * 0.2},${cy + r * 0.2} ${cx - r},${cy} Q${cx - r * 0.2},${cy - r * 0.2} ${cx},${cy - r}Z`;
  return svg(40, 40, `<path d="${p(20, 20, 16)}" fill="#fff7b0" stroke="#e0a800" stroke-width="2" stroke-linejoin="round"/><path d="${p(32, 9, 6)}" fill="#fff7b0" stroke="#e0a800" stroke-width="1.4"/>`);
}
