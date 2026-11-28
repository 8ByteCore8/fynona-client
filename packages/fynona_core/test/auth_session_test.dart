import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fynona_core/fynona_core.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

/// A fictitious API's session routes; the core knows no real one.
const fictitious = AuthRoutes(
  login: '/x/v9/auth/login',
  loginMfa: '/x/v9/auth/login/mfa',
  refresh: '/x/v9/auth/refresh',
  logout: '/x/v9/auth/logout',
  passkeyLogin: '/x/v9/auth/passkeys/login',
  unauthenticated: {'/x/v9/auth/register'},
  refreshCookie: 'x_refresh',
);

/// Another one whose password step never answers tokens.
const secondFactorOnly = AuthRoutes(
  login: '/y/v2/session/start',
  loginMfa: '/y/v2/session/confirm',
  refresh: '/y/v2/session/renew',
  logout: '/y/v2/session/end',
  refreshCookie: 'y_refresh',
  loginTakesTokenDelivery: false,
);

const mePath = '/x/v9/me';

Map<String, Object?> tokens(String access, {String? refresh}) => {
  'session_id': '0193a1b2-0000-7000-8000-000000000001',
  'access_token': access,
  'token_type': 'Bearer',
  'expires_in': 900,
  'refresh_token': ?refresh,
  'refresh_expires_in': 2592000,
};

