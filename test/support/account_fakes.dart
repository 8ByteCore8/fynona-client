import 'package:dio/dio.dart';

import 'api_fakes.dart';
import 'auth_fakes.dart';

/// A fake Fynona server for the account, security and entitlement screens:
/// password `right-password`, TOTP code `123456`, two sessions (this one and
/// a laptop), plans `free` and `pro`. Set [exceed] to answer a route with
/// `402 entitlement.exceeded`.
final class FakeAccountServer {
  FakeAccountServer({this.totp = false});

  bool totp;
  int recoveryLeft = 10;
  int version = 3;
  String? pendingEmail;
  bool deleted = false;

  /// The account password; any text, sent as typed.
  String password = 'right-password';

  /// `GET /v1/auth/totp` fails with `400`.
  bool totpStatusFails = false;

  /// The id of the data export.
  String exportId = '0193a1b2-0000-7000-8000-0000000000e1';

  /// GETs of an export answered `pending` before it is `ready`.
  int exportPolls = 1;

  /// GETs of an export answered with [exportError] before the ones above.
  int exportErrors = 0;
  ({int status, String code, String? retryAfter}) exportError = (
    status: 400,
    code: 'request.invalid',
    retryAfter: null,
  );

  /// A path answered with `402 entitlement.exceeded` naming this entitlement.
  ({String path, String entitlement})? exceed;

  final profile = <String, Object?>{
    'id': '0193a1b2-0000-7000-8000-0000000000aa',
    'email': 'user@example.com',
    'email_verified': true,
    'display_name': 'Olena',
    'locale': 'uk',
    'display_currency': 'UAH',
    'created_at': '2026-11-27T12:00:00Z',
  };

  final sessions = <Map<String, Object?>>[
    {
      'id': 's-this',
      'device': 'Fynona linux',
      'ip': '10.0.0.1',
      'user_agent': 'Fynona/0.1.0 (linux)',
      'created_at': '2026-11-27T10:00:00Z',
      'last_used_at': '2026-11-27T12:00:00Z',
      'current': true,
    },
    {
      'id': 's-laptop',
      'device': 'Fynona web',
      'ip': '192.0.2.7',
      'user_agent': 'Mozilla/5.0',
      'created_at': '2026-11-20T10:00:00Z',
      'last_used_at': '2026-11-26T09:30:00Z',
      'current': false,
    },
    {
      'id': 's-phone',
      'device': '',
      'ip': '192.0.2.8',
      'user_agent': 'Fynona/0.1.0 (ios)',
      'created_at': '2026-11-21T10:00:00Z',
      'last_used_at': '2026-11-25T09:30:00Z',
      'current': false,
    },
  ];

  final passkeys = <Map<String, Object?>>[
    {'id': 'p1', 'name': 'MacBook', 'created_at': '2026-11-27T12:00:00Z'},
  ];

  final requests = <RequestOptions>[];
  late final adapter = ScriptedAdapter(_respond);

  /// Requests to [path] with [method], in order.
  List<RequestOptions> to(String method, String path) => [
    for (final r in requests)
      if (r.method == method && r.path == path) r,
  ];

  static final codes = [for (var i = 0; i < 10; i++) 'CODE-000$i'];

  ResponseBody _json(int status, Map<String, Object?> body, {String? etag}) {
    final response = FakeAuthServer.json(status, body);
    if (etag != null) response.headers['etag'] = [etag];
    return response;
  }

  ResponseBody _me() => _json(200, {
    ...profile,
    'pending_email': ?pendingEmail,
  }, etag: '"$version"');

