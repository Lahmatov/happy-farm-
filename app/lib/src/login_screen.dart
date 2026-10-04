import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'messages.dart';
import 'widgets.dart';
import 'models.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final Future<void> Function(String token) saveToken;
  final void Function(Farm farm) onLoggedIn;
  const LoginScreen({super.key, required this.api, required this.saveToken, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  // One id per screen lifetime, so a retry after a lost reply reuses the account.
  final _clientId = List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final farm = await widget.api.register(_name.text, _clientId);
      try {
        await widget.saveToken(widget.api.token!);
      } catch (_) {
        // The account exists already; let the player in for this session rather than
        // stranding them (registering again would fail with "name taken").
      }
      widget.onLoggedIn(farm);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = localize(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA8DCF5), Color(0xFF8CC63F), Color(0xFF6DAA2C)], stops: [0, 0.45, 1]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SpriteThumb('decor_barn', size: 150),
                        SpriteThumb('decor_tree', size: 110),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Счастливая ферма',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFE066),
                        shadows: [Shadow(color: ink, blurRadius: 0, offset: Offset(2, 2)), Shadow(color: ink, blurRadius: 0, offset: Offset(-2, 2)), Shadow(color: ink, blurRadius: 0, offset: Offset(2, -2)), Shadow(color: ink, blurRadius: 0, offset: Offset(-2, -2))],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ink, width: 3),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            maxLength: 20,
                            decoration: InputDecoration(labelText: 'Имя фермера', errorText: _error),
                            onSubmitted: (_) => _busy ? null : _submit(),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF58B83A),
                                side: const BorderSide(color: ink, width: 2.5),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Начать играть'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
