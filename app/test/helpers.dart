import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_farm/src/farm_game.dart';

final gameFinder = find.byWidgetPredicate((w) => w is GameWidget);

FarmGame gameOf(WidgetTester tester) => (tester.widget(gameFinder.first) as GameWidget).game as FarmGame;

/// Global position of a plot's centre, taken from the game's own isometric layout.
Offset plotTap(WidgetTester tester, int index) => tester.getTopLeft(gameFinder.first) + gameOf(tester).plotCenter(index);

Offset penTap(WidgetTester tester, int slot) => tester.getTopLeft(gameFinder.first) + gameOf(tester).penCenter(slot);
