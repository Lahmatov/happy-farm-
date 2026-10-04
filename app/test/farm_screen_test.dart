import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/farm_screen.dart';
import 'package:happy_farm/src/models.dart';

Map<String, dynamic> plotJson(int i) =>
    {'index': i, 'unlocked': i < 6, 'cropId': null, 'plantedAt': null, 'readyAt': null, 'ready': false, 'stolenShare': 0};

void main() {
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
    final cell = tester.getSize(gameFinder.first).width / 4;
    await tester.tapAt(topLeft + Offset(cell / 2, cell / 2));
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
    final cell = tester.getSize(gameFinder.first).width / 4;
    await tester.tapAt(tester.getTopLeft(gameFinder.first) + Offset(cell / 2, cell / 2));
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
