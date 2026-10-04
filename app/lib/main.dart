import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'src/api.dart';
import 'src/farm_screen.dart';
import 'src/login_screen.dart';
import 'src/models.dart';
import 'src/notifications.dart';

const _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
const _tokenKey = 'token';

void main() => runApp(const HappyFarmApp());

class HappyFarmApp extends StatefulWidget {
  const HappyFarmApp({super.key});

  @override
  State<HappyFarmApp> createState() => _HappyFarmAppState();
}

class _HappyFarmAppState extends State<HappyFarmApp> {
  final _storage = const FlutterSecureStorage(); // iOS Keychain
  final _api = ApiClient(baseUrl: _apiUrl);
  final _reminder = ReadyReminder(LocalNotificationScheduler());
  late Future<Farm?> _start = _restoreSession();
  Farm? _farm;

  Future<Farm?> _restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    _api.token = token;
    try {
      return await _api.farm();
    } on ApiException catch (e) {
      // Only a rejected token logs the player out; a network error must not.
      if (e.status == 401) {
        await _storage.delete(key: _tokenKey);
        return null;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Счастливая ферма',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: FutureBuilder<Farm?>(
        future: _start,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snap.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _start = _restoreSession()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }
          final farm = _farm ?? snap.data;
          if (farm != null) return FarmScreen(api: _api, initial: farm, reminder: _reminder);
          return LoginScreen(
            api: _api,
            saveToken: (t) => _storage.write(key: _tokenKey, value: t),
            onLoggedIn: (f) => setState(() => _farm = f),
          );
        },
      ),
    );
  }
}
