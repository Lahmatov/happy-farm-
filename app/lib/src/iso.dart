import 'dart:math' as math;
import 'dart:ui';

/// Isometric scene geometry, in "sprite pixels" (scale 1 = the 128x128 sprite canvases).
///
/// Every plot/pen sprite is a 128x128 canvas whose 2:1 tile diamond is centred at
/// ([anchorX], [anchorY]); layers (soil, crop, pen, animal) are drawn at the same rect.
const spriteCanvas = 128.0;
const anchorX = 64.0;
const anchorY = 88.0;
const tileHalfW = 62.0;
const tileHalfH = 31.0;

const plotCols = 4;
const plotRows = 6;
const animalSlots = 4;

/// Isometric cell to the centre of its tile diamond.
Offset cellCenter(double col, double row) => Offset((col - row) * tileHalfW, (col + row) * tileHalfH);

({int col, int row}) plotCell(int index) => (col: index % plotCols, row: index ~/ plotCols);

/// Pens stand in one horizontal row just below the field. Cells with the same col+row share a
/// screen y, and neighbours are a full tile width apart, so no animal or bubble hides another.
({int col, int row}) penCell(int slot) => (col: 3 + slot, row: 6 - slot);

class DecorSpot {
  final String sprite;
  // Where the sprite touches the ground, in scene units.
  final double x;
  final double y;
  final double width;
  final double height;
  // That ground point inside the sprite's own width x height.
  final double baseX;
  final double baseY;
  const DecorSpot(this.sprite, this.x, this.y, this.width, this.height, this.baseX, this.baseY);

  Rect get rect => Rect.fromLTWH(x - baseX, y - baseY, width, height);
}

const _decorSizes = {
  'decor_tree': (128.0, 160.0, 64.0, 146.0),
  'decor_bush': (80.0, 60.0, 40.0, 50.0),
  'decor_flowers': (66.0, 56.0, 33.0, 52.0),
};

DecorSpot _spot(String sprite, double x, double y) {
  final s = _decorSizes[sprite]!;
  return DecorSpot(sprite, x, y, s.$1, s.$2, s.$3, s.$4);
}

/// Scenery around the field, generated once and deterministically (same on every launch).
/// Only what is on screen is ever drawn, so over-generating around the field is cheap.
List<DecorSpot> _buildDecor() {
  final field = IsoLayout.fieldBounds.inflate(24);
  final barn = const DecorSpot('decor_barn', -190, -70, 180, 160, 90, 150);
  final spots = <DecorSpot>[barn];
  final rnd = math.Random(11);
  const stepX = 135.0, stepY = 105.0;
  for (var gy = -760.0; gy < 1000; gy += stepY) {
    for (var gx = -560.0; gx < 440; gx += stepX) {
      if (rnd.nextDouble() < 0.28) continue; // leave gaps so it does not look like a grid
      final r = rnd.nextDouble();
      final kind = r < 0.22 ? 'decor_tree' : r < 0.5 ? 'decor_bush' : 'decor_flowers';
      final spot = _spot(kind, gx + (rnd.nextDouble() - 0.5) * 70, gy + (rnd.nextDouble() - 0.5) * 50);
      if (spot.rect.overlaps(field) || spot.rect.overlaps(barn.rect.inflate(8))) continue;
      spots.add(spot);
    }
  }
  return spots;
}

/// Maps scene units to the screen: uniform scale plus an offset, fitted and centred.
class IsoLayout {
  final double scale;
  final Offset origin; // screen position of scene (0, 0)

  const IsoLayout._(this.scale, this.origin);

  /// Plots and pens only. The scale is fitted to this, so scenery never shrinks the field.
  static final Rect fieldBounds = _computeBounds();

  static Rect _computeBounds() {
    Rect? r;
    void add(Rect x) => r = r == null ? x : r!.expandToInclude(x);
    for (var i = 0; i < plotCols * plotRows; i++) {
      final c = plotCell(i);
      add(_spriteRect(cellCenter(c.col.toDouble(), c.row.toDouble())));
    }
    for (var s = 0; s < animalSlots; s++) {
      final c = penCell(s);
      add(_spriteRect(cellCenter(c.col.toDouble(), c.row.toDouble())));
    }
    return r!;
  }

  static Rect _spriteRect(Offset center) =>
      Rect.fromLTWH(center.dx - anchorX, center.dy - anchorY, spriteCanvas, spriteCanvas);

  /// Fits the field into [width] x [height], centred. Never zero or negative.
  factory IsoLayout.fit(double width, double height) {
    final b = fieldBounds;
    final scale = math.max(0.01, math.min(width / b.width, height / b.height));
    final origin = Offset(
      (width - b.width * scale) / 2 - b.left * scale,
      (height - b.height * scale) / 2 - b.top * scale,
    );
    return IsoLayout._(scale, origin);
  }

  Offset toScreen(Offset scene) => origin + scene * scale;

  Offset plotCenter(int index) {
    final c = plotCell(index);
    return toScreen(cellCenter(c.col.toDouble(), c.row.toDouble()));
  }

  Offset penCenter(int slot) {
    final c = penCell(slot);
    return toScreen(cellCenter(c.col.toDouble(), c.row.toDouble()));
  }
}

final List<DecorSpot> decor = _buildDecor();
