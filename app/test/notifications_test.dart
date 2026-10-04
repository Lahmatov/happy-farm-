import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/farm_screen.dart';
import 'package:happy_farm/src/models.dart';
import 'package:happy_farm/src/notifications.dart';

class FakeScheduler implements NotificationScheduler {
  final log = <String>[];
  Duration? lastDelay;

  @override
  Future<void> cancel() async => log.add('cancel');

  @override
  Future<void> scheduleIn(Duration delay, {required String title, required String body}) async {
    lastDelay = delay;
    log.add('schedule ${delay.inSeconds}');
  }
}

Plot plot(int i, {String? crop, int? readyAt}) =>
    Plot(index: i, unlocked: true, cropId: crop, plantedAt: crop == null ? null : 0, readyAt: readyAt);

Farm farm({List<Plot> plots = const [], List<Animal> animals = const []}) => Farm(
      id: 1, name: 'A', coins: 0, xp: 0, level: 1, plots: plots, animals: animals, plotUnlockPrice: 500, serverTime: 1000,
    );

void main() {
  group('secondsUntilNextReady', () {
    test('nothing growing: null', () {
      expect(secondsUntilNextReady(farm(plots: [plot(0)]), 1000), isNull);
    });

    test('picks the earliest of plots and animals, on the server clock', () {
      final f = farm(
        plots: [plot(0, crop: 'wheat', readyAt: 1300), plot(1, crop: 'radish', readyAt: 1060)],
        animals: const [Animal(slot: 0, kind: 'chicken', lastCollectedAt: 1000, readyAt: 1030)],
      );
      expect(secondsUntilNextReady(f, 1000), 30);
    });

    test('already ripe or ready things are ignored', () {
      final f = farm(
        plots: [plot(0, crop: 'radish', readyAt: 900), plot(1, crop: 'wheat', readyAt: 1300)],
        animals: const [Animal(slot: 0, kind: 'chicken', lastCollectedAt: 100, readyAt: 700)],
      );
      expect(secondsUntilNextReady(f, 1000), 300);
    });
  });

  group('ReadyReminder', () {
    test('replaces the pending reminder, then clears it when nothing is left', () async {
      final s = FakeScheduler();
      final r = ReadyReminder(s);
      await r.update(farm(plots: [plot(0, crop: 'radish', readyAt: 1060)]), 1000);
      expect(s.log, ['cancel', 'schedule 60']);
      s.log.clear();
      await r.update(farm(plots: [plot(0)]), 1000); // harvested
      expect(s.log, ['cancel']);
    });

    test('a failing scheduler never throws into the game', () async {
      final r = ReadyReminder(_Throwing());
      await r.update(farm(plots: [plot(0, crop: 'radish', readyAt: 1060)]), 1000);
    });
  });

  testWidgets('the farm screen schedules a reminder for the earliest ready time', (tester) async {
    final json = {
      'id': 1, 'name': 'Anna', 'coins': 190, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [
        for (var i = 0; i < 24; i++)
          {
            'index': i, 'unlocked': i < 6, 'cropId': i == 0 ? 'radish' : null,
            'plantedAt': i == 0 ? 1000 : null, 'readyAt': i == 0 ? 1060 : null, 'ready': false, 'stolenShare': 0,
          },
      ],
    };
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async => http.Response(req.url.path.endsWith('catalog') ? '[]' : jsonEncode(json), 200)),
    );
    final scheduler = FakeScheduler();
    await tester.pumpWidget(MaterialApp(
      home: FarmScreen(api: api, initial: Farm.fromJson(json), reminder: ReadyReminder(scheduler)),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scheduler.lastDelay, const Duration(seconds: 60));
    await tester.pumpWidget(const SizedBox());
  });
}

class _Throwing implements NotificationScheduler {
  @override
  Future<void> cancel() async => throw Exception('boom');

  @override
  Future<void> scheduleIn(Duration delay, {required String title, required String body}) async => throw Exception('boom');
}
