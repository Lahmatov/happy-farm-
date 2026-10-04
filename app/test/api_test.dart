import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';

const farmJson = {
  'id': 1, 'name': 'Anna', 'coins': 200, 'xp': 0, 'level': 1, 'plotUnlockPrice': 500, 'serverTime': 1000, 'plots': [],
};

void main() {
  errorCases();
  test('register stores the token and sends it on later calls', () async {
    final seen = <http.Request>[];
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        seen.add(req);
        if (req.url.path == '/register') return http.Response(jsonEncode({'token': 'abc', 'farm': farmJson}), 201);
        return http.Response(jsonEncode(farmJson), 200);
      }),
    );
    await api.register('Anna', 'c' * 32);
    await api.farm();
    expect(jsonDecode(seen[0].body)['clientId'], 'c' * 32);
    expect(seen[0].headers['authorization'], isNull);
    expect(seen[1].headers['authorization'], 'Bearer abc');
  });

  test('server errors become ApiException with the server message', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response(jsonEncode({'error': 'not enough coins'}), 402)),
    );
    expect(
      api.plant(0, 'corn'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 402).having((e) => e.message, 'message', 'not enough coins')),
    );
  });

  test('network failure is reported as status 0', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => throw http.ClientException('down')));
    expect(api.farm(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });
}

void errorCases() {
  test('an HTML 401 (captive portal) is NOT reported as a rejected token', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response('<html>Login</html>', 401)));
    expect(api.farm(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });

  test('a real JSON 401 keeps status 401', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response(jsonEncode({'error': 'unauthorized'}), 401)));
    expect(api.farm(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
  });

  test('a hanging request times out as status 0', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) => Completer<http.Response>().future), timeout: const Duration(milliseconds: 50));
    expect(api.farm(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });

  test('a non-JSON reply (e.g. an HTML 502) becomes ApiException', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response('<html>Bad Gateway</html>', 502)));
    expect(api.farm(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });

  test('a reply with a missing field becomes ApiException, not a crash', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response(jsonEncode({'id': 1}), 200)));
    expect(api.farm(), throwsA(isA<ApiException>()));
  });

  test('register does not keep a token when the reply is malformed', () async {
    final api = ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response(jsonEncode({'token': 'abc'}), 201)));
    await expectLater(api.register('Anna', 'c' * 32), throwsA(isA<ApiException>()));
    expect(api.token, isNull);
  });
}
