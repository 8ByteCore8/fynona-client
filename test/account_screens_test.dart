// Ще → Безпека, Акаунт, Підписка (CLI-12, SEC-1, SEC-2, SEC-4, SEC-60,
// API-23, MON-3, MON-4): sessions, 2FA, web passkeys, account settings,
// email change, export, deletion, entitlements and the 402 plan offer.
import 'dart:convert';

import 'package:dio/dio.dart' show RequestOptions;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/account/account.dart';
import 'package:fynona/api/api.dart';
import 'package:fynona/app.dart';
import 'package:fynona/auth/auth.dart';
import 'package:fynona/screens/account/account_screen.dart';
import 'package:fynona/screens/account/account_widgets.dart';
import 'package:fynona/screens/account/security_screen.dart';
import 'package:fynona/screens/account/subscription_screen.dart';
import 'package:fynona/screens/account/totp_setup_screen.dart';
import 'package:fynona/screens/auth/sign_in_screen.dart';
import 'package:fynona/screens/more_screen.dart' show moreEntryKey;
import 'package:fynona/shell/router.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:material_ui/material_ui.dart';

import 'semantics_test.dart' show unlabelledInteractiveNodes;
import 'support/account_fakes.dart';
import 'support/api_fakes.dart';
import 'support/auth_fakes.dart';
import 'support/harness.dart';

late FakeAccountServer server;
late List<(String, String)> saved;
late List<String> clipboard;

