import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'iso.dart';
import 'models.dart';
import 'sprites.dart';

final _paint = Paint()..filterQuality = FilterQuality.medium;

// Reused every frame: render() runs ~60 times a second for each component.
final _fill = Paint();
final _line = Paint()..style = PaintingStyle.stroke;
final _cap = Paint()..strokeCap = StrokeCap.round;

void _drawSprite(ui.Canvas canvas, ui.Image image, Rect dst) {
  canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dst, _paint);
}

/// Base of plots and pens: a sprite canvas whose isometric diamond is the tap target.
abstract class _IsoTile extends PositionComponent with TapCallbacks {
  final FarmGame owner;
  double time = 0;

  _IsoTile(this.owner);

  /// Scale of this tile relative to the 128 px sprite canvas.
  double get unit => size.x / spriteCanvas;

  @override
  void update(double dt) => time += dt;

  /// Only the diamond (slightly enlarged for fingers) is tappable, not the whole canvas.
  /// Crops overhang the neighbours above, and those neighbours must stay tappable.
  @override
  bool containsLocalPoint(Vector2 p) {
    final u = unit;
    final dx = (p.x - anchorX * u).abs() / (tileHalfW * u * 1.08);
    final dy = (p.y - anchorY * u).abs() / (tileHalfH * u * 1.08);
    return dx + dy <= 1;
  }

  Rect get canvasRect => Rect.fromLTWH(0, 0, size.x, size.y);

  /// A bubble hovering at the upper right of the canvas, bobbing gently.
  void drawBubble(ui.Canvas canvas, ui.Image image, {double phase = 0}) {
    final u = unit;
    final bob = math.sin(time * 3 + phase) * 3 * u;
    _drawSprite(canvas, image, Rect.fromLTWH(74 * u, 4 * u + bob, 46 * u, 46 * u));
  }
}

class PlotComponent extends _IsoTile {
  final void Function(int index) onTap;
  Plot plot;
  int serverNow = 0;
  // The first locked plot: the one the next purchase unlocks, so it alone carries the sign.
  bool isNext = false;

  PlotComponent(this.plot, this.onTap, FarmGame owner) : super(owner);

  @override
  void onTapDown(TapDownEvent event) => onTap(plot.index);

  @override
  void render(ui.Canvas canvas) {
    final sp = owner.sprites;
    if (sp == null) return;
    final stage = stageOf(plot, serverNow);
    _drawSprite(
      canvas,
      sp[switch (stage) {
        PlotStage.locked => isNext ? 'soil_next' : 'soil_locked',
        PlotStage.empty => 'soil_dry',
        _ => 'soil_wet',
      }],
      canvasRect,
    );
    final cropId = plot.cropId;
    if (cropId == null || stage == PlotStage.locked || !Sprites.cropIds.contains(cropId)) return;
    _drawSprite(canvas, sp['crop_${cropId}_${Sprites.cropStage(stage, growthProgress(plot, serverNow))}'], canvasRect);
    if (stage == PlotStage.ripe) {
      final u = unit;
      final pulse = 0.75 + 0.25 * math.sin(time * 4 + plot.index);
      final s = 16 * u * pulse;
      _drawSprite(canvas, sp['fx_sparkle'], Rect.fromCenter(center: Offset(40 * u, 56 * u), width: s * 1.6, height: s * 1.6));
      drawBubble(canvas, sp['bubble_crop'], phase: plot.index.toDouble());
    }
  }
}

class AnimalComponent extends _IsoTile {
  final void Function(int slot)? onTap;
  final int slot;
  Animal? animal;
  int serverNow = 0;

  AnimalComponent(this.slot, this.onTap, FarmGame owner) : super(owner);

  @override
  void onTapDown(TapDownEvent event) => onTap?.call(slot);

  @override
  void render(ui.Canvas canvas) {
    final sp = owner.sprites;
    if (sp == null) return;
    _drawSprite(canvas, sp['pen'], canvasRect);
    final a = animal;
    final u = unit;
    if (a == null) {
      // An empty pen invites a purchase.
      final c = Offset(anchorX * u, (anchorY - 8) * u);
      canvas.drawCircle(c, 13 * u, _fill..color = const Color(0xE6FFFFFF));
      canvas.drawCircle(c, 13 * u, _line
        ..color = const Color(0xFF3D2A12)
        ..strokeWidth = 2.2 * u);
      _cap
        ..color = const Color(0xFF3D2A12)
        ..strokeWidth = 3.4 * u;
      canvas.drawLine(c.translate(-6 * u, 0), c.translate(6 * u, 0), _cap);
      canvas.drawLine(c.translate(0, -6 * u), c.translate(0, 6 * u), _cap);
      return;
    }
    if (Sprites.animalIds.contains(a.kind)) _drawSprite(canvas, sp['animal_${a.kind}'], canvasRect);
    if (animalStageOf(a, serverNow) == AnimalStage.ready) {
      drawBubble(canvas, sp[Sprites.productBubble(a.kind)], phase: slot.toDouble());
    } else {
      // Thin progress pill on the front edge of the pen.
      final w = 40 * u, h = 5 * u;
      final r = Rect.fromCenter(center: Offset(anchorX * u, (anchorY + tileHalfH + 8) * u), width: w, height: h);
      final rr = RRect.fromRectAndRadius(r, Radius.circular(h));
      canvas.drawRRect(rr, _fill..color = const Color(0xAA3D2A12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, w * animalProgress(a, serverNow), h), Radius.circular(h)),
        _fill..color = const Color(0xFFFFC21F),
      );
    }
  }
}

