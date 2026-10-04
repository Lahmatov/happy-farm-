import 'package:flutter/material.dart';

import 'models.dart';

const ink = Color(0xFF3D2A12);

/// A sprite PNG shown as a list icon or HUD glyph.
class SpriteThumb extends StatelessWidget {
  final String name;
  final double size;
  const SpriteThumb(this.name, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/sprites/$name.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // A missing asset must not crash the screen.
        errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
      );
}

class CoinPrice extends StatelessWidget {
  final int amount;
  const CoinPrice(this.amount, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$amount', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const SpriteThumb('icon_coin', size: 20),
        ],
      );
}

/// Wooden top panel: level star and name on the left, coins on the right, XP bar below.
class Hud extends StatelessWidget {
  final Farm farm;
  const Hud({super.key, required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB87A3D), Color(0xFF8F5A26)]),
        border: Border(bottom: BorderSide(color: ink, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Stack(
                alignment: const Alignment(0, 0.1),
                children: [
                  const SpriteThumb('icon_star', size: 40),
                  Text('${farm.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, shadows: [Shadow(color: ink, blurRadius: 3), Shadow(color: ink, blurRadius: 3)])),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(farm.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, shadows: [Shadow(color: ink, blurRadius: 3)])),
              ),
              _Pill(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SpriteThumb('icon_coin', size: 22),
                  const SizedBox(width: 6),
                  Text('${farm.coins}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 12, color: const Color(0x66000000)),
                FractionallySizedBox(
                  widthFactor: levelProgress(farm.xp, farm.level),
                  child: Container(height: 12, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9BE15D), Color(0xFF4CAE2F)]))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ink, width: 2.5),
        ),
        child: child,
      );
}

/// Bottom wooden bar with the main actions.
class BottomBar extends StatelessWidget {
  final VoidCallback onFriends;
  const BottomBar({super.key, required this.onFriends});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB87A3D), Color(0xFF8F5A26)]),
        border: Border(top: BorderSide(color: ink, width: 3)),
      ),
      child: Center(
        child: FilledButton.icon(
          onPressed: onFriends,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF58B83A),
            foregroundColor: Colors.white,
            minimumSize: const Size(160, 46),
            side: const BorderSide(color: ink, width: 2.5),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          icon: const Icon(Icons.group),
          label: const Text('Соседи'),
        ),
      ),
    );
  }
}