const challengeJson = <String, Object?>{
  'mfa_token': 'm1',
  'expires_in': 300,
  'methods': ['totp', 'recovery_code'],
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

ResponseBody problem(SeenRequest request, int code, String name) => status(
  code,
  json: problemJson(code, name),
  contentType: 'application/problem+json',
)(request);

/// A fake server of [routes]: [mePath] accepts only [validAccess] and
/// answers [meForbidden] when set; refresh counts its calls; logout accepts
/// only [logoutAccess] when it is set.
final class FakeServer {
  FakeServer(this.routes, {this.refreshOk = true});

  final AuthRoutes routes;
  bool refreshOk;
  String validAccess = 'a2';
  String? logoutAccess;
  String? meForbidden;
  int refreshes = 0;

  ResponseBody call(SeenRequest request) {
    final path = request.path;
    if (path == routes.login) {
      return status(200, json: tokens('a1', refresh: 'r1'))(request);
    }
    if (path == routes.loginMfa) {
      return status(200, json: tokens('a1', refresh: 'r1'))(request);
    }
    if (path == routes.refresh) {
      refreshes++;
      return refreshOk
          ? status(200, json: tokens('a2', refresh: 'r2'))(request)
          : problem(request, 401, 'auth.unauthorized');
    }
    if (path == routes.logout) {
      final accepted = logoutAccess;
      if (accepted != null &&
          request.headers['Authorization'] != 'Bearer $accepted') {
        return problem(request, 401, 'auth.unauthorized');
      }
      return status(204)(request);
    }
    if (path == mePath) {
      final forbidden = meForbidden;
      if (forbidden != null) return problem(request, 403, forbidden);
      if (request.headers['Authorization'] == 'Bearer $validAccess') {
        return status(200, json: {'id': 'u1'})(request);
      }
      return problem(request, 401, 'auth.unauthorized');
    }
    return status(404)(request);
  }
}

/// The session rules every API shares, on the routes of [routes].
void sessionRules(AuthRoutes routes) {
  late FakeAdapter adapter;
  late FakeServer server;
  late MemoryRefreshTokenStore store;

  AuthSession start({
    RefreshTokenStore? withStore,
    Set<String> revoking = const {},
    TokenMode mode = TokenMode.body,
  }) => AuthSession(
    fakeTransport(adapter).transport,
    routes: routes,
    mode: mode,
    store: withStore ?? store,
    device: 'test',
    revokingForbiddenCodes: revoking,
  );

  Future<Response<Object?>> me(AuthSession session) =>
      session.transport.call(() => session.transport.dio.get<Object?>(mePath));

  setUp(() {
    server = FakeServer(routes);
    adapter = FakeAdapter([server.call]);
    store = MemoryRefreshTokenStore();
  });

  test('parallel 401s share one refresh (single flight)', () async {
    final session = start();
    await session.login(email: 'user@example.com', password: 'p');
    final results = await Future.wait([
      for (var i = 0; i < 5; i++) me(session),
    ]);
    expect(results.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshes, 1);
    expect(
      adapter.requests.where((r) => r.path == routes.refresh),
      hasLength(1),
    );
  });

  test('a secret store that fails sends the user to sign-in', () async {
    final restored = start(withStore: BrokenStore());
    expect(await restored.restore(), AuthState.signedOut);
    expect(restored.accessToken, isNull);
    expect(adapter.requests, isEmpty);

    final login = start(withStore: BrokenStore());
    await expectLater(
      login.login(email: 'user@example.com', password: 'p'),
      throwsA(isA<StateError>()),
    );
    expect(login.state, AuthState.signedOut);
    expect(login.accessToken, isNull);
    expect(adapter.requests.last.path, routes.logout);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer a1');
  });

  test('logout with an expired access token refreshes first', () async {
    final session = start();
    server.logoutAccess = 'a2';
    await session.login(email: 'user@example.com', password: 'p');
    await session.logout();
    expect(adapter.requests.map((r) => r.path), [
      routes.login,
      routes.logout,
      routes.refresh,
      routes.logout,
    ]);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer a2');
    expect(session.state, AuthState.signedOut);
    expect(await store.read(), isNull);
  });

  test('403 with a revoking code signs out; other 403s do not', () async {
    final session = start(revoking: {'auth.not_admin'});
    await session.login(email: 'user@example.com', password: 'p');
    server.meForbidden = 'admin.owner_required';
    await expectLater(me(session), throwsA(isA<ApiProblemException>()));
    expect(session.state, AuthState.signedIn);
    server.meForbidden = 'auth.not_admin';
    await expectLater(
      me(session),
      throwsA(
        isA<ApiProblemException>().having((e) => e.code, '', 'auth.not_admin'),
      ),
    );
    expect(session.state, AuthState.signedOut);
    expect(session.accessToken, isNull);
    expect(await store.read(), isNull);
    expect(server.refreshes, 0);
  });

  test('session routes never carry Authorization', () async {
    final session = start();
    await session.login(email: 'user@example.com', password: 'p');
    await session.refresh();
    await me(session);
    final byPath = {for (final r in adapter.requests) r.path: r.headers};
    expect(byPath[routes.login], isNot(contains('Authorization')));
    expect(byPath[routes.refresh], isNot(contains('Authorization')));
    expect(byPath[mePath]!['Authorization'], 'Bearer a2');
  });
}

void main() {
  for (final routes in [fictitious, secondFactorOnly]) {
    group('session rules on ${routes.login}', () => sessionRules(routes));
  }

  group('request and answer shapes (SEC-2, SEC-5)', () {
    test('bodies of sign-in, second factor, refresh and passkey', () async {
      final adapter = FakeAdapter([
        status(202, json: challengeJson),
        status(200, json: tokens('a1', refresh: 'r1')),
        status(200, json: tokens('a2', refresh: 'r2')),
        status(200, json: tokens('a3', refresh: 'r3')),
      ]);
      final session = AuthSession(
        fakeTransport(adapter).transport,
        routes: fictitious,
        mode: TokenMode.body,
        device: 'test',
      );
      final outcome = await session.login(
        email: 'u@example.com',
        password: 'p',
      );
      final challenge = (outcome as AuthMfaRequired).challenge;
      expect(challenge.mfaToken, 'm1');
      expect(challenge.methods, ['totp', 'recovery_code']);
      expect(session.state, isNot(AuthState.signedIn));
      await session.completeMfa(challenge, recoveryCode: 'ABCD');
      await session.refresh();
      await session.loginWithPasskey(ceremonyId: 'c1', credential: {'id': 'k'});
      expect(adapter.requests.map(jsonOf), [
        {
          'email': 'u@example.com',
          'password': 'p',
          'device': 'test',
          'token_delivery': 'body',
        },
        {'mfa_token': 'm1', 'recovery_code': 'ABCD', 'token_delivery': 'body'},
        {'refresh_token': 'r1', 'token_delivery': 'body'},
        {
          'ceremony_id': 'c1',
          'credential': {'id': 'k'},
          'device': 'test',
          'token_delivery': 'body',
        },
      ]);
      expect(session.accessToken, 'a3');
    });

    test('a login that takes no token_delivery is sent without it', () async {
      final adapter = FakeAdapter([status(202, json: challengeJson)]);
      final session = AuthSession(
        fakeTransport(adapter).transport,
        routes: secondFactorOnly,
        mode: TokenMode.cookie,
      );
      await session.login(email: 'u@example.com', password: 'p');
      expect(jsonOf(adapter.requests.single), {
        'email': 'u@example.com',
        'password': 'p',
      });
      expect(
        () => session.loginWithPasskey(ceremonyId: 'c', credential: {}),
        throwsStateError,
      );
    });

    test('cookie mode never sees the refresh token', () async {
      final adapter = FakeAdapter([status(200, json: tokens('a1'))]);
      final store = MemoryRefreshTokenStore();
      final session = AuthSession(
        fakeTransport(adapter).transport,
        routes: fictitious,
        mode: TokenMode.cookie,
        store: store,
      );
      expect(await session.restore(), AuthState.signedIn);
      expect(jsonOf(adapter.requests.single), {'token_delivery': 'cookie'});
      expect(adapter.requests.single.extra['withCredentials'], isTrue);
      expect(await store.read(), isNull);
      expect(fictitious.refreshCookie, 'x_refresh');
    });

    test('a token answer without access_token is a format error', () {
      expect(
        () => AuthTokens.fromJson({'refresh_token': 'r'}),
        throwsFormatException,
      );
      expect(
        () => AuthChallenge.fromJson({
          ...challengeJson,
          'methods': [1],
        }),
        throwsFormatException,
      );
    });
  });
}
