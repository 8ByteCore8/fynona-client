import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

Map<String, Object?> tokens(String access, {String? refresh}) => {
  'session_id': '0193a1b2-0000-7000-8000-000000000001',
  'access_token': access,
  'token_type': 'Bearer',
  'expires_in': 900,
  'refresh_token': ?refresh,
  'refresh_expires_in': 2592000,
};

const profileJson = <String, Object?>{
  'id': '0193a1b2-0000-7000-8000-000000000002',
  'email': 'user@example.com',
  'email_verified': true,
  'display_name': '',
  'locale': 'uk',
  'display_currency': 'UAH',
  'created_at': '2026-11-27T12:00:00Z',
};

/// A secret store that cannot be used, like a missing keyring.
final class BrokenStore implements RefreshTokenStore {
  @override
  Future<String?> read() => Future.error(StateError('no keyring'));

  @override
  Future<void> write(String token) => Future.error(StateError('no keyring'));

  @override
  Future<void> clear() => Future.error(StateError('no keyring'));
}

Map<String, Object?> jsonOf(SeenRequest request) =>
    jsonDecode(request.body!) as Map<String, Object?>;

/// A fake server: `/v1/me` accepts only [validAccess]; refresh answers
/// [refreshReply] and counts the calls; logout accepts only [logoutAccess]
/// when it is set.
final class FakeServer {
  FakeServer({this.validAccess = 'a2', Responder? refreshReply})
    : refreshReply =
          refreshReply ?? status(200, json: tokens('a2', refresh: 'r2'));

  String validAccess;
  String? logoutAccess;
  final Responder refreshReply;
  int refreshes = 0;

  ResponseBody _unauthorized(SeenRequest request) => status(
    401,
    json: problemJson(401, 'auth.unauthorized'),
    contentType: 'application/problem+json',
  )(request);

  ResponseBody call(SeenRequest request) {
    switch (request.path) {
      case '/v1/auth/login':
        return status(200, json: tokens('a1', refresh: 'r1'))(request);
      case '/v1/auth/refresh':
        refreshes++;
        return refreshReply(request);
      case '/v1/auth/logout':
        final accepted = logoutAccess;
        if (accepted != null &&
            request.headers['Authorization'] != 'Bearer $accepted') {
          return _unauthorized(request);
        }
        return status(204)(request);
      case '/v1/me':
        if (request.headers['Authorization'] == 'Bearer $validAccess') {
          return status(200, json: profileJson)(request);
        }
        return _unauthorized(request);
    }
    return status(404)(request);
  }
}