  ResponseBody _respond(RequestOptions o) {
    requests.add(o);
    final path = o.path;
    final exceed = this.exceed;
    if (exceed != null && path == exceed.path) {
      return FakeAuthServer.json(402, {
        'type': 'urn:fynona:problem:entitlement.exceeded',
        'title': 'Problem',
        'status': 402,
        'code': 'entitlement.exceeded',
        'request_id': 'req-402',
        'entitlement': exceed.entitlement,
      })..headers['content-type'] = ['application/problem+json'];
    }
    if (path == '/v1/meta') return meta()(o);
    final body = o.method == 'GET' || o.data == null
        ? const <String, Object?>{}
        : FakeAuthServer.bodyOf(o);
    final mfaInvalid = problem(403, 'auth.mfa_invalid')(o);
    switch ((o.method, path)) {
      case ('POST', '/v1/auth/refresh'):
        return _json(200, {
          'session_id': 's-this',
          'access_token': 'a1',
          'token_type': 'Bearer',
          'expires_in': 900,
          'refresh_token': 'r1',
          'refresh_expires_in': 2592000,
        });
      case ('GET', '/v1/sessions'):
        return _json(200, {'items': sessions});
      case ('DELETE', final p) when p.startsWith('/v1/sessions/'):
        sessions.removeWhere((s) => '/v1/sessions/${s['id']}' == p);
        return FakeAuthServer.empty(204);
      case ('GET', '/v1/auth/totp'):
        if (totpStatusFails) return problem(400, 'request.invalid')(o);
        return _json(200, {
          'enabled': totp,
          'recovery_codes_left': totp ? recoveryLeft : 0,
        });
      case ('POST', '/v1/auth/totp/enroll'):
        return _json(200, {
          'secret': 'JBSWY3DPEHPK3PXP',
          'otpauth_uri': 'otpauth://totp/Fynona:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Fynona',
        });
      case ('POST', '/v1/auth/totp/verify'):
        if (body['code'] != '123456') return mfaInvalid;
        totp = true;
        recoveryLeft = 10;
        return _json(200, {'codes': codes});
      case ('POST', '/v1/auth/totp/recovery-codes'):
        if (body['code'] != '123456') return mfaInvalid;
        recoveryLeft = 10;
        return _json(200, {'codes': codes});
      case ('POST', '/v1/auth/totp/disable'):
        if (body['code'] != '123456' && body['password'] != password) {
          return mfaInvalid;
        }
        totp = false;
        return FakeAuthServer.empty(204);
      case ('GET', '/v1/auth/passkeys'):
        return _json(200, {'items': passkeys});
      case ('POST', '/v1/auth/passkeys/register/options'):
        return _json(200, {
          'ceremony_id': '0193a1b2-0000-7000-8000-0000000000c2',
          'options': {
            'publicKey': {'challenge': 'Y2hhbGxlbmdl'},
          },
        });
      case ('POST', '/v1/auth/passkeys/register'):
        final passkey = {
          'id': 'p${passkeys.length + 1}',
          'name': body['name'] ?? 'Passkey',
          'created_at': '2026-11-27T13:00:00Z',
        };
        passkeys.add(passkey);
        return _json(201, passkey);
      case ('DELETE', final p) when p.startsWith('/v1/auth/passkeys/'):
        passkeys.removeWhere((k) => '/v1/auth/passkeys/${k['id']}' == p);
        return FakeAuthServer.empty(204);
      case ('GET', '/v1/me'):
        return _me();
      case ('PATCH', '/v1/me'):
        if (o.headers['If-Match'] != '"$version"') {
          return problem(412, 'precondition.failed')(o);
        }
        profile.addAll(body);
        version++;
        return _me();
      case ('POST', '/v1/me/email'):
        if (body['password'] != password ||
            (totp &&
                body['code'] != '123456' &&
                body['recovery_code'] != codes.first)) {
          return mfaInvalid;
        }
        pendingEmail = body['email']! as String;
        version++;
        return _me();
      case ('DELETE', '/v1/me'):
        if (body['password'] != password ||
            (totp && body['code'] != '123456')) {
          return mfaInvalid;
        }
        deleted = true;
        return FakeAuthServer.empty(204);
      case ('POST', '/v1/me/export'):
        return _export(202, pending: true);
      case ('GET', final p) when p == '/v1/me/export/$exportId':
        if (exportErrors > 0) {
          exportErrors--;
          final (:status, :code, :retryAfter) = exportError;
          final response = problem(status, code)(o);
          if (retryAfter != null) {
            response.headers['retry-after'] = [retryAfter];
          }
          return response;
        }
        return _export(200, pending: exportPolls-- > 0);
      case ('GET', final p) when p == '/v1/me/export/$exportId/archive':
        return FakeAuthServer.json(200, {
          'format': 'fynona-export-v1',
          'generated_at': '2026-11-27T12:00:00Z',
        });
      case ('GET', '/v1/entitlements'):
        return _json(200, {'plan': 'free', 'entitlements': _free});
      case ('GET', '/v1/plans'):
        return _json(200, {
          'items': [
            {'code': 'free', 'name': 'Free', 'entitlements': _free},
            {
              'code': 'pro',
              'name': 'Pro',
              'entitlements': {
                ..._free,
                'connections.max': null,
                'connectors.business': true,
                'sync.min_interval': 900,
              },
            },
          ],
        });
    }
    return problem(404, 'not_found')(o);
  }

  ResponseBody _export(int status, {required bool pending}) => _json(status, {
    'id': exportId,
    'status': pending ? 'pending' : 'ready',
    'created_at': '2026-11-27T12:00:00Z',
    if (!pending) 'expires_at': '2026-11-27T13:00:00Z',
  });

  static const _free = <String, Object?>{
    'profiles.max': 1,
    'connections.max': 2,
    'connectors.business': false,
    'sync.min_interval': 3600,
    'exports': ['csv'],
  };
}
