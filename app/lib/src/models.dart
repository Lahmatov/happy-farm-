class Crop {
  final String id;
  final String name;
  final int seedPrice;
  final int growSeconds;
  final int yieldCount;
  final int sellPrice;
  final int xp;
  final int unlockLevel;

  const Crop({
    required this.id,
    required this.name,
    required this.seedPrice,
    required this.growSeconds,
    required this.yieldCount,
    required this.sellPrice,
    required this.xp,
    required this.unlockLevel,
  });

  factory Crop.fromJson(Map<String, dynamic> j) => Crop(
        id: j['id'] as String,
        name: j['name'] as String,
        seedPrice: j['seedPrice'] as int,
        growSeconds: j['growSeconds'] as int,
        yieldCount: j['yieldCount'] as int,
        sellPrice: j['sellPrice'] as int,
        xp: j['xp'] as int,
        unlockLevel: j['unlockLevel'] as int,
      );
}

class Plot {
  final int index;
  final bool unlocked;
  final String? cropId;
  final int? plantedAt;
  final int? readyAt;
  final bool ready;

  const Plot({
    required this.index,
    required this.unlocked,
    this.cropId,
    this.plantedAt,
    this.readyAt,
    this.ready = false,
  });

  factory Plot.fromJson(Map<String, dynamic> j) => Plot(
        index: j['index'] as int,
        unlocked: j['unlocked'] as bool,
        cropId: j['cropId'] as String?,
        plantedAt: j['plantedAt'] as int?,
        readyAt: j['readyAt'] as int?,
        ready: j['ready'] as bool,
      );
}

class Farm {
  final int id;
  final String name;
  final int coins;
  final int xp;
  final int level;
  final List<Plot> plots;
  final int plotUnlockPrice;
  final int serverTime;

  const Farm({
    required this.id,
    required this.name,
    required this.coins,
    required this.xp,
    required this.level,
    required this.plots,
    required this.plotUnlockPrice,
    required this.serverTime,
  });

  factory Farm.fromJson(Map<String, dynamic> j) => Farm(
        id: j['id'] as int,
        name: j['name'] as String,
        coins: j['coins'] as int,
        xp: j['xp'] as int,
        level: j['level'] as int,
        plots: (j['plots'] as List).map((p) => Plot.fromJson(p as Map<String, dynamic>)).toList(),
        plotUnlockPrice: j['plotUnlockPrice'] as int,
        serverTime: j['serverTime'] as int,
      );
}

class Friend {
  final int id;
  final String name;
  final int level;
  const Friend({required this.id, required this.name, required this.level});

  factory Friend.fromJson(Map<String, dynamic> j) =>
      Friend(id: j['id'] as int, name: j['name'] as String, level: j['level'] as int);
}

enum PlotStage { locked, empty, growing, ripe }

/// Visual stage of a plot. [serverNow] must be on the server clock, so the
/// player cannot make crops ripen by changing the phone's time.
PlotStage stageOf(Plot p, int serverNow) {
  if (!p.unlocked) return PlotStage.locked;
  if (p.cropId == null) return PlotStage.empty;
  final readyAt = p.readyAt;
  if (readyAt == null) return PlotStage.growing; // malformed payload: do not crash the render loop
  return serverNow >= readyAt ? PlotStage.ripe : PlotStage.growing;
}

/// 0..1 growth progress, 1 when ripe.
double growthProgress(Plot p, int serverNow) {
  if (p.cropId == null || p.plantedAt == null || p.readyAt == null) return 0;
  final total = p.readyAt! - p.plantedAt!;
  if (total <= 0) return 1;
  return ((serverNow - p.plantedAt!) / total).clamp(0.0, 1.0);
}
