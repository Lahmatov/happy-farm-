import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);

  @override
  String toString() => message;
}

class HarvestResult {
  final int earned;
  final int xp;
  final bool levelUp;
  final Farm farm;
  HarvestResult(this.earned, this.xp, this.levelUp, this.farm);
}

class ApiClient {
  final String baseUrl;
  final http.Client _http;
  String? token;

  ApiClient({required this.baseUrl, this.token, http.Client? client}) : _http = client ?? http.Client();

  Future<Map<String, dynamic>> _call(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
    final http.Response res;
    try {
      res = method == 'GET'
          ? await _http.get(uri, headers: headers)
          : await _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } on http.ClientException {
      throw ApiException(0, 'Нет связи с сервером');
    }
    // Decode bytes as UTF-8 ourselves: `res.body` falls back to latin1 without a charset.
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, (decoded is Map ? decoded['error'] : null)?.toString() ?? 'Ошибка ${res.statusCode}');
    }
    return decoded is Map<String, dynamic> ? decoded : {'items': decoded};
  }

  /// Registers a new player and keeps the returned token.
  Future<Farm> register(String name) async {
    final j = await _call('POST', '/register', {'name': name});
    token = j['token'] as String;
    return Farm.fromJson(j['farm'] as Map<String, dynamic>);
  }

  Future<List<Crop>> catalog() async {
    final j = await _call('GET', '/catalog');
    return (j['items'] as List).map((c) => Crop.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Farm> farm() async => Farm.fromJson(await _call('GET', '/farm'));

  Future<Farm> plant(int plot, String cropId) async =>
      Farm.fromJson(await _call('POST', '/plant', {'plot': plot, 'cropId': cropId}));

  Future<HarvestResult> harvest(int plot) async {
    final j = await _call('POST', '/harvest', {'plot': plot});
    return HarvestResult(j['earned'] as int, j['xp'] as int, j['levelUp'] as bool,
        Farm.fromJson(j['farm'] as Map<String, dynamic>));
  }

  Future<Farm> unlockPlot() async => Farm.fromJson(await _call('POST', '/unlock-plot'));
}
