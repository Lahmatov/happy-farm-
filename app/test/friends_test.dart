import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/farm_game.dart';
import 'package:happy_farm/src/friend_farm_screen.dart';
import 'package:happy_farm/src/friends_screen.dart';
import 'package:happy_farm/src/messages.dart';
import 'package:happy_farm/src/models.dart';

Map<String, dynamic> farmJson({bool ripe = false, int coins = 200}) => {
      'id': 2, 'name': 'Boris', 'coins': coins, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [
        for (var i = 0; i < 24; i++)
          {
            'index': i, 'unlocked': i < 6,
            'cropId': i == 0 && ripe ? 'radish' : null,
            'plantedAt': i == 0 && ripe ? 900 : null,
            'readyAt': i == 0 && ripe ? 960 : null,
            'ready': i == 0 && ripe,
            'stolenShare': 0,
          },
      ],
    };

http.Response json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json; charset=utf-8'});

Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  resilienceTests();
  test('friend endpoints parse', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/friends/2/steal') {
          return json({'amount': 1, 'earned': 2, 'xp': 1, 'farm': farmJson()});
        }
        return json([
          {'id': 2, 'name': 'Boris', 'level': 3}
        ]);
      }),
    );
    expect((await api.friends()).single.name, 'Boris');
    expect((await api.addFriend('Boris')).single.level, 3);
    expect((await api.steal(2, 0)).earned, 2);
  });

  test('known server errors are translated, unknown ones pass through', () {
    expect(localize('not enough coins'), 'Не хватает монет');
    expect(localize('something new'), 'something new');
  });

  testWidgets('friends screen lists neighbours and adds one by name', (tester) async {
    final names = ['Boris'];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.method == 'POST') names.add(jsonDecode(req.body)['name'] as String);
        return json([for (var i = 0; i < names.length; i++) {'id': i + 2, 'name': names[i], 'level': 1}]);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(api: api)));
    await pumpFrames(tester);
    expect(find.text('Boris'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Clara');
    await tester.tap(find.text('Добавить'));
    await pumpFrames(tester);
    expect(find.text('Clara'), findsOneWidget);
  });

  testWidgets('friends screen shows a translated error for an unknown player', (tester) async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async =>
          req.method == 'POST' ? json({'error': 'user not found'}, 404) : json(<Object>[])),
    );
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(api: api)));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'Nobody');
    await tester.tap(find.text('Добавить'));
    await pumpFrames(tester);
    expect(find.text('Игрок не найден'), findsOneWidget);
  });

  testWidgets('tapping a ripe plot on a friend farm steals; unripe plots do not', (tester) async {
    final stolen = <Map<String, dynamic>>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        if (req.url.path == '/friends/2/steal') {
          stolen.add(jsonDecode(req.body) as Map<String, dynamic>);
          return json({'amount': 1, 'earned': 2, 'xp': 1, 'farm': farmJson(coins: 202)});
        }
        return json(farmJson(ripe: true)); // GET /friends/2/farm
      }),
    );
    await tester.pumpWidget(MaterialApp(
      home: FriendFarmScreen(api: api, friend: const Friend(id: 2, name: 'Boris', level: 1)),
    ));
    await pumpFrames(tester);

    final game = find.byWidgetPredicate((w) => w is GameWidget);
    final topLeft = tester.getTopLeft(game.first);
    final gs = tester.getSize(game.first);
    final m = gridMetrics(gs.width, gs.height);
    final cell = m.cell;
    final left = m.left;

    // Plot 1 is empty: no steal request.
    await tester.tapAt(topLeft + Offset(left + cell * 1.5, cell / 2));
    await pumpFrames(tester);
    expect(stolen, isEmpty);
    expect(find.text('Красть можно только созревший урожай'), findsOneWidget);

    // Plot 0 is ripe: steal.
    await tester.tapAt(topLeft + Offset(left + cell / 2, cell / 2));
    await pumpFrames(tester);
    expect(stolen, [
      {'plot': 0}
    ]);

    await tester.pumpWidget(const SizedBox()); // stop the ticker
  });
}

void resilienceTests() {
  testWidgets('friends screen: failed first load offers a retry that recovers', (tester) async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        calls++;
        if (calls == 1) throw http.ClientException('down');
        return json([
          {'id': 2, 'name': 'Boris', 'level': 1}
        ]);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(api: api)));
    await pumpFrames(tester);
    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await pumpFrames(tester);
    expect(find.text('Boris'), findsOneWidget);
  });

  testWidgets('friends screen keeps the typed name when adding fails', (tester) async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async =>
          req.method == 'POST' ? json({'error': 'user not found'}, 404) : json(<Object>[])),
    );
    await tester.pumpWidget(MaterialApp(home: FriendsScreen(api: api)));
    await pumpFrames(tester);
    await tester.enterText(find.byType(TextField), 'Borsi');
    await tester.tap(find.text('Добавить'));
    await pumpFrames(tester);
    expect(find.text('Borsi'), findsOneWidget); // still in the field
  });

  testWidgets('friend farm: failed load offers a retry that recovers', (tester) async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        calls++;
        if (calls == 1) throw http.ClientException('down');
        return json(farmJson());
      }),
    );
    await tester.pumpWidget(MaterialApp(
      home: FriendFarmScreen(api: api, friend: const Friend(id: 2, name: 'Boris', level: 1)),
    ));
    await pumpFrames(tester);
    await tester.tap(find.text('Повторить'));
    await pumpFrames(tester);
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
