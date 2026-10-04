import 'package:flutter/material.dart';

import 'api.dart';
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
      final farm = await widget.api.register(_name.text);
      await widget.saveToken(widget.api.token!);
      widget.onLoggedIn(farm);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌾 Счастливая ферма', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    maxLength: 20,
                    decoration: InputDecoration(labelText: 'Имя фермера', errorText: _error),
                    onSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const CircularProgressIndicator() : const Text('Начать играть'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
