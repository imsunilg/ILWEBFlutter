import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Holds the session and talks to the ILAPI. Refreshes the access token once on 401.
/// The server is the authority for roles/permissions; they are only used here to shape the UI.
class ApiClient extends ChangeNotifier {
  static const _key = 'il.session';
  Map<String, dynamic>? _session;

  bool get isLoggedIn => _session != null;
  Map<String, dynamic>? get _user => _session?['user'] as Map<String, dynamic>?;
  String get userName => (_user?['displayName'] as String?) ?? '';
  String get role => (_user?['role'] as String?) ?? '';
  List<String> get permissions => ((_user?['permissions'] as List<dynamic>?) ?? const []).cast<String>();
  bool has(String permission) => permissions.contains(permission);

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw != null) {
      _session = jsonDecode(raw) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) =>
      _auth('login', {'username': username, 'password': password});

  Future<void> register(String email, String password, String fullName) =>
      _auth('register', {'email': email, 'password': password, 'fullName': fullName});

  Future<void> logout() async {
    final rt = _session?['refreshToken'];
    if (rt != null) {
      // best effort: revoke the refresh token on the server
      try {
        await http.post(Uri.parse('$apiUrl/api/v1/auth/logout'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': rt}));
      } catch (_) {}
    }
    _session = null;
    (await SharedPreferences.getInstance()).remove(_key);
    notifyListeners();
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);

  /// Creates a one-time token and returns the Angular portal URL that exchanges it.
  Future<Uri> angularHandoffUrl() async {
    final r = await post('/api/v1/auth/handoff');
    return Uri.parse('$angularUrl/handoff').replace(queryParameters: {'token': r['token'] as String});
  }

  Future<void> _auth(String path, Map<String, String> body) async {
    final res = await http.post(Uri.parse('$apiUrl/api/v1/auth/$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    await _save(_decode(res) as Map<String, dynamic>);
  }

  Future<bool> _refresh() async {
    final rt = _session?['refreshToken'];
    if (rt == null) return false;
    final res = await http.post(Uri.parse('$apiUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': rt}));
    if (res.statusCode != 200) {
      _session = null;
      (await SharedPreferences.getInstance()).remove(_key);
      notifyListeners();
      return false;
    }
    await _save(_decode(res) as Map<String, dynamic>);
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

  /// Unwraps the `{success, message, data}` envelope used by the auth endpoints.
  dynamic _decode(http.Response res) {
    dynamic parsed;
    try {
      parsed = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return parsed is Map && parsed.containsKey('success') ? parsed['data'] : parsed;
    }
    if (res.statusCode == 403) throw ApiException('You do not have permission to do that.', 403);
    final msg = parsed is Map
        ? (parsed['message'] ?? parsed['error'] ?? 'Request failed (${res.statusCode})') as String
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }

  Future<void> _save(Map<String, dynamic> s) async {
    _session = s;
    (await SharedPreferences.getInstance()).setString(_key, jsonEncode(s));
    notifyListeners();
  }
}
