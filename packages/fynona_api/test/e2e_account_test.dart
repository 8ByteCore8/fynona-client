@Tags(['e2e'])
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

/// End to end against a running sandbox server (card client-account
/// criterion 6): enable TOTP → sign out → sign in with a code → the export
/// finishes → delete the account → sign-in fails.
///
/// ```sh
/// FYNONA_API_URL=http://127.0.0.1:8080 FYNONA_SERVER_LOG=/path/to/server.log \
///   dart test test/e2e_account_test.dart
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

  Future<String> verificationToken(String email) async {
    final link = RegExp(r'verify-email\?token=([A-Za-z0-9_.~%-]+)');
    for (var attempt = 0; attempt < 50; attempt++) {
      for (final line in io.File(logPath).readAsLinesSync().reversed) {
        final match = link.firstMatch(line);
        if (match != null && line.contains(email)) {
          return Uri.decodeComponent(match[1]!);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('no verification link for the new account in the log');
  }

  test(
    'TOTP on → sign out → sign in with a code → export → delete → sign-in fails',
    () async {
      final transport = ApiTransport(
        baseUrl: baseUrl,
        clientVersion: '0.1.0',
        platform: 'linux',
      );
      addTearDown(transport.close);
      final session = AuthSession(
        transport,
        mode: TokenMode.body,
        store: MemoryRefreshTokenStore(),
        device: 'e2e',
      );
      final email =
          'e2e-acc-${DateTime.now().microsecondsSinceEpoch}@example.com';
      const password = 'e2e-password-1';

      await transport.call(
        (api) => api.auth.registerAccount(
          body: RegisterRequest(
            email: Email(email),
            password: const NewPassword(password),
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

      // Enable TOTP with the first code of the enrolled secret.
      final enrollment = await transport.call((api) => api.auth.enrollTotp());
      expect(enrollment.otpauthUri, startsWith('otpauth://totp/'));
      final step = _step(DateTime.now());
      final recovery = await transport.call(
        (api) => api.auth.verifyTotp(
          body: TotpCodeRequest(code: TotpCode(_totp(enrollment.secret, step))),
        ),
      );
      expect(recovery.codes, hasLength(10));
      expect(
        (await transport.call((api) => api.auth.getTotp())).enabled,
        isTrue,
      );

      await session.logout();
      expect(session.state, AuthState.signedOut);

      // A code is single-use: sign in with the next time step's code.
      while (_step(DateTime.now()) == step) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final outcome = await session.login(email: email, password: password);
      expect(outcome, isA<MfaRequired>());
      await session.completeMfa(
        (outcome as MfaRequired).challenge,
        code: _totp(enrollment.secret, _step(DateTime.now())),
      );
      expect(session.state, AuthState.signedIn);

      // The export finishes and its archive downloads.
      var export = await transport.call(
        (api) => api.account.startExport(idempotencyKey: UuidV7().next()),
      );
      const ready = ExportStatusKnown(ExportStatusValue.ready);
      for (var i = 0; i < 120 && export.status != ready; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final id = export.id;
        export = await transport.call((api) => api.account.getExport(id: id));
      }
      expect(export.status, ready);
      final archive = jsonDecode(
        utf8.decode(await transport.downloadExportArchive(export.id)),
      ) as Map<String, Object?>;
      expect(archive['format'], 'fynona-export-v1');

      // Delete with the password and a recovery code.
      await transport.call(
        (api) => api.account.deleteAccount(
          body: DeleteAccountRequest(
            password: password,
            recoveryCode: recovery.codes.first,
          ),
        ),
      );
      await session.signOutLocally();

      await expectLater(
        session.login(email: email, password: password),
        throwsA(
          isA<ApiProblemException>().having(
            (e) => e.code,
            'code',
            'auth.invalid_credentials',
          ),
        ),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

int _step(DateTime now) => now.millisecondsSinceEpoch ~/ 30000;

/// RFC 6238 TOTP: SHA1, six digits, 30-second steps (as the server enrolls).
String _totp(String base32Secret, int step) {
  final counter = List<int>.generate(8, (i) => (step >> (8 * (7 - i))) & 0xff);
  final hash = Hmac(sha1, _base32(base32Secret)).convert(counter).bytes;
  final offset = hash.last & 0x0f;
  final value =
      ((hash[offset] & 0x7f) << 24) |
      (hash[offset + 1] << 16) |
      (hash[offset + 2] << 8) |
      hash[offset + 3];
  return (value % 1000000).toString().padLeft(6, '0');
}

List<int> _base32(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final bytes = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final char in input.toUpperCase().replaceAll('=', '').split('')) {
    buffer = (buffer << 5) | alphabet.indexOf(char);
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      bytes.add((buffer >> bits) & 0xff);
    }
  }
  return bytes;
}