class _DecorComponent extends PositionComponent {
  final FarmGame owner;
  final DecorSpot spot;
  _DecorComponent(this.owner, this.spot) : super(priority: spot.y.round());

  @override
  void render(ui.Canvas canvas) {
    final sp = owner.sprites;
    if (sp == null) return;
    _drawSprite(canvas, sp[spot.sprite], Rect.fromLTWH(0, 0, size.x, size.y));
  }
}

class _Background extends PositionComponent {
  final FarmGame owner;
  _Background(this.owner) : super(priority: -1000);

  // Tuft positions as fractions of the screen: generated once, the same on every launch.
  static final List<Offset> _tufts = () {
    final rnd = math.Random(7);
    return [for (var i = 0; i < 70; i++) Offset(rnd.nextDouble(), rnd.nextDouble())];
  }();

  final Paint _gradient = Paint();
  Size? _gradientFor;

  @override
  void render(ui.Canvas canvas) {
    final size = Size(owner.size.x, owner.size.y);
    final rect = Offset.zero & size;
    if (_gradientFor != size) {
      _gradient.shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, const [Color(0xFF8CC63F), Color(0xFF6DAA2C)]);
      _gradientFor = size;
    }
    canvas.drawRect(rect, _gradient);
    final sp = owner.sprites;
    final layout = owner.layout;
    if (sp == null || layout == null) return;
    final tuft = sp['decor_tuft'];
    final w = 18 * layout.scale * 1.6, h = 13 * layout.scale * 1.6;
    for (final t in _tufts) {
      _drawSprite(canvas, tuft, Rect.fromLTWH(t.dx * size.width, t.dy * size.height, w, h));
    }
  }
}

class FarmGame extends FlameGame {
  final void Function(int index) onPlotTap;
  final void Function(int slot)? onAnimalTap;
  final Map<int, PlotComponent> _plots = {};
  final Map<int, AnimalComponent> _animals = {};
  final List<_DecorComponent> _decor = [];

  /// Set once the PNGs are decoded; until then tiles are still tappable but draw nothing.
  Sprites? sprites;
  IsoLayout? layout;

  FarmGame({required this.onPlotTap, this.onAnimalTap});

  @override
  Color backgroundColor() => const Color(0xFF7CB342);

  @override
  Future<void> onLoad() async {
    add(_Background(this));
    for (final spot in decor) {
      final c = _DecorComponent(this, spot);
      _decor.add(c);
      add(c);
    }
  }

  /// Screen position (game-local) of a plot's centre. Used for hit testing in tests.
  Offset plotCenter(int index) => layout!.plotCenter(index);
  Offset penCenter(int slot) => layout!.penCenter(slot);

  /// Applies a fresh farm state. Called on every server response and once a second.
  void setFarm(Farm farm, int serverNow) {
    final nextLocked = farm.plots.indexWhere((p) => !p.unlocked);
    for (final p in farm.plots) {
      var c = _plots[p.index];
      if (c == null) {
        c = PlotComponent(p, onPlotTap, this)..priority = _plotPriority(p.index);
        _plots[p.index] = c;
        add(c);
        // Before the first layout there is no size; onGameResize lays out later.
        if (hasLayout) _place(c, layout!.plotCenter(p.index));
      }
      c
        ..plot = p
        ..isNext = p.index == nextLocked
        ..serverNow = serverNow;
    }
    for (var slot = 0; slot < farm.animalSlots && slot < animalSlots; slot++) {
      var c = _animals[slot];
      if (c == null) {
        c = AnimalComponent(slot, onAnimalTap, this)..priority = _penPriority(slot);
        _animals[slot] = c;
        add(c);
        if (hasLayout) _place(c, layout!.penCenter(slot));
      }
      c
        ..animal = animalAt(farm, slot)
        ..serverNow = serverNow;
    }
  }

  // Depth order is the ground y of the tile's front corner, shared with the scenery.
  static int _plotPriority(int index) {
    final c = plotCell(index);
    return cellCenter(c.col.toDouble(), c.row.toDouble()).dy.round() + tileHalfH.round();
  }

  static int _penPriority(int slot) {
    final c = penCell(slot);
    return cellCenter(c.col.toDouble(), c.row.toDouble()).dy.round() + tileHalfH.round();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final l = layout = IsoLayout.fit(size.x, size.y);
    _plots.forEach((i, c) => _place(c, l.plotCenter(i)));
    _animals.forEach((s, c) => _place(c, l.penCenter(s)));
    for (final d in _decor) {
      final o = l.toScreen(Offset(d.spot.x, d.spot.y));
      d
        ..size = Vector2(d.spot.width, d.spot.height) * l.scale
        ..position = Vector2(o.dx - d.spot.baseX * l.scale, o.dy - d.spot.baseY * l.scale);
    }
  }

  void _place(PositionComponent c, Offset center) {
    final l = layout!;
    c
      ..size = Vector2.all(spriteCanvas * l.scale)
      ..position = Vector2(center.dx - anchorX * l.scale, center.dy - anchorY * l.scale);
  }
}
