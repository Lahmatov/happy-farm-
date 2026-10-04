import 'dart:async';
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

class StealResult {
  final int amount;
  final int earned;
  final int xp;
  final Farm farm;
  StealResult(this.amount, this.earned, this.xp, this.farm);
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;
  String? token;

  ApiClient({required this.baseUrl, this.token, http.Client? client, this.timeout = const Duration(seconds: 15)}) : _http = client ?? http.Client();

  /// Sends a request and parses the JSON reply with [parse]. Anything unexpected
  /// (non-JSON body, missing or mistyped field) becomes an [ApiException].
  Future<T> _call<T>(String method, String path, T Function(dynamic json) parse, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
    final http.Response res;
    try {
      res = method == 'GET'
          ? await _http.get(uri, headers: headers).timeout(timeout)
          : await _http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(timeout);
    } on http.ClientException {
      throw ApiException(0, 'Нет связи с сервером');
    } on TimeoutException {
      throw ApiException(0, 'Нет связи с сервером');
    }
    try {
      // Decode bytes as UTF-8 ourselves: `res.body` falls back to latin1 without a charset.
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 400) {
        throw ApiException(res.statusCode, (decoded is Map ? decoded['error'] : null)?.toString() ?? 'Ошибка ${res.statusCode}');
      }
      return parse(decoded);
    } on FormatException {
      // Status 0, not res.statusCode: an HTML 401 from a captive portal or proxy must not
      // look like "the server rejected my token" (that logs the player out).
      throw ApiException(0, 'Неожиданный ответ сервера (${res.statusCode})');
    } on TypeError {
      throw ApiException(res.statusCode, 'Неожиданный ответ сервера');
    }
  }

  static Farm _farm(dynamic j) => Farm.fromJson(j as Map<String, dynamic>);

  /// Registers a new player and keeps the returned token.
  ///
  /// [clientId] is a random secret kept for the whole sign-up attempt: if the reply is
  /// lost and we retry, the server returns the same account instead of "name taken".
  Future<Farm> register(String name, String clientId) async {
    final (t, farm) = await _call('POST', '/register', (j) {
      j as Map<String, dynamic>;
      return (j['token'] as String, _farm(j['farm']));
    }, {'name': name, 'clientId': clientId});
    token = t; // only keep a token from a fully valid reply
    return farm;
  }

  Future<List<Crop>> catalog() async {
    return _call('GET', '/catalog', (j) => (j as List).map((c) => Crop.fromJson(c as Map<String, dynamic>)).toList());
  }

  Future<Farm> farm() => _call('GET', '/farm', _farm);

  Future<Farm> plant(int plot, String cropId) =>
      _call('POST', '/plant', _farm, {'plot': plot, 'cropId': cropId});

  Future<HarvestResult> harvest(int plot) async {
    return _call('POST', '/harvest', (j) {
      j as Map<String, dynamic>;
      return HarvestResult(j['earned'] as int, j['xp'] as int, j['levelUp'] as bool, _farm(j['farm']));
    }, {'plot': plot});
  }

  Future<Farm> unlockPlot() => _call('POST', '/unlock-plot', _farm);

  static List<Friend> _friends(dynamic j) => (j as List).map((f) => Friend.fromJson(f as Map<String, dynamic>)).toList();

  Future<List<Friend>> friends() => _call('GET', '/friends', _friends);

  /// Friendship is mutual, as in VK.
  Future<List<Friend>> addFriend(String name) => _call('POST', '/friends', _friends, {'name': name});

  Future<Farm> friendFarm(int friendId) => _call('GET', '/friends/$friendId/farm', _farm);

  Future<StealResult> steal(int friendId, int plot) => _call('POST', '/friends/$friendId/steal', (j) {
        j as Map<String, dynamic>;
        return StealResult(j['amount'] as int, j['earned'] as int, j['xp'] as int, _farm(j['farm']));
      }, {'plot': plot});

  Future<List<AnimalKind>> animalCatalog() => _call(
      'GET', '/animal-catalog', (j) => (j as List).map((a) => AnimalKind.fromJson(a as Map<String, dynamic>)).toList());

  Future<Farm> buyAnimal(int slot, String kind) => _call('POST', '/animals/buy', _farm, {'slot': slot, 'kind': kind});

  Future<HarvestResult> collectAnimal(int slot) => _call('POST', '/animals/collect', (j) {
        j as Map<String, dynamic>;
        return HarvestResult(j['earned'] as int, j['xp'] as int, j['levelUp'] as bool, _farm(j['farm']));
      }, {'slot': slot});
}
