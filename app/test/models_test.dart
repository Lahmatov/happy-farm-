import 'package:flutter_test/flutter_test.dart';
import 'package:happy_farm/src/models.dart';

Plot plot({bool unlocked = true, String? crop, int? planted, int? ready}) =>
    Plot(index: 0, unlocked: unlocked, cropId: crop, plantedAt: planted, readyAt: ready);

void main() {
  test('animal stage follows the server clock', () {
    const a = Animal(slot: 0, kind: 'chicken', lastCollectedAt: 100, readyAt: 700);
    expect(animalStageOf(null, 0), AnimalStage.empty);
    expect(animalStageOf(a, 699), AnimalStage.producing);
    expect(animalStageOf(a, 700), AnimalStage.ready);
    expect(animalProgress(a, 400), 0.5);
    expect(animalProgress(a, 5000), 1);
  });

  test('farm without animals (older server) still parses', () {
    final farm = Farm.fromJson({
      'id': 1, 'name': 'A', 'coins': 1, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1, 'plots': [],
    });
    expect(farm.animals, isEmpty);
    expect(farm.animalSlots, 4);
  });

  test('stage follows the server clock', () {
    expect(stageOf(plot(unlocked: false), 0), PlotStage.locked);
    expect(stageOf(plot(), 0), PlotStage.empty);
    final p = plot(crop: 'radish', planted: 100, ready: 160);
    expect(stageOf(p, 159), PlotStage.growing);
    expect(stageOf(p, 160), PlotStage.ripe);
  });

  test('a plot with a crop but no readyAt does not throw', () {
    expect(stageOf(plot(crop: 'radish', planted: 1), 5), PlotStage.growing);
  });

  test('growth progress is clamped to 0..1', () {
    final p = plot(crop: 'radish', planted: 100, ready: 200);
    expect(growthProgress(p, 50), 0);
    expect(growthProgress(p, 150), 0.5);
    expect(growthProgress(p, 999), 1);
    expect(growthProgress(plot(), 5), 0);
  });

  test('farm parses the server payload', () {
    final farm = Farm.fromJson({
      'id': 1, 'name': 'Anna', 'coins': 190, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000,
      'plots': [
        {'index': 0, 'unlocked': true, 'cropId': 'radish', 'plantedAt': 1000, 'readyAt': 1060, 'ready': false, 'stolenShare': 0},
        {'index': 1, 'unlocked': false, 'cropId': null, 'plantedAt': null, 'readyAt': null, 'ready': false, 'stolenShare': 0},
      ],
    });
    expect(farm.plots[0].readyAt, 1060);
    expect(farm.plots[1].cropId, isNull);
  });
}