Future<void> pumpAt(
  WidgetTester tester,
  String at, {
  List<Locale> locales = const [Locale('uk')],
  PasskeyRegistrar? passkeys,
}) => pumpApp(
  tester,
  initialLocation: at,
  locales: locales,
  size: const Size(800, 1200),
  transport: fakeApiTransport(server.adapter),
  // A real session, resumed from a stored refresh token.
  signedIn: false,
  store: MemoryRefreshTokenStore()..write('r0'),
  overrides: [
    passkeyRegistrarProvider.overrideWithValue(passkeys),
    exportPollIntervalProvider.overrideWithValue(
      const Duration(milliseconds: 100),
    ),
    fileSaverProvider.overrideWithValue((name, bytes, _) async {
      saved.add((name, utf8.decode(bytes)));
      return name;
    }),
  ],
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FynonaApp)));

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, Key key, String text) async {
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

Map<String, Object?> bodyOf(RequestOptions r) => FakeAuthServer.bodyOf(r);

/// Lets [time] pass and the answers that came in it land. The export
/// spinner never settles, so its tests pump by hand.
Future<void> wait(WidgetTester tester, Duration time) async {
  await tester.pump(time);
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

List<RequestOptions> exportPolls() =>
    server.to('GET', '/v1/me/export/${server.exportId}');

Future<void> startExport(WidgetTester tester) async {
  await pumpAt(tester, accountPath);
  await tester.ensureVisible(find.byKey(exportStartKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(exportStartKey));
  await wait(tester, Duration.zero);
}

Future<Map<String, Object?>> fakeCredential(Map<String, Object?> _) async => {
  'id': 'cred',
  'type': 'public-key',
};

void main() {
  setUp(() {
    server = FakeAccountServer();
    saved = [];
    clipboard = [];
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
  });

  group('screens are reachable from Ще, localized and labelled', () {
    const screens = {
      securityPath: ('Безпека', 'Безопасность', 'Security'),
      accountPath: ('Акаунт', 'Аккаунт', 'Account'),
      subscriptionPath: ('Підписка', 'Подписка', 'Subscription'),
    };
    for (final MapEntry(key: path, value: titles) in screens.entries) {
      for (final (lang, title) in [
        ('uk', titles.$1),
        ('ru', titles.$2),
        ('en', titles.$3),
      ]) {
        testWidgets('$path in $lang', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpAt(tester, morePath, locales: [Locale(lang)]);
          await tapKey(tester, moreEntryKey(path));
          expect(find.text(title), findsWidgets);
          expect(unlabelledInteractiveNodes(tester), isEmpty);
          semantics.dispose();
        });
      }
    }
  });

  group('sessions (SEC-4)', () {
    testWidgets('list device, IP, last use and this device', (tester) async {
      await pumpAt(tester, securityPath);
      final mine = find.byKey(sessionTileKey('s-this'));
      expect(
        find.descendant(of: mine, matching: find.text('Fynona linux')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: mine,
          matching: find.textContaining('Цей пристрій · 10.0.0.1 · востаннє'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(sessionRevokeKey('s-this')), findsNothing);
      // A session without a device name shows its user agent.
      expect(find.text('Fynona/0.1.0 (ios)'), findsOneWidget);
      expect(find.textContaining('192.0.2.7'), findsOneWidget);
    });

    testWidgets('end one session', (tester) async {
      await pumpAt(tester, securityPath);
      await tapKey(tester, sessionRevokeKey('s-laptop'));
      final revoke = server.to('DELETE', '/v1/sessions/s-laptop').single;
      expect(revoke.headers['Idempotency-Key'], isNotNull);
      expect(find.byKey(sessionTileKey('s-laptop')), findsNothing);
      expect(find.byKey(sessionTileKey('s-phone')), findsOneWidget);
    });

    testWidgets('end all other sessions after confirming', (tester) async {
      await pumpAt(tester, securityPath);
      await tapKey(tester, revokeOtherSessionsKey);
      expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
      await tapKey(tester, confirmDialogOkKey);
      expect(server.to('DELETE', '/v1/sessions/s-laptop'), hasLength(1));
      expect(server.to('DELETE', '/v1/sessions/s-phone'), hasLength(1));
      expect(server.to('DELETE', '/v1/sessions/s-this'), isEmpty);
      expect(find.byKey(sessionTileKey('s-this')), findsOneWidget);
      expect(find.byKey(revokeOtherSessionsKey), findsNothing);
    });
  });

  group('two-factor authentication (SEC-2)', () {
    testWidgets('enable: QR, manual key, code, recovery codes once', (
      tester,
    ) async {
      await pumpAt(tester, securityPath);
      await tapKey(tester, totpEnableKey);
      expect(find.byKey(totpQrKey), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR-код для застосунку-автентифікатора'),
        findsOneWidget,
      );
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
      await tapKey(tester, totpSecretCopyKey);
      expect(clipboard.last, 'JBSWY3DPEHPK3PXP');

      await enter(tester, totpSetupCodeKey, '000000');
      await tapKey(tester, totpSetupSubmitKey);
      expect(find.text('Неправильний код'), findsOneWidget);
      expect(server.totp, isFalse);

      await enter(tester, totpSetupCodeKey, '123456');
      await tapKey(tester, totpSetupSubmitKey);
      expect(server.totp, isTrue);
      for (final code in FakeAccountServer.codes) {
        expect(find.textContaining(code), findsOneWidget);
      }
      await tapKey(tester, recoveryCodesCopyKey);
      expect(clipboard.last, FakeAccountServer.codes.join('\n'));
      await tapKey(tester, recoveryCodesSaveKey);
      expect(saved.single.$1, 'fynona-recovery-codes.txt');
      expect(saved.single.$2, '${FakeAccountServer.codes.join('\n')}\n');

      await tapKey(tester, totpSetupDoneKey);
      expect(find.byType(SecurityScreen), findsOneWidget);
      expect(find.text('Увімкнено'), findsOneWidget);
      expect(find.text('Резервних кодів залишилось: 10'), findsOneWidget);
      // Shown once: nothing of them stays on screen.
      expect(find.textContaining('CODE-0000'), findsNothing);
    });

    testWidgets('regenerate the recovery codes with a code', (tester) async {
      server
        ..totp = true
        ..recoveryLeft = 2;
      await pumpAt(tester, securityPath);
      expect(find.text('Резервних кодів залишилось: 2'), findsOneWidget);
      await tapKey(tester, totpRegenerateKey);
      await enter(tester, totpCodeFieldKey, '123456');
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('POST', '/v1/auth/totp/recovery-codes').single), {
        'code': '123456',
      });
      expect(find.textContaining('CODE-0009'), findsOneWidget);
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(find.text('Резервних кодів залишилось: 10'), findsOneWidget);
    });

    testWidgets('disable needs a confirmation with a code or the password', (
      tester,
    ) async {
      server.totp = true;
      await pumpAt(tester, securityPath);
      await tapKey(tester, totpDisableKey);
      final submit = find.byKey(formDialogSubmitKey);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await enter(tester, totpPasswordFieldKey, 'wrong');
      await tapKey(tester, formDialogSubmitKey);
      expect(find.text('Неправильний код'), findsOneWidget);
      expect(server.totp, isTrue);
      await enter(tester, totpPasswordFieldKey, 'right-password');
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('POST', '/v1/auth/totp/disable').last), {
        'password': 'right-password',
      });
      expect(server.totp, isFalse);
      expect(find.byKey(totpEnableKey), findsOneWidget);
    });
  });

  group('passkeys on web (SEC-1)', () {
    testWidgets('hidden where passkeys are not offered', (tester) async {
      await pumpAt(tester, securityPath);
      expect(find.byKey(passkeyAddKey), findsNothing);
      expect(server.to('GET', '/v1/auth/passkeys'), isEmpty);
    });

    testWidgets('list, add and delete', (tester) async {
      Map<String, Object?>? options;
      await pumpAt(
        tester,
        securityPath,
        passkeys: (o) async {
          options = o;
          return fakeCredential(o);
        },
      );
      expect(find.text('MacBook'), findsOneWidget);

      await tapKey(tester, passkeyAddKey);
      await enter(tester, passkeyNameFieldKey, 'Pixel');
      await tapKey(tester, formDialogSubmitKey);
      expect(options, {
        'publicKey': {'challenge': 'Y2hhbGxlbmdl'},
      });
      expect(bodyOf(server.to('POST', '/v1/auth/passkeys/register').single), {
        'ceremony_id': '0193a1b2-0000-7000-8000-0000000000c2',
        'name': 'Pixel',
        'credential': {'id': 'cred', 'type': 'public-key'},
      });
      expect(find.text('Pixel'), findsOneWidget);

      await tapKey(tester, passkeyDeleteKey('p1'));
      await tapKey(tester, confirmDialogOkKey);
      expect(server.to('DELETE', '/v1/auth/passkeys/p1'), hasLength(1));
      expect(find.text('MacBook'), findsNothing);
    });
  });

  group('account (API-23, SEC-3, SEC-60)', () {
    testWidgets('edit name, language and currency against the version', (
      tester,
    ) async {
      await pumpAt(tester, accountPath);
      await enter(tester, accountNameKey, 'Olena K.');
      await enter(tester, accountCurrencyKey, 'eur');
      await tapKey(tester, accountLocaleKey);
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tapKey(tester, accountSaveKey);
      final patch = server.to('PATCH', '/v1/me').single;
      expect(patch.headers['If-Match'], '"3"');
      expect(patch.headers['Idempotency-Key'], isNotNull);
      expect(bodyOf(patch), {
        'display_name': 'Olena K.',
        'locale': 'en',
        'display_currency': 'EUR',
      });
      expect(find.text('Збережено'), findsOneWidget);
    });

    testWidgets('a stale version reloads and says so', (tester) async {
      await pumpAt(tester, accountPath);
      server
        ..version = 4
        ..profile['display_name'] = 'Changed elsewhere';
      await enter(tester, accountNameKey, 'Mine');
      await tapKey(tester, accountSaveKey);
      expect(find.textContaining('змінено в іншому місці'), findsOneWidget);
      expect(find.text('Changed elsewhere'), findsOneWidget);
    });

    testWidgets('an invalid currency is not sent', (tester) async {
      await pumpAt(tester, accountPath);
      await enter(tester, accountCurrencyKey, 'hryvnia');
      await tapKey(tester, accountSaveKey);
      expect(server.to('PATCH', '/v1/me'), isEmpty);
      expect(find.textContaining('трьох латинських літер'), findsOneWidget);
    });

    testWidgets('change email with re-authentication: pending state', (
      tester,
    ) async {
      server.totp = true;
      await pumpAt(tester, accountPath);
      expect(find.byKey(emailPendingKey), findsNothing);
      await tapKey(tester, emailChangeKey);
      await enter(tester, emailNewFieldKey, 'new@example.com');
      await enter(tester, reauthPasswordKey, 'right-password');
      await enter(tester, reauthCodeKey, '123456');
      await tapKey(tester, formDialogSubmitKey);
      final post = server.to('POST', '/v1/me/email').single;
      expect(post.headers['If-Match'], '"3"');
      expect(post.headers, isNot(contains('Idempotency-Key')));
      expect(bodyOf(post), {
        'email': 'new@example.com',
        'password': 'right-password',
        'code': '123456',
      });
      expect(find.text('user@example.com'), findsOneWidget);
      expect(
        find.text(
          'Очікує підтвердження: new@example.com. Відкрийте посилання з листа.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('export: start, progress, download', (tester) async {
      await startExport(tester);
      expect(find.byKey(exportProgressKey), findsOneWidget);
      expect(find.text('Готуємо архів…'), findsOneWidget);
      expect(
        server.to('POST', '/v1/me/export').single.headers['Idempotency-Key'],
        isNotNull,
      );
      // First poll: still pending; second: ready.
      await wait(tester, const Duration(milliseconds: 100));
      expect(exportPolls(), hasLength(1));
      expect(find.byKey(exportProgressKey), findsOneWidget);
      await wait(tester, const Duration(milliseconds: 100));
      expect(exportPolls(), hasLength(2));
      await tester.pumpAndSettle();
      expect(find.byKey(exportDownloadKey), findsOneWidget);
      await tapKey(tester, exportDownloadKey);
      final name = 'fynona-export-${server.exportId}.json';
      expect(saved.single.$1, name);
      expect(
        jsonDecode(saved.single.$2),
        containsPair('format', 'fynona-export-v1'),
      );
      expect(find.text('Збережено: $name'), findsOneWidget);
    });

    testWidgets('export: a Retry-After of a failed poll is the wait', (
      tester,
    ) async {
      server
        ..exportPolls = 0
        ..exportErrors = 100
        ..exportError = (status: 429, code: 'rate_limited', retryAfter: '5');
      await startExport(tester);
      await wait(tester, const Duration(milliseconds: 100));
      // The transport's own retries of the 429 are in this count.
      final failed = exportPolls().length;
      expect(failed, greaterThan(0));
      server.exportErrors = 0;
      expect(find.byKey(exportProgressKey), findsOneWidget);
      await wait(tester, const Duration(seconds: 4));
      expect(exportPolls(), hasLength(failed));
      await wait(tester, const Duration(seconds: 1));
      expect(exportPolls(), hasLength(failed + 1));
      await tester.pumpAndSettle();
      expect(find.byKey(exportDownloadKey), findsOneWidget);
    });

    testWidgets('export: polling backs off and stops after failures', (
      tester,
    ) async {
      server
        ..exportPolls = 0
        ..exportErrors = 3;
      await startExport(tester);
      // Waits of 100, 200 and 400 ms: three failed polls, then none.
      for (final (ms, polls) in [
        (100, 1),
        (150, 1),
        (100, 2),
        (300, 2),
        (150, 3),
      ]) {
        await wait(tester, Duration(milliseconds: ms));
        expect(exportPolls(), hasLength(polls));
      }
      await wait(tester, const Duration(minutes: 5));
      expect(exportPolls(), hasLength(3));
      expect(find.byKey(exportProgressKey), findsNothing);
      await tapKey(tester, exportRetryKey);
      expect(exportPolls(), hasLength(4));
      expect(find.byKey(exportDownloadKey), findsOneWidget);
    });

    testWidgets('export: a 404 poll stops and offers a new export', (
      tester,
    ) async {
      server
        ..exportErrors = 1
        ..exportError = (status: 404, code: 'not_found', retryAfter: null);
      await startExport(tester);
      await wait(tester, const Duration(milliseconds: 100));
      expect(exportPolls(), hasLength(1));
      await wait(tester, const Duration(minutes: 1));
      expect(exportPolls(), hasLength(1));
      expect(find.byKey(exportStartKey), findsOneWidget);
    });

    testWidgets('a server export id that is not a UUID names no path', (
      tester,
    ) async {
      server
        ..exportId = 'e1'
        ..exportPolls = 0;
      await startExport(tester);
      await wait(tester, const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tapKey(tester, exportDownloadKey);
      expect(saved.single.$1, 'fynona-export.json');
    });

    testWidgets('delete: typed confirmation, re-authentication, signed out', (
      tester,
    ) async {
      server.totp = true;
      await pumpAt(tester, accountPath);
      await tapKey(tester, deleteAccountKey);
      final submit = find.byKey(formDialogSubmitKey);
      await enter(tester, reauthPasswordKey, 'right-password');
      await enter(tester, reauthCodeKey, '123456');
      await enter(tester, deleteConfirmFieldKey, 'user@example');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await enter(tester, deleteConfirmFieldKey, 'user@example.com');
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tapKey(tester, formDialogSubmitKey);
      final delete = server.to('DELETE', '/v1/me').single;
      expect(bodyOf(delete), {'password': 'right-password', 'code': '123456'});
      expect(delete.headers, isNot(contains('Idempotency-Key')));
      expect(server.deleted, isTrue);
      expect(containerOf(tester).read(authStateProvider), AuthState.signedOut);
      expect(find.byKey(signInSubmitKey), findsOneWidget);
    });

    testWidgets('a wrong password keeps the account', (tester) async {
      await pumpAt(tester, accountPath);
      await tapKey(tester, deleteAccountKey);
      await enter(tester, reauthPasswordKey, 'wrong');
      await enter(tester, deleteConfirmFieldKey, 'user@example.com');
      await tapKey(tester, formDialogSubmitKey);
      expect(server.deleted, isFalse);
      expect(find.text('Неправильний код'), findsOneWidget);
      expect(containerOf(tester).read(authStateProvider), AuthState.signedIn);
    });

    const spacedPassword = '  spaced password ';

    testWidgets('turning TOTP off sends the password exactly as typed', (
      tester,
    ) async {
      server
        ..password = spacedPassword
        ..totp = true;
      await pumpAt(tester, securityPath);
      await tapKey(tester, totpDisableKey);
      await enter(tester, totpPasswordFieldKey, spacedPassword);
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('POST', '/v1/auth/totp/disable').single), {
        'password': spacedPassword,
      });
      expect(server.totp, isFalse);
    });

    testWidgets('email change and deletion send the password as typed', (
      tester,
    ) async {
      const password = spacedPassword;
      server.password = password;
      await pumpAt(tester, accountPath);
      await tapKey(tester, emailChangeKey);
      await enter(tester, emailNewFieldKey, ' new@example.com ');
      await enter(tester, reauthPasswordKey, password);
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('POST', '/v1/me/email').single), {
        'email': 'new@example.com',
        'password': password,
      });

      await tapKey(tester, deleteAccountKey);
      await enter(tester, reauthPasswordKey, password);
      await enter(tester, deleteConfirmFieldKey, 'user@example.com');
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('DELETE', '/v1/me').single), {
        'password': password,
      });
      expect(server.deleted, isTrue);
    });

    testWidgets('an unknown TOTP status still offers the code field', (
      tester,
    ) async {
      server.totpStatusFails = true;
      await pumpAt(tester, accountPath);
      await tapKey(tester, emailChangeKey);
      expect(find.byKey(reauthCodeKey), findsOneWidget);
      await tester.tap(find.text('Скасувати'));
      await tester.pumpAndSettle();

      await tapKey(tester, deleteAccountKey);
      expect(find.byKey(reauthCodeKey), findsOneWidget);
      // Left empty, no second factor is sent.
      await enter(tester, reauthPasswordKey, 'right-password');
      await enter(tester, deleteConfirmFieldKey, 'user@example.com');
      await tapKey(tester, formDialogSubmitKey);
      expect(bodyOf(server.to('DELETE', '/v1/me').single), {
        'password': 'right-password',
      });
    });
  });

  group('entitlements (MON-3, MON-4)', () {
    testWidgets('the current plan and its values', (tester) async {
      await pumpAt(tester, subscriptionPath, locales: const [Locale('en')]);
      expect(find.text('Plan: Free'), findsOneWidget);
      String valueOf(String name) => tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(entitlementRowKey(name)),
                  matching: find.byType(Text),
                )
                .last,
          )
          .data!;
      expect(valueOf('connections.max'), '2');
      expect(valueOf('connectors.business'), 'No');
      expect(valueOf('sync.min_interval'), '60 min');
      expect(valueOf('exports'), 'csv');
      expect(find.text('Connections'), findsOneWidget);
    });

    testWidgets('a 402 anywhere offers a plan with more of it', (tester) async {
      server.exceed = (path: '/v1/sessions', entitlement: 'connections.max');
      await pumpAt(tester, securityPath, locales: const [Locale('en')]);
      expect(find.byKey(planOfferKey), findsOneWidget);
      expect(
        find.text(
          'Your plan has no more “Connections”. The plans below give more.',
        ),
        findsOneWidget,
      );
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
      server.exceed = null;
      await tapKey(tester, planOfferSeePlansKey);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byKey(planOfferKey), findsNothing);
    });

    test('givesMore compares by the kind of value', () {
      expect(givesMore('connections.max', null, 2), isTrue);
      expect(givesMore('connections.max', 5, 2), isTrue);
      expect(givesMore('connections.max', 2, null), isFalse);
      expect(givesMore('connectors.business', true, false), isTrue);
      expect(givesMore('sync.min_interval', 900, 3600), isTrue);
      expect(givesMore('sync.min_interval', null, 3600), isFalse);
      expect(givesMore('exports', ['csv', 'xlsx'], ['csv']), isTrue);
    });

    test('a typed exception reaches the app stream', () async {
      final transport = fakeApiTransport(server.adapter);
      server.exceed = (path: '/v1/me', entitlement: 'profiles.max');
      final next = transport.entitlementRejections.first;
      await expectLater(
        transport.getProfile(),
        throwsA(isA<EntitlementExceededException>()),
      );
      expect((await next).entitlement, 'profiles.max');
      transport.close();
    });
  });

  test('the poll interval and saver have production defaults', () {
    final container = ProviderContainer(
      overrides: [
        apiTransportProvider.overrideWithValue(
          fakeApiTransport(ScriptedAdapter(meta())),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(exportPollIntervalProvider),
      const Duration(seconds: 2),
    );
    expect(container.read(passkeyRegistrarProvider), isNull);
  });
}
