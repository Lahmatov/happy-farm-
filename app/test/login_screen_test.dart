import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';
import 'package:happy_farm/src/login_screen.dart';
import 'package:happy_farm/src/models.dart';

void main() {
  testWidgets('a Keychain failure does not strand a freshly registered player', (tester) async {
    final farmJson = {
      'id': 1, 'name': 'Anna', 'coins': 200, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000, 'plots': [],
    };
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response(jsonEncode({'token': 't', 'farm': farmJson}), 201)),
    );
    Farm? loggedIn;
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        api: api,
        saveToken: (_) async => throw Exception('keychain unavailable'),
        onLoggedIn: (f) => loggedIn = f,
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    expect(loggedIn?.name, 'Anna');
  });

  testWidgets('a server error is shown under the name field', (tester) async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response(jsonEncode({'error': 'name taken'}), 409)),
    );
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(api: api, saveToken: (_) async {}, onLoggedIn: (_) {}),
    ));
    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    expect(find.text('name taken'), findsOneWidget);
  });
}
