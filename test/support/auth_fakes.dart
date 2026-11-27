import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fynona_api/fynona_api.dart' show RefreshTokenStore;

import 'api_fakes.dart';

/// A platform secret store that cannot be used, like Linux without a
/// keyring: every call fails.
final class BrokenRefreshTokenStore implements RefreshTokenStore {
  @override
  Future<String?> read() => Future.error(StateError('no keyring'));

  @override
  Future<void> write(String token) => Future.error(StateError('no keyring'));

  @override
  Future<void> clear() => Future.error(StateError('no keyring'));
}

/// A fake Fynona server for the auth flows: one account
/// `user@example.com` / `right-password`, TOTP code `123456`, recovery code
/// `ABCD-EFGH`, link token `good`.
final class FakeAuthServer {
  FakeAuthServer({this.totp = false, this.validRefresh = 'r0'});

  /// Whether the account has TOTP on (login answers `202`).
  bool totp;

  /// The refresh token the server still accepts.
  String? validRefresh;

  /// The access token the server still accepts.
  String? validAccess;

  final requests = <RequestOptions>[];

  late final adapter = ScriptedAdapter(_respond);

  /// Requests to [path], in order.
  List<RequestOptions> to(String path) => [
    for (final r in requests)
      if (r.path == path) r,
  ];

  /// The JSON body of [request].
  static Map<String, Object?> bodyOf(RequestOptions request) {
    final data = request.data;
    if (data is String) return jsonDecode(data) as Map<String, Object?>;
    return (data as Map<String, Object?>?) ?? const {};
  }

  static ResponseBody json(int status, Map<String, Object?> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  static ResponseBody empty(int status) => ResponseBody.fromString('', status);

  Map<String, Object?> _tokens(String n) => {
    'session_id': '0193a1b2-0000-7000-8000-00000000000$n',
    'access_token': 'a$n',
    'token_type': 'Bearer',
    'expires_in': 900,
    'refresh_token': 'r$n',
    'refresh_expires_in': 2592000,
  };

  ResponseBody _signIn(String n) {
    validRefresh = 'r$n';
    validAccess = 'a$n';
    return json(200, _tokens(n));
  }

  ResponseBody _respond(RequestOptions o) {
    requests.add(o);
    if (o.path == '/v1/meta') return meta()(o);
    final body = o.method == 'GET' ? const <String, Object?>{} : bodyOf(o);
    switch (o.path) {
      case '/v1/auth/login':
        if (body['email'] != 'user@example.com' ||
            body['password'] != 'right-password') {
          return problem(401, 'auth.invalid_credentials')(o);
        }
        if (totp) {
          return json(202, {
            'mfa_token': 'm1',
            'expires_in': 300,
            'methods': ['totp', 'recovery_code'],
          });
        }
        return _signIn('1');
      case '/v1/auth/login/mfa':
        if (body['code'] == '123456' || body['recovery_code'] == 'ABCD-EFGH') {
          return _signIn('1');
        }
        return problem(403, 'auth.mfa_invalid')(o);
      case '/v1/auth/refresh':
        if (validRefresh != null && body['refresh_token'] == validRefresh) {
          return _signIn('2');
        }
        return problem(401, 'auth.unauthorized')(o);
      case '/v1/auth/logout':
        validRefresh = null;
        return empty(204);
      case '/v1/auth/register' || '/v1/auth/password/reset':
        return empty(202);
      case '/v1/auth/email/verify' || '/v1/auth/password/reset/confirm':
        return body['token'] == 'good'
            ? empty(204)
            : problem(400, 'auth.link_invalid')(o);
      case '/v1/auth/passkeys/login/options':
        return json(200, {
          'ceremony_id': '0193a1b2-0000-7000-8000-0000000000c1',
          'options': {
            'publicKey': {'challenge': 'Y2hhbGxlbmdl'},
          },
        });
      case '/v1/auth/passkeys/login':
        return _signIn('1');
      case '/v1/me':
        if (validAccess == null ||
            o.headers['Authorization'] != 'Bearer $validAccess') {
          return problem(401, 'auth.unauthorized')(o);
        }
        return json(200, {
          'id': '0193a1b2-0000-7000-8000-0000000000aa',
          'email': 'user@example.com',
          'email_verified': true,
          'display_name': '',
          'locale': 'uk',
          'display_currency': 'UAH',
          'created_at': '2026-11-27T12:00:00Z',
        });
    }
    return problem(404, 'not_found')(o);
  }
}
