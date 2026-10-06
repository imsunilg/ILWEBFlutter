import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5080');
const angularUrl = String.fromEnvironment('ANGULAR_URL', defaultValue: 'http://localhost:4200');

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Holds the session and talks to the ILAPI. Refreshes the access token once on 401.
class ApiClient extends ChangeNotifier {
  static const _key = 'il.session';
  Map<String, dynamic>? _session;

  bool get isLoggedIn => _session != null;
  String get userName => (_session?['user']?['fullName'] as String?) ?? '';

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw != null) {
      _session = jsonDecode(raw) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) =>
      _auth('/api/auth/login', {'email': email, 'password': password});

  Future<void> register(String email, String password, String fullName) =>
      _auth('/api/auth/register', {'email': email, 'password': password, 'fullName': fullName});

  Future<void> logout() async {
    _session = null;
    (await SharedPreferences.getInstance()).remove(_key);
    notifyListeners();
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);

  /// Creates a one-time token and returns the Angular portal URL that exchanges it.
  Future<Uri> angularHandoffUrl() async {
    final r = await post('/api/auth/handoff');
    return Uri.parse('$angularUrl/handoff').replace(queryParameters: {'token': r['token'] as String});
  }

  Future<void> _auth(String path, Map<String, String> body) async {
    final res = await http.post(Uri.parse('$apiUrl$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final data = _decode(res);
    await _save(data as Map<String, dynamic>);
  }

  Future<bool> _refresh() async {
    final rt = _session?['refreshToken'];
    if (rt == null) return false;
    final res = await http.post(Uri.parse('$apiUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': rt}));
    if (res.statusCode != 200) {
      await logout();
      return false;
    }
    await _save(jsonDecode(res.body) as Map<String, dynamic>);
    return true;
  }

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    Future<http.Response> once() async {
      final req = http.Request(method, Uri.parse('$apiUrl$path'))
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer ${_session?['accessToken']}';
      if (body != null) req.body = jsonEncode(body);
      return http.Response.fromStream(await req.send());
    }

    var res = await once();
    if (res.statusCode == 401 && await _refresh()) res = await once();
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final parsed = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return parsed;
    final msg = parsed is Map && parsed['error'] is String ? parsed['error'] as String : 'Request failed (${res.statusCode})';
    throw ApiException(msg);
  }

  Future<void> _save(Map<String, dynamic> s) async {
    _session = s;
    (await SharedPreferences.getInstance()).setString(_key, jsonEncode(s));
    notifyListeners();
  }
}