void main() {
  late FakeAdapter adapter;
  late FakeServer server;
  late MemoryRefreshTokenStore store;
  late AuthSession session;

  AuthSession start(TokenMode mode) {
    final t = fakeTransport(adapter);
    return AuthSession(t.transport, mode: mode, store: store, device: 'test');
  }

  setUp(() {
    server = FakeServer();
    adapter = FakeAdapter([server.call]);
    store = MemoryRefreshTokenStore();
    session = start(TokenMode.body);
  });

  group('sign-in (SEC-3, SEC-4)', () {
    test('a password sign-in keeps the refresh token in the store', () async {
      final outcome = await session.login(
        email: 'user@example.com',
        password: 'secret-pass',
      );
      expect(outcome, isA<SignedIn>());
      expect(session.state, AuthState.signedIn);
      expect(session.accessToken, 'a1');
      expect(await store.read(), 'r1');
      final login = adapter.requests.single;
      expect(jsonOf(login), {
        'email': 'user@example.com',
        'password': 'secret-pass',
        'device': 'test',
        'token_delivery': 'body',
      });
      expect(login.headers, isNot(contains('Authorization')));
    });

    test('202 asks for a second factor; login/mfa opens the session', () async {
      adapter = FakeAdapter([
        status(
          202,
          json: {
            'mfa_token': 'm1',
            'expires_in': 300,
            'methods': ['totp', 'recovery_code'],
          },
        ),
        status(200, json: tokens('a1', refresh: 'r1')),
      ]);
      session = start(TokenMode.body);
      final outcome = await session.login(
        email: 'user@example.com',
        password: 'secret-pass',
      );
      expect(outcome, isA<MfaRequired>());
      expect(session.state, isNot(AuthState.signedIn));
      final challenge = (outcome as MfaRequired).challenge;
      await session.completeMfa(challenge, code: '123456');
      expect(session.state, AuthState.signedIn);
      expect(await store.read(), 'r1');
      final mfa = adapter.requests.last;
      expect(mfa.path, '/v1/auth/login/mfa');
      expect(jsonOf(mfa), {
        'mfa_token': 'm1',
        'code': '123456',
        'token_delivery': 'body',
      });
    });

    test('a refused sign-in throws its problem code', () async {
      adapter = FakeAdapter([
        status(
          401,
          json: problemJson(401, 'auth.invalid_credentials'),
          contentType: 'application/problem+json',
        ),
      ]);
      session = start(TokenMode.body);
      await expectLater(
        session.login(email: 'nobody@example.com', password: 'x'),
        throwsA(
          isA<ApiProblemException>().having(
            (e) => e.code,
            'code',
            'auth.invalid_credentials',
          ),
        ),
      );
      expect(session.accessToken, isNull);
    });
  });

  group('refresh on 401 (SEC-4)', () {
    test('a 401 refreshes once and repeats the request', () async {
      await session.login(email: 'user@example.com', password: 'p');
      final me = await session.transport.call((api) => api.account.getMe());
      expect(me.email.value, 'user@example.com');
      expect(adapter.requests.map((r) => r.path), [
        '/v1/auth/login',
        '/v1/me',
        '/v1/auth/refresh',
        '/v1/me',
      ]);
      final refresh = adapter.requests[2];
      expect(jsonOf(refresh), {
        'refresh_token': 'r1',
        'token_delivery': 'body',
      });
      expect(refresh.headers, isNot(contains('Authorization')));
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a2');
      expect(await store.read(), 'r2');
    });

    test('parallel 401s share one refresh (single flight)', () async {
      await session.login(email: 'user@example.com', password: 'p');
      final results = await Future.wait([
        for (var i = 0; i < 5; i++)
          session.transport.call((api) => api.account.getMe()),
      ]);
      expect(results, hasLength(5));
      expect(server.refreshes, 1);
    });

    test('a rejected refresh (reuse revocation) signs out', () async {
      server = FakeServer(
        refreshReply: status(
          401,
          json: problemJson(401, 'auth.unauthorized'),
          contentType: 'application/problem+json',
        ),
      );
      adapter = FakeAdapter([server.call]);
      session = start(TokenMode.body);
      final states = <AuthState>[];
      session.changes.listen(states.add);
      await session.login(email: 'user@example.com', password: 'p');
      await expectLater(
        session.transport.call((api) => api.account.getMe()),
        throwsA(isA<ApiProblemException>().having((e) => e.status, '', 401)),
      );
      expect(server.refreshes, 1);
      expect(session.state, AuthState.signedOut);
      expect(session.accessToken, isNull);
      expect(await store.read(), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(states, [AuthState.signedIn, AuthState.signedOut]);
    });

    test('a refresh without a connection keeps the session', () async {
      server = FakeServer(refreshReply: networkError());
      adapter = FakeAdapter([server.call]);
      session = start(TokenMode.body);
      await session.login(email: 'user@example.com', password: 'p');
      await expectLater(
        session.transport.call((api) => api.account.getMe()),
        throwsA(isA<ApiProblemException>()),
      );
      expect(session.state, AuthState.signedIn);
      expect(await store.read(), 'r1');
    });

    test('a 401 after the repeat is not refreshed again', () async {
      server.validAccess = 'never';
      await session.login(email: 'user@example.com', password: 'p');
      await expectLater(
        session.transport.call((api) => api.account.getMe()),
        throwsA(isA<ApiProblemException>()),
      );
      expect(server.refreshes, 1);
      expect(adapter.requests.where((r) => r.path == '/v1/me'), hasLength(2));
    });
  });

  group('restore and sign-out', () {
    test('without a stored token there is nothing to restore', () async {
      expect(await session.restore(), AuthState.signedOut);
      expect(adapter.requests, isEmpty);
    });

    test('a stored token resumes the session', () async {
      await store.write('r1');
      expect(await session.restore(), AuthState.signedIn);
      expect(session.accessToken, 'a2');
      expect(await store.read(), 'r2');
    });

    test('logout ends the session on the server and forgets it', () async {
      await session.login(email: 'user@example.com', password: 'p');
      await session.logout();
      final logout = adapter.requests.last;
      expect(logout.path, '/v1/auth/logout');
      expect(logout.headers['Authorization'], 'Bearer a1');
      expect(session.state, AuthState.signedOut);
      expect(session.accessToken, isNull);
      expect(await store.read(), isNull);
    });

    test('logout with a stale access token renews it once first', () async {
      server.logoutAccess = 'a2';
      await session.login(email: 'user@example.com', password: 'p');
      await session.logout();
      expect(adapter.requests.map((r) => r.path), [
        '/v1/auth/login',
        '/v1/auth/logout',
        '/v1/auth/refresh',
        '/v1/auth/logout',
      ]);
      expect(adapter.requests[1].headers['Authorization'], 'Bearer a1');
      expect(jsonOf(adapter.requests[2])['refresh_token'], 'r1');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a2');
      expect(server.refreshes, 1);
      expect(session.state, AuthState.signedOut);
      expect(session.accessToken, isNull);
      expect(await store.read(), isNull);
    });

    test(
      'logout with a stale token and a rejected refresh signs out',
      () async {
        server = FakeServer(
          refreshReply: status(
            401,
            json: problemJson(401, 'auth.unauthorized'),
            contentType: 'application/problem+json',
          ),
        )..logoutAccess = 'a2';
        adapter = FakeAdapter([server.call]);
        session = start(TokenMode.body);
        await session.login(email: 'user@example.com', password: 'p');
        await session.logout();
        expect(adapter.requests.map((r) => r.path), [
          '/v1/auth/login',
          '/v1/auth/logout',
          '/v1/auth/refresh',
        ]);
        expect(session.state, AuthState.signedOut);
        expect(await store.read(), isNull);
      },
    );

    test('logout without a connection still forgets the session', () async {
      await session.login(email: 'user@example.com', password: 'p');
      adapter.responders
        ..clear()
        ..add(networkError());
      await session.logout();
      expect(session.state, AuthState.signedOut);
      expect(await store.read(), isNull);
    });
  });

  group('a failing secret store', () {
    test('restore ends signed out when read and clear throw', () async {
      final t = fakeTransport(adapter);
      session = AuthSession(
        t.transport,
        mode: TokenMode.body,
        store: BrokenStore(),
      );
      expect(await session.restore(), AuthState.signedOut);
      expect(session.accessToken, isNull);
      expect(adapter.requests, isEmpty);
    });

    test(
      'a refresh token that cannot be written closes the new session',
      () async {
        final t = fakeTransport(adapter);
        session = AuthSession(
          t.transport,
          mode: TokenMode.body,
          store: BrokenStore(),
        );
        await expectLater(
          session.login(email: 'user@example.com', password: 'p'),
          throwsA(isA<StateError>()),
        );
        expect(session.accessToken, isNull);
        expect(session.state, AuthState.signedOut);
        final logout = adapter.requests.last;
        expect(logout.path, '/v1/auth/logout');
        expect(logout.headers['Authorization'], 'Bearer a1');
      },
    );
  });

  group('web cookie mode (SEC-5)', () {
    setUp(() {
      server = FakeServer(refreshReply: status(200, json: tokens('a2')));
      adapter = FakeAdapter([server.call]);
      session = start(TokenMode.cookie);
    });

    test('the refresh token never reaches the client', () async {
      await session.login(email: 'user@example.com', password: 'p');
      await session.transport.call((api) => api.account.getMe());
      expect(await store.read(), isNull);
      expect(jsonOf(adapter.requests.first)['token_delivery'], 'cookie');
      final refresh = adapter.requests.firstWhere(
        (r) => r.path == '/v1/auth/refresh',
      );
      expect(jsonOf(refresh), {'token_delivery': 'cookie'});
      expect(
        adapter.requests.map((r) => r.extra['withCredentials']),
        everyElement(true),
      );
    });

    test('restore asks the cookie for a session', () async {
      expect(await session.restore(), AuthState.signedIn);
      expect(session.accessToken, 'a2');
    });

    test('logout without an access token still clears the cookie', () async {
      await session.logout();
      expect(adapter.requests.map((r) => r.path), [
        '/v1/auth/refresh',
        '/v1/auth/logout',
      ]);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a2');
      expect(session.state, AuthState.signedOut);
      expect(session.accessToken, isNull);
    });

    test('logout with a stale access token renews the cookie once', () async {
      server.logoutAccess = 'a2';
      await session.login(email: 'user@example.com', password: 'p');
      await session.logout();
      expect(adapter.requests.map((r) => r.path), [
        '/v1/auth/login',
        '/v1/auth/logout',
        '/v1/auth/refresh',
        '/v1/auth/logout',
      ]);
      expect(jsonOf(adapter.requests[2]), {'token_delivery': 'cookie'});
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a2');
      expect(server.refreshes, 1);
      expect(session.state, AuthState.signedOut);
      expect(session.accessToken, isNull);
    });
  });

  group('Idempotency-Key exemptions (API-20)', () {
    test('auth and account credential routes take no key', () async {
      adapter = FakeAdapter([status(204)]);
      final t = fakeTransport(adapter);
      for (final (method, path) in [
        ('POST', '/v1/auth/login'),
        ('POST', '/v1/auth/refresh'),
        ('DELETE', '/v1/auth/passkeys/x'),
        ('DELETE', '/v1/me'),
        ('POST', '/v1/me/email'),
      ]) {
        await t.transport.dio.request<void>(
          path,
          options: Options(method: method),
        );
      }
      expect(
        adapter.requests.map((r) => r.headers.containsKey('Idempotency-Key')),
        everyElement(isFalse),
      );
    });

    test('other mutating routes keep the key', () async {
      adapter = FakeAdapter([status(204)]);
      final t = fakeTransport(adapter);
      await t.transport.dio.delete<void>('/v1/sessions/x');
      await t.transport.dio.patch<void>('/v1/me');
      expect(
        adapter.requests.map((r) => r.headers.containsKey('Idempotency-Key')),
        everyElement(isTrue),
      );
    });
  });
}
