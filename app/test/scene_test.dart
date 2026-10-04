import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/farm_game.dart';
import 'package:happy_farm/src/farm_screen.dart';
import 'package:happy_farm/src/iso.dart';
import 'package:happy_farm/src/models.dart';
import 'package:happy_farm/src/sprites.dart';

Map<String, dynamic> plotJson(int i, {String? crop, int? planted, int? ready}) => {
      'index': i, 'unlocked': i < 6, 'cropId': crop, 'plantedAt': planted, 'readyAt': ready, 'ready': false, 'stolenShare': 0,
    };

Map<String, dynamic> richFarm() => {
      'id': 1, 'name': 'Anna', 'coins': 1234, 'xp': 260, 'level': 3, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [
        plotJson(0, crop: 'radish', planted: 900, ready: 960), // ripe
        plotJson(1, crop: 'wheat', planted: 700, ready: 1200), // growing
        plotJson(2, crop: 'carrot', planted: 100, ready: 900), // ripe
        plotJson(3, crop: 'strawberry', planted: 950, ready: 1900), // just planted
        plotJson(4, crop: 'corn', planted: 100, ready: 500), // ripe
        plotJson(5),
        for (var i = 6; i < 24; i++) plotJson(i),
      ],
      'animals': [
        {'slot': 0, 'kind': 'chicken', 'lastCollectedAt': 300, 'readyAt': 900, 'ready': true},
        {'slot': 1, 'kind': 'sheep', 'lastCollectedAt': 900, 'readyAt': 1700, 'ready': false},
        {'slot': 2, 'kind': 'cow', 'lastCollectedAt': 100, 'readyAt': 700, 'ready': true},
      ],
      'animalSlots': 4,
    };

void main() {
  testWidgets('taps near the shared edge of two tiles go to the front tile, away from it to the right one', (tester) async {
    final taps = <int>[];
    final game = FarmGame(onPlotTap: taps.add);
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: SizedBox(width: 390, height: 640, child: GameWidget(game: game))));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    game.setFarm(Farm.fromJson(richFarm()), 1000);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final origin = tester.getTopLeft(find.byType(GameWidget<FarmGame>));
    // Plots 0 and 1 are neighbours along the first row; plot 1 is nearer to the viewer.
    final c0 = game.plotCenter(0), c1 = game.plotCenter(1);
    Offset at(double t) => origin + Offset.lerp(c0, c1, t)!;

    for (final (t, expected) in [(0.2, 0), (0.45, 0), (0.5, 1), (0.55, 1), (0.8, 1)]) {
      taps.clear();
      await tester.tapAt(at(t));
      await tester.pump(const Duration(milliseconds: 50));
      expect(taps, [expected], reason: 'tap at t=$t between plot 0 and plot 1');
    }
    await tester.pumpWidget(const SizedBox());
  });

  test('layout: the whole scene fits any phone, tiles keep a usable size, nothing overlaps', () {
    for (final size in const [Size(375, 520), Size(393, 640), Size(430, 740)]) {
      final l = IsoLayout.fit(size.width, size.height);
      final b = IsoLayout.fieldBounds;
      final tl = l.toScreen(b.topLeft), br = l.toScreen(b.bottomRight);
      expect(tl.dx, greaterThanOrEqualTo(-0.5));
      expect(tl.dy, greaterThanOrEqualTo(-0.5));
      expect(br.dx, lessThanOrEqualTo(size.width + 0.5));
      expect(br.dy, lessThanOrEqualTo(size.height + 0.5));
      // A diamond tile is about 2 * tileHalfW * scale wide: keep it comfortably tappable.
      expect(2 * tileHalfW * l.scale, greaterThan(70), reason: '$size');
    }
    // Plots and pens occupy distinct isometric cells.
    final cells = <String>{};
    for (var i = 0; i < plotCols * plotRows; i++) {
      final c = plotCell(i);
      expect(cells.add('${c.col},${c.row}'), isTrue);
    }
    for (var s = 0; s < animalSlots; s++) {
      final c = penCell(s);
      expect(cells.add('${c.col},${c.row}'), isTrue, reason: 'pen $s collides with a plot or pen');
    }
  });

  test('scenery stays off the field and is deterministic', () {
    final field = IsoLayout.fieldBounds;
    expect(decor.length, greaterThan(20));
    for (final d in decor.skip(1)) {
      expect(d.rect.overlaps(field), isFalse, reason: '${d.sprite} at ${d.x},${d.y} sits on the field');
    }
  });

  test('a degenerate size never produces a zero or negative scale', () {
    expect(IsoLayout.fit(0, 0).scale, greaterThan(0));
  });

  testWidgets('every sprite decodes, and the farm scene really draws them', (tester) async {
    final sprites = await tester.runAsync(Sprites.load);
    expect(sprites, isNotNull);
    for (final n in Sprites.names) {
      expect(sprites![n].width, greaterThan(0), reason: n);
    }
    // All plot/pen layers share one square canvas so they stack exactly.
    for (final n in ['soil_dry', 'soil_wet', 'soil_locked', 'soil_next', 'pen', 'crop_corn_3', 'animal_cow']) {
      expect(sprites![n].width, sprites[n].height, reason: n);
      expect(sprites[n].width, sprites['soil_dry'].width, reason: n);
    }

    tester.view.physicalSize = const Size(1179, 2556); // iPhone 15 Pro at 3x
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async => http.Response.bytes(utf8.encode(req.url.path.endsWith('catalog') ? '[]' : jsonEncode(richFarm())), 200)),
    );
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(key: key, child: FarmScreen(api: api, initial: Farm.fromJson(richFarm()), sprites: sprites)),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final bytes = await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    // Count distinct colours: a blank or flat scene has a handful, real art has thousands.
    final colours = <int>{};
    for (var i = 0; i < bytes!.lengthInBytes; i += 4 * 7) {
      colours.add(bytes.getUint32(i));
    }
    expect(colours.length, greaterThan(500), reason: 'the scene looks blank');

    final dir = Platform.environment['SCREENSHOT_DIR'];
    if (dir != null) {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/scene.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
    await tester.pumpWidget(const SizedBox());
  });
}
