import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/farm_game.dart';
import 'package:happy_farm/src/farm_screen.dart';
import 'package:happy_farm/src/models.dart';

Map<String, dynamic> plotJson(int i) =>
    {'index': i, 'unlocked': i < 6, 'cropId': null, 'plantedAt': null, 'readyAt': null, 'ready': false, 'stolenShare': 0};

void main() {
  animalTests();
  staleAfterLostReply();
  testWidgets('tapping an empty plot opens the seed picker and plants', (tester) async {
    final farmJson = {
      'id': 1, 'name': 'Anna', 'coins': 200, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [for (var i = 0; i < 24; i++) plotJson(i)],
    };
    final planted = <Map<String, dynamic>>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/catalog') {
          return http.Response.bytes(
              utf8.encode(jsonEncode([
                {'id': 'radish', 'name': 'Редис', 'seedPrice': 10, 'growSeconds': 60, 'yieldCount': 10, 'sellPrice': 2, 'xp': 5, 'unlockLevel': 1},
              ])),
              200);
        }
        if (req.url.path == '/plant') {
          planted.add(jsonDecode(req.body) as Map<String, dynamic>);
          final plots = [for (var i = 0; i < 24; i++) plotJson(i)];
          plots[0] = {...plots[0], 'cropId': 'radish', 'plantedAt': 1000, 'readyAt': 1060};
          return http.Response(jsonEncode({...farmJson, 'coins': 190, 'plots': plots}), 200);
        }
        return http.Response(jsonEncode(farmJson), 200);
      }),
    );

    final gameFinder = find.byWidgetPredicate((w) => w is GameWidget);
    await tester.pumpWidget(MaterialApp(home: FarmScreen(api: api, initial: Farm.fromJson(farmJson))));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(gameFinder, findsWidgets);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('200 🪙'), findsOneWidget);

    // Plot 0 is the top-left cell, just under the HUD.
    final topLeft = tester.getTopLeft(gameFinder.first);
    final gs = tester.getSize(gameFinder.first);
    final m = gridMetrics(gs.width, gs.height);
    final cell = m.cell;
    final left = m.left;
    await tester.tapAt(topLeft + Offset(left + cell / 2, cell / 2));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // the game loop never settles
    }
    expect(find.text('Редис'), findsOneWidget);

    await tester.tap(find.text('Редис'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // the game loop never settles
    }
    expect(planted, [
      {'plot': 0, 'cropId': 'radish'}
    ]);
    expect(find.text('190 🪙'), findsOneWidget);

    // Stop the periodic ticker before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}

void staleAfterLostReply() {
  testWidgets('after a lost reply the farm is re-read from the server', (tester) async {
    final farm = {
      'id': 1, 'name': 'Anna', 'coins': 200, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [for (var i = 0; i < 24; i++) plotJson(i)],
    };
    var farmGets = 0;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/catalog') {
          return http.Response.bytes(
              utf8.encode(jsonEncode([
                {'id': 'radish', 'name': 'Редис', 'seedPrice': 10, 'growSeconds': 60, 'yieldCount': 10, 'sellPrice': 2, 'xp': 5, 'unlockLevel': 1},
              ])),
              200);
        }
        if (req.url.path == '/animal-catalog') return http.Response('[]', 200);
        if (req.url.path == '/plant') throw http.ClientException('reply lost');
        farmGets++;
        return http.Response(jsonEncode({...farm, 'coins': 190}), 200); // the plant did succeed server-side
      }),
    );
    await tester.pumpWidget(MaterialApp(home: FarmScreen(api: api, initial: Farm.fromJson(farm))));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final gameFinder = find.byWidgetPredicate((w) => w is GameWidget);
    final gs = tester.getSize(gameFinder.first);
    final m = gridMetrics(gs.width, gs.height);
    final cell = m.cell;
    final left = m.left;
    await tester.tapAt(tester.getTopLeft(gameFinder.first) + Offset(left + cell / 2, cell / 2));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Редис'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(farmGets, 1);
    expect(find.text('190 🪙'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

void animalTests() {
  Map<String, dynamic> farmWith(List<Map<String, dynamic>> animals, {int coins = 200, int serverTime = 1000}) => {
        'id': 1, 'name': 'Anna', 'coins': coins, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': serverTime,
        'plots': [for (var i = 0; i < 24; i++) plotJson(i)],
        'animals': animals, 'animalSlots': 4,
      };

  http.Response bytes(Object o) => http.Response.bytes(utf8.encode(jsonEncode(o)), 200);

  Future<void> frames(WidgetTester tester, [int n = 5]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Offset animalTap(WidgetTester tester, Finder game, int slot) {
    final gs = tester.getSize(game.first);
    final m = gridMetrics(gs.width, gs.height);
    return tester.getTopLeft(game.first) + Offset(m.left + m.cell * (slot + 0.5), m.cell * 6.5);
  }

  const kinds = [
    {'id': 'chicken', 'name': 'Курица', 'price': 100, 'produceSeconds': 600, 'product': 'Яйца', 'value': 40, 'xp': 8, 'unlockLevel': 1},
    {'id': 'cow', 'name': 'Корова', 'price': 900, 'produceSeconds': 3600, 'product': 'Молоко', 'value': 300, 'xp': 50, 'unlockLevel': 5},
  ];

  testWidgets('tap an empty pen: pick an animal and buy it; locked ones are disabled', (tester) async {
    final bought = <Map<String, dynamic>>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/animal-catalog') return bytes(kinds);
        if (req.url.path == '/catalog') return bytes([]);
        if (req.url.path == '/animals/buy') {
          bought.add(jsonDecode(req.body) as Map<String, dynamic>);
          return bytes(farmWith([
            {'slot': 0, 'kind': 'chicken', 'lastCollectedAt': 1000, 'readyAt': 1600, 'ready': false}
          ], coins: 100));
        }
        return bytes(farmWith([]));
      }),
    );
    await tester.pumpWidget(MaterialApp(home: FarmScreen(api: api, initial: Farm.fromJson(farmWith([])))));
    await frames(tester, 3);
    final game = find.byWidgetPredicate((w) => w is GameWidget);
    await tester.tapAt(animalTap(tester, game, 0));
    await frames(tester);
    expect(find.text('Курица'), findsOneWidget);
    expect(find.text('Откроется на уровне 5'), findsOneWidget); // the cow is locked at level 1
    await tester.tap(find.text('Корова'), warnIfMissed: false); // disabled tile: nothing happens
    await frames(tester);
    expect(bought, isEmpty);
    await tester.tap(find.text('Курица'));
    await frames(tester);
    expect(bought, [
      {'slot': 0, 'kind': 'chicken'}
    ]);
    expect(find.text('100 🪙'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tap a ready animal collects; a producing one only shows a hint', (tester) async {
    final collected = <Map<String, dynamic>>[];
    // Slot 0 is ready (readyAt 900 < serverTime 1000); slot 1 is still producing.
    final animals = [
      {'slot': 0, 'kind': 'chicken', 'lastCollectedAt': 300, 'readyAt': 900, 'ready': true},
      {'slot': 1, 'kind': 'chicken', 'lastCollectedAt': 1000, 'readyAt': 1600, 'ready': false},
    ];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/animal-catalog') return bytes(kinds);
        if (req.url.path == '/catalog') return bytes([]);
        if (req.url.path == '/animals/collect') {
          collected.add(jsonDecode(req.body) as Map<String, dynamic>);
          return bytes({'earned': 40, 'xp': 8, 'levelUp': false, 'farm': farmWith(animals, coins: 240)});
        }
        return bytes(farmWith(animals));
      }),
    );
    await tester.pumpWidget(MaterialApp(home: FarmScreen(api: api, initial: Farm.fromJson(farmWith(animals)))));
    await frames(tester, 3);
    final game = find.byWidgetPredicate((w) => w is GameWidget);

    await tester.tapAt(animalTap(tester, game, 1));
    await frames(tester);
    expect(collected, isEmpty);
    expect(find.textContaining('Будет готово через'), findsOneWidget);

    await tester.tapAt(animalTap(tester, game, 0));
    await frames(tester);
    expect(collected, [
      {'slot': 0}
    ]);
    expect(find.text('240 🪙'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
