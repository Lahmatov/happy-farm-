# Sprite pipeline

All game art is original vector art written as code (`art.mjs`) and rendered to transparent
PNGs with headless Chromium. The PNGs in `app/assets/sprites/` are committed, so building the
app does not need Node.

```
export NODE_PATH=$(npm root -g)          # must contain `playwright`
node tools/sprites/build.mjs             # render everything
node tools/sprites/build.mjs crop_corn   # only sprites whose name starts with this
node tools/sprites/preview.mjs app/assets/sprites /tmp/sheet.png 6   # contact sheet to eyeball
```

## Conventions (the Flutter side relies on them)

- Isometric 2:1 tiles. Every plot and pen sprite is a **128x128 canvas** whose tile diamond is
  centred at (64, 88), half-size 62x31. Layers (soil, crop, pen, animal) are drawn at the same
  rect, so they stack without any per-sprite offsets. See `app/lib/src/iso.dart`.
- Rendered at 3x (384 px), displayed at about 0.6x logical scale on a phone.
- Style: saturated flat colours, thick dark outline (`INK`), simple highlight. Keep it consistent.
- Crops have four stages: `crop_<id>_0..2` while growing and `_3` when ripe.
- Adding a sprite: draw it in `art.mjs`, register it in `build.mjs`, add its name to
  `Sprites.names` in `app/lib/src/sprites.dart` (a test decodes every name, so a typo fails).
- Adding a crop or animal also needs the server catalog entry and a client mapping.

Originality: nothing here is traced or copied from the original VK game or from any other game.
