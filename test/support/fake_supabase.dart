import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, GotrueAsyncStorage, SupabaseClient;

/// PKCE akışı için bellek içi depolama (uygulamada SharedPreferences kullanılır).
class MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getItem({required String key}) async => _data[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _data[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _data.remove(key);
}

/// Sunucuya giden bir isteğin kaydı.
class Call {
  Call(this.method, this.url, this.body, this.headers);
  final String method;
  final Uri url;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
  String get path => url.path;
}

typedef Route = http.Response Function(http.Request request);

/// Gerçek ağ olmadan çalışan Supabase istemcisi. İstekler `calls` içine yazılır,
/// yanıtlar `routes['METHOD /yol']` ile verilir. Yolu tanımsız istek 500 döner.
class FakeSupabase {
  FakeSupabase() {
    client = SupabaseClient(
      'https://test.supabase.co',
      'anon-key',
      httpClient: MockClient(_handle),
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: MemoryAsyncStorage(),
      ),
    );
  }

  late final SupabaseClient client;
  final List<Call> calls = [];
  final Map<String, Route> routes = {};

  /// Bu yola gitmiş istekler.
  List<Call> to(String method, String path) =>
      calls.where((c) => c.method == method && c.path == path).toList();

  Future<http.Response> _handle(http.Request r) async {
    Map<String, dynamic>? body;
    if (r.body.isNotEmpty) {
      final decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }
    calls.add(Call(r.method, r.url, body, r.headers));
    final route = routes['${r.method} ${r.url.path}'];
    final res = route == null
        ? http.Response(
            jsonEncode({'msg': 'tanımsız yol ${r.method} ${r.url.path}'}),
            500,
          )
        : route(r);
    // Gerçek istemci yanıta isteği iliştirir; postgrest buna güvenir.
    return http.Response(
      res.body,
      res.statusCode,
      request: r,
      headers: res.headers,
    );
  }

  void on(String key, Route route) => routes[key] = route;
}

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> userJson({
  String email = 'ayse@ornek.com',
  String first = 'Ayşe',
  String last = 'Yılmaz',
  String phone = '',
}) => {
  'id': '11111111-1111-4111-8111-111111111111',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': email,
  'created_at': '2026-11-24T10:00:00Z',
  'app_metadata': {'provider': 'email'},
  'user_metadata': {'first_name': first, 'last_name': last, 'phone': phone},
};

Map<String, dynamic> sessionJson({Map<String, dynamic>? user}) => {
  'access_token': 'access-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh-token',
  'user': user ?? userJson(),
};

Map<String, dynamic> errorJson(String code, String msg, int status) => {
  'code': status,
  'error_code': code,
  'msg': msg,
};
