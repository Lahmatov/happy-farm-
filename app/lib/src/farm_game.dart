
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'models.dart';

const cropEmoji = {
  'radish': '🌱',
  'wheat': '🌾',
  'carrot': '🥕',
  'strawberry': '🍓',
  'corn': '🌽',
};

const _columns = 4;

class PlotComponent extends PositionComponent with TapCallbacks {
  final void Function(int index) onTap;
  Plot plot;
  int serverNow = 0;

  PlotComponent(this.plot, this.onTap);

  @override
  void onTapDown(TapDownEvent event) => onTap(plot.index);

  @override
  void render(Canvas canvas) {
    final stage = stageOf(plot, serverNow);
    final rect = Rect.fromLTWH(3, 3, size.x - 6, size.y - 6);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final soil = switch (stage) {
      PlotStage.locked => const Color(0xFF9E9E9E),
      PlotStage.ripe => const Color(0xFF6D4C41),
      _ => const Color(0xFF8D6E63),
    };
    canvas.drawRRect(rrect, Paint()..color = soil);
    if (stage == PlotStage.ripe) {
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFFFFEB3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    final glyph = switch (stage) {
      PlotStage.locked => '🔒',
      PlotStage.empty => '',
      _ => cropEmoji[plot.cropId] ?? '🌿',
    };
    if (glyph.isNotEmpty) {
      // Crops grow: the emoji scales from 40% to 100% of the plot.
      final scale = stage == PlotStage.growing ? 0.4 + 0.5 * growthProgress(plot, serverNow) : 1.0;
      final tp = TextPainter(
        text: TextSpan(text: glyph, style: TextStyle(fontSize: size.x * 0.5 * scale)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
    }
    if (stage == PlotStage.growing) {
      final bar = Rect.fromLTWH(rect.left + 8, rect.bottom - 10, rect.width - 16, 5);
      canvas.drawRect(bar, Paint()..color = const Color(0x55000000));
      canvas.drawRect(Rect.fromLTWH(bar.left, bar.top, bar.width * growthProgress(plot, serverNow), bar.height),
          Paint()..color = const Color(0xFF8BC34A));
    }
  }
}

class FarmGame extends FlameGame {
  final void Function(int index) onPlotTap;
  final Map<int, PlotComponent> _components = {};

  FarmGame({required this.onPlotTap});

  @override
  Color backgroundColor() => const Color(0xFF7CB342);

  /// Applies a fresh farm state. Called on every server response and once a second.
  void setFarm(Farm farm, int serverNow) {
    for (final p in farm.plots) {
      final c = _components[p.index];
      if (c == null) {
        final created = PlotComponent(p, onPlotTap)..serverNow = serverNow;
        _components[p.index] = created;
        add(created);
        // Before the first layout there is no size; onGameResize lays out later.
        if (hasLayout) _layout(created);
      } else {
        c
          ..plot = p
          ..serverNow = serverNow;
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _components.values.forEach(_layout);
  }

  void _layout(PlotComponent c) {
    final cell = size.x / _columns;
    c.size = Vector2.all(cell);
    c.position = Vector2((c.plot.index % _columns) * cell, (c.plot.index ~/ _columns) * cell);
  }
}
