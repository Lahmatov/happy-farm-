import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'farm_game.dart';
import 'messages.dart';
import 'models.dart';

/// A neighbour's farm: tap a ripe plot to steal from it.
class FriendFarmScreen extends StatefulWidget {
  final ApiClient api;
  final Friend friend;
  const FriendFarmScreen({super.key, required this.api, required this.friend});

  @override
  State<FriendFarmScreen> createState() => _FriendFarmScreenState();
}

class _FriendFarmScreenState extends State<FriendFarmScreen> {
  Farm? _farm;
  String? _error;
  late final FarmGame _game = FarmGame(onPlotTap: _onPlotTap);
  Timer? _ticker;
  int _clockOffset = 0;

  int get _serverNow => DateTime.now().millisecondsSinceEpoch ~/ 1000 + _clockOffset;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final farm = _farm;
      if (farm != null) _game.setFarm(farm, _serverNow);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final farm = await widget.api.friendFarm(widget.friend.id);
      _clockOffset = farm.serverTime - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _game.setFarm(farm, farm.serverTime);
      if (!mounted) return;
      setState(() {
        _farm = farm;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = localize(e.message));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  Future<void> _onPlotTap(int index) async {
    final farm = _farm;
    if (farm == null) return;
    if (stageOf(farm.plots[index], _serverNow) != PlotStage.ripe) {
      _toast('Красть можно только созревший урожай');
      return;
    }
    try {
      final r = await widget.api.steal(widget.friend.id, index);
      _toast('Украдено ${r.amount} шт.: +${r.earned} монет, +${r.xp} опыта');
      await _load(); // the owner's plot now shows less crop
    } on ApiException catch (e) {
      _toast(localize(e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ферма: ${widget.friend.name}')),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text(_error!))
            : _farm == null
                ? const Center(child: CircularProgressIndicator())
                : GameWidget(game: _game),
      ),
    );
  }
}
