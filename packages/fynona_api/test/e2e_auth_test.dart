@Tags(['e2e'])
library;

import 'dart:io' as io;

import 'package:dio/dio.dart' show Options;
import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

/// End to end against a running sandbox server (card client-auth criterion
/// 5): register, confirm the email with the link the sandbox mailer writes to
/// the server log, sign in, `GET /v1/me`, refresh, sign out.
///
/// ```sh
/// FYNONA_API_URL=http://127.0.0.1:8080 FYNONA_SERVER_LOG=/path/to/server.log \
///   dart test test/e2e_auth_test.dart
/// ```
void main() {
  final env = io.Platform.environment;
  final baseUrl = env['FYNONA_API_URL'] ?? '';
  final logPath = env['FYNONA_SERVER_LOG'] ?? '';
  final skip = baseUrl.isEmpty
      ? 'FYNONA_API_URL is not set; start the sandbox server and set it to run this test'
      : logPath.isEmpty
      ? 'FYNONA_SERVER_LOG is not set; point it at the sandbox server log'
      : false;

  /// The token of the newest verification link mailed to [email]: in local
  /// and sandbox the server's mailer writes every message to its log.
  Future<String> verificationToken(String email) async {
    final link = RegExp(r'verify-email\?token=([A-Za-z0-9_.~%-]+)');
    for (var attempt = 0; attempt < 50; attempt++) {
      final lines = io.File(logPath).readAsLinesSync();
      for (final line in lines.reversed) {
        final match = link.firstMatch(line);
        if (match != null && line.contains(email)) {
          return Uri.decodeComponent(match[1]!);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('no verification link for the new account in the log');
  }

  test('register → verify → sign in → /v1/me → refresh → sign out', () async {
    final transport = ApiTransport(
      baseUrl: baseUrl,
      clientVersion: '0.1.0',
      platform: 'linux',
    );
    addTearDown(transport.close);
    final store = MemoryRefreshTokenStore();
    final session = AuthSession(
      transport,
      mode: TokenMode.body,
      store: store,
      device: 'e2e',
    );
    final email = 'e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    const password = 'e2e-password-1';

    await transport.call(
      (api) => api.auth.registerAccount(
        body: RegisterRequest(
          email: Email(email),
          password: const NewPassword(password),
        ),
      ),
    );
    await expectLater(
      session.login(email: email, password: password),
      throwsA(
        isA<ApiProblemException>().having(
          (e) => e.code,
          'code',
          'auth.email_unverified',
        ),
      ),
    );

    final token = await verificationToken(email);
    await transport.call(
      (api) => api.auth.verifyEmail(body: LinkTokenRequest(token: token)),
    );

    expect(
      await session.login(email: email, password: password),
      isA<SignedIn>(),
    );
    final firstRefresh = await store.read();
    expect(firstRefresh, isNotNull);

    final me = await transport.call((api) => api.account.getMe());
    expect(me.email.value, email);
    expect(me.emailVerified, isTrue);

    final firstAccess = session.accessToken;
    expect(await session.refresh(), isTrue);
    expect(session.accessToken, isNot(firstAccess));
    expect(await store.read(), isNot(firstRefresh));
    expect(
      (await transport.call((api) => api.account.getMe())).email.value,
      email,
    );

    final lastAccess = session.accessToken!;
    await session.logout();
    expect(session.state, AuthState.signedOut);
    expect(await store.read(), isNull);
    await expectLater(
      transport.call(
        (api) => api.account.getMe(
          options: Options(headers: {'Authorization': 'Bearer $lastAccess'}),
        ),
      ),
      throwsA(
        isA<ApiProblemException>().having((e) => e.status, 'status', 401),
      ),
    );
  }, skip: skip);
}
