import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:happy_farm/src/api.dart';

const farmJson = {
  'id': 1, 'name': 'Anna', 'coins': 200, 'xp': 0, 'level': 1, 'serverTime': 1000, 'plots': [],
};

void main() {
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
    await api.register('Anna');
    await api.farm();
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
