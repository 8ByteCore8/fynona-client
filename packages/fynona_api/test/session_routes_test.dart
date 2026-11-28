// The session rules of fynona_core on two route sets: the public API's and
// a fictitious one, so nothing in the rules depends on public paths.
import 'package:dio/dio.dart';
import 'package:fynona_api/fynona_api.dart' show publicAuthRoutes;
import 'package:fynona_core/fynona_core.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

const fictitiousAuthRoutes = AuthRoutes(
  login: '/x/v9/auth/login',
  loginMfa: '/x/v9/auth/login/mfa',
  refresh: '/x/v9/auth/refresh',
  logout: '/x/v9/auth/logout',
  refreshCookie: 'x_refresh',
);

Map<String, Object?> tokens(String access, String refresh) => {
  'session_id': '0193a1b2-0000-7000-8000-000000000001',
  'access_token': access,
  'token_type': 'Bearer',
  'expires_in': 900,
  'refresh_token': refresh,
  'refresh_expires_in': 2592000,
};

final class BrokenStore implements RefreshTokenStore {
  @override
  Future<String?> read() => Future.error(StateError('no keyring'));

  @override
  Future<void> write(String token) => Future.error(StateError('no keyring'));

  @override
  Future<void> clear() => Future.error(StateError('no keyring'));
}

ResponseBody problem(SeenRequest request, int code, String name) => status(
  code,
  json: problemJson(code, name),
  contentType: 'application/problem+json',
)(request);

/// A server of [routes] with one resource that accepts only `a2`.
final class RouteServer {
  RouteServer(this.routes);

  final AuthRoutes routes;
  static const resource = '/x/v9/things';
  String? logoutAccess;
  String? forbidden;
  int refreshes = 0;

  ResponseBody call(SeenRequest request) {
    final path = request.path;
    final bearer = request.headers['Authorization'];
    if (path == routes.login) {
      return status(200, json: tokens('a1', 'r1'))(request);
    }
    if (path == routes.refresh) {
      refreshes++;
      return status(200, json: tokens('a2', 'r2'))(request);
    }
    if (path == routes.logout) {
      final accepted = logoutAccess;
      return accepted != null && bearer != 'Bearer $accepted'
          ? problem(request, 401, 'auth.unauthorized')
          : status(204)(request);
    }
    if (path == resource) {
      final code = forbidden;
      if (code != null) return problem(request, 403, code);
      return bearer == 'Bearer a2'
          ? status(200, json: {})(request)
          : problem(request, 401, 'auth.unauthorized');
    }
    return status(404)(request);
  }
}

void main() {
  for (final (name, routes) in [
    ('public', publicAuthRoutes),
    ('fictitious /x/v9/auth/*', fictitiousAuthRoutes),
  ]) {
    group('session rules on the $name routes', () {
      late RouteServer server;
      late FakeAdapter adapter;
      late MemoryRefreshTokenStore store;

      AuthSession start({RefreshTokenStore? broken, Set<String>? revoking}) =>
          AuthSession(
            fakeTransport(adapter).transport.http,
            routes: routes,
            mode: TokenMode.body,
            store: broken ?? store,
            revokingForbiddenCodes: revoking ?? const {},
          );

      Future<Response<Object?>> resource(AuthSession session) => session
          .transport
          .call(() => session.transport.dio.get<Object?>(RouteServer.resource));

      setUp(() {
        server = RouteServer(routes);
        adapter = FakeAdapter([server.call]);
        store = MemoryRefreshTokenStore();
      });

      test('parallel 401s share one refresh', () async {
        final session = start();
        await session.login(email: 'user@example.com', password: 'p');
        await Future.wait([for (var i = 0; i < 5; i++) resource(session)]);
        expect(server.refreshes, 1);
        expect(session.accessToken, 'a2');
      });

      test('a failing secret store leads to sign-in', () async {
        final restored = start(broken: BrokenStore());
        expect(await restored.restore(), AuthState.signedOut);
        final login = start(broken: BrokenStore());
        await expectLater(
          login.login(email: 'user@example.com', password: 'p'),
          throwsA(isA<StateError>()),
        );
        expect(login.state, AuthState.signedOut);
        expect(login.accessToken, isNull);
        expect(adapter.requests.last.path, routes.logout);
      });

      test('logout with an expired token refreshes first', () async {
        server.logoutAccess = 'a2';
        final session = start();
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

      test('403 with a revoking code signs out', () async {
        final session = start(revoking: {'auth.not_admin'});
        await session.login(email: 'user@example.com', password: 'p');
        server.forbidden = 'auth.not_admin';
        await expectLater(
          resource(session),
          throwsA(isA<ApiProblemException>()),
        );
        expect(session.state, AuthState.signedOut);
        expect(await store.read(), isNull);
      });
    });
  }
}
