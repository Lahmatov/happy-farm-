import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'farm_game.dart';
import 'friends_screen.dart';
import 'messages.dart';
import 'models.dart';
import 'notifications.dart';
import 'sprites.dart';
import 'widgets.dart';
import 'toast.dart';

class FarmScreen extends StatefulWidget {
  final ApiClient api;
  final Farm initial;
  final ReadyReminder? reminder;
  // Normally loaded here; a screen can be handed ready sprites (tests, screenshots).
  final Sprites? sprites;
  const FarmScreen({super.key, required this.api, required this.initial, this.reminder, this.sprites});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> with WidgetsBindingObserver {
  late Farm _farm = widget.initial;
  List<Crop> _crops = const [];
  List<AnimalKind> _animalKinds = const [];
  late final FarmGame _game = FarmGame(onPlotTap: _onPlotTap, onAnimalTap: _onAnimalTap);
  Timer? _ticker;
  // serverTime - local time at the moment the farm was received.
  late int _clockOffset;

  int get _serverNow => DateTime.now().millisecondsSinceEpoch ~/ 1000 + _clockOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apply(_farm);
    _initSprites();
    widget.api.animalCatalog().then((a) => mounted ? setState(() => _animalKinds = a) : null).catchError(_showError);
    widget.api.catalog().then((c) => mounted ? setState(() => _crops = c) : null).catchError(_showError);
    // Re-evaluate crop stages once a second, not every frame.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _game.setFarm(_farm, _serverNow);
      if (mounted) setState(() {});
    });
  }

  void _initSprites() {
    final ready = widget.sprites;
    if (ready != null) {
      _game.sprites = ready;
      return;
    }
    Sprites.load().then((s) {
      _game.sprites = s;
      if (mounted) setState(() {});
    }).catchError(_showError);
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
    widget.reminder?.update(farm, farm.serverTime);
    if (mounted) setState(() {});
  }

  Future<void> _refresh({bool quiet = false}) async {
    try {
      _apply(await widget.api.farm());
    } on ApiException catch (e) {
      if (!quiet) _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    showToast(context, e is ApiException ? localize(e.message) : e.toString());
  }

  void _toast(String text) {
    if (mounted) showToast(context, text);
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
      // Status 0: the request may have reached the server even though the reply was lost,
      // so the screen could be stale. Re-read the truth from the server.
      if (e.status == 0) await _refresh(quiet: true);
    }
  }

  Future<void> _openFriends() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsScreen(api: widget.api)));
    _refresh(); // stealing from a neighbour changed our coins and XP
  }

  Future<void> _onAnimalTap(int slot) async {
    final animal = animalAt(_farm, slot);
    try {
      switch (animalStageOf(animal, _serverNow)) {
        case AnimalStage.empty:
          final kind = await _pickAnimal();
          if (kind != null) _apply(await widget.api.buyAnimal(slot, kind.id));
        case AnimalStage.producing:
          _toast('Будет готово через ${_format(animal!.readyAt - _serverNow)}');
        case AnimalStage.ready:
          final r = await widget.api.collectAnimal(slot);
          _apply(r.farm);
          _toast('+${r.earned} монет, +${r.xp} опыта${r.levelUp ? ' — новый уровень!' : ''}');
      }
    } on ApiException catch (e) {
      _showError(e);
      if (e.status == 0) await _refresh(quiet: true);
    }
  }

  Future<AnimalKind?> _pickAnimal() {
    return showModalBottomSheet<AnimalKind>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final k in _animalKinds)
              ListTile(
                enabled: k.unlockLevel <= _farm.level && k.price <= _farm.coins,
                leading: SpriteThumb('animal_${k.id}'),
                title: Text(k.name),
                subtitle: Text(k.unlockLevel > _farm.level
                    ? 'Откроется на уровне ${k.unlockLevel}'
                    : '${k.product} раз в ${_format(k.produceSeconds)} · +${k.value} монет'),
                trailing: CoinPrice(k.price),
                onTap: () => Navigator.pop(c, k),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _offerUnlock(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Купить грядку?'),
        content: Text('Новая грядка стоит ${_farm.plotUnlockPrice} монет.'),
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
                leading: SpriteThumb('crop_${crop.id}_3'),
                title: Text(crop.name),
                subtitle: Text(crop.unlockLevel > _farm.level
                    ? 'Откроется на уровне ${crop.unlockLevel}'
                    : 'Растёт ${_format(crop.growSeconds)} · урожай ${crop.yieldCount} × ${crop.sellPrice}'),
                trailing: CoinPrice(crop.seedPrice),
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
      backgroundColor: const Color(0xFF6DAA2C),
      body: SafeArea(
        child: Column(
          children: [
            Hud(farm: _farm),
            // Scenery at the edges must not paint over the panels.
            Expanded(child: ClipRect(child: GameWidget(game: _game))),
            BottomBar(onFriends: _openFriends),
          ],
        ),
      ),
    );
  }
}
