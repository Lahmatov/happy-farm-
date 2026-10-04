import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'farm_game.dart';
import 'models.dart';

class FarmScreen extends StatefulWidget {
  final ApiClient api;
  final Farm initial;
  const FarmScreen({super.key, required this.api, required this.initial});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> with WidgetsBindingObserver {
  late Farm _farm = widget.initial;
  List<Crop> _crops = const [];
  late final FarmGame _game = FarmGame(onPlotTap: _onPlotTap);
  Timer? _ticker;
  // serverTime - local time at the moment the farm was received.
  late int _clockOffset;

  int get _serverNow => DateTime.now().millisecondsSinceEpoch ~/ 1000 + _clockOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apply(_farm);
    widget.api.catalog().then((c) => mounted ? setState(() => _crops = c) : null).catchError(_showError);
    // Re-evaluate crop stages once a second, not every frame.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _game.setFarm(_farm, _serverNow);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _apply(Farm farm) {
    _farm = farm;
    _clockOffset = farm.serverTime - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _game.setFarm(farm, farm.serverTime);
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    try {
      _apply(await widget.api.farm());
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  Future<void> _onPlotTap(int index) async {
    final plot = _farm.plots[index];
    try {
      switch (stageOf(plot, _serverNow)) {
        case PlotStage.locked:
          await _offerUnlock(index);
        case PlotStage.empty:
          final crop = await _pickSeed();
          if (crop != null) _apply(await widget.api.plant(index, crop.id));
        case PlotStage.growing:
          final left = plot.readyAt! - _serverNow;
          _toast('Созреет через ${_format(left)}');
        case PlotStage.ripe:
          final r = await widget.api.harvest(index);
          _apply(r.farm);
          _toast('+${r.earned} монет, +${r.xp} опыта${r.levelUp ? ' — новый уровень!' : ''}');
      }
    } on ApiException catch (e) {
      _showError(e);
    }
  }

  Future<void> _offerUnlock(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Купить грядку?'),
        content: const Text('Новая грядка стоит 500 монет.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Купить')),
        ],
      ),
    );
    if (ok == true) _apply(await widget.api.unlockPlot());
  }

  Future<Crop?> _pickSeed() {
    return showModalBottomSheet<Crop>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final crop in _crops)
              ListTile(
                enabled: crop.unlockLevel <= _farm.level && crop.seedPrice <= _farm.coins,
                leading: Text(cropEmoji[crop.id] ?? '🌿', style: const TextStyle(fontSize: 28)),
                title: Text(crop.name),
                subtitle: Text(crop.unlockLevel > _farm.level
                    ? 'Откроется на уровне ${crop.unlockLevel}'
                    : 'Растёт ${_format(crop.growSeconds)} · урожай ${crop.yieldCount} × ${crop.sellPrice}'),
                trailing: Text('${crop.seedPrice} 🪙'),
                onTap: () => Navigator.pop(c, crop),
              ),
          ],
        ),
      ),
    );
  }

  static String _format(int seconds) {
    if (seconds < 60) return '$seconds с';
    if (seconds < 3600) return '${seconds ~/ 60} мин';
    return '${seconds ~/ 3600} ч ${(seconds % 3600) ~/ 60} мин';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Hud(farm: _farm),
            Expanded(child: GameWidget(game: _game)),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final Farm farm;
  const _Hud({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF33691E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(farm.name),
            Text('Ур. ${farm.level}'),
            Text('${farm.xp} XP'),
            Text('${farm.coins} 🪙'),
          ],
        ),
      ),
    );
  }
}
