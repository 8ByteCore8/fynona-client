// CLI auth screens (SEC-1, SEC-2, SEC-3): sign up, sign in, check email,
// email link, forgot and reset password, TOTP or recovery code, web
// passkey; uk/ru/en and screen-reader labels.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/app.dart';
import 'package:fynona/auth/auth.dart';
import 'package:fynona/screens/auth/password_screens.dart';
import 'package:fynona/screens/more_screen.dart' show signOutKey;
import 'package:fynona/screens/auth/sign_in_screen.dart';
import 'package:fynona/screens/auth/sign_up_screen.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/router.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:material_ui/material_ui.dart';

import 'semantics_test.dart' show unlabelledInteractiveNodes;
import 'support/api_fakes.dart';
import 'support/auth_fakes.dart';
import 'support/harness.dart';

late FakeAuthServer server;
late MemoryRefreshTokenStore store;

Future<void> pumpSignedOut(
  WidgetTester tester, {
  String at = signInPath,
  List<Locale> locales = const [Locale('uk')],
  PasskeyAuthenticator? passkey,
}) => pumpApp(
  tester,
  signedIn: false,
  initialLocation: at,
  locales: locales,
  transport: fakeApiTransport(server.adapter),
  store: store,
  overrides: [passkeyAuthenticatorProvider.overrideWithValue(passkey)],
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FynonaApp)));

Future<void> signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(signInEmailKey), email);
  await tester.enterText(find.byKey(signInPasswordKey), password);
  await tester.tap(find.byKey(signInSubmitKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    server = FakeAuthServer();
    store = MemoryRefreshTokenStore();
  });

  group('every auth screen is localized and labelled', () {
    const screens = {
      signInPath: ('Вхід', 'Вход', 'Sign in'),
      signUpPath: ('Реєстрація', 'Регистрация', 'Create an account'),
      forgotPasswordPath: (
        'Відновлення пароля',
        'Восстановление пароля',
        'Reset your password',
      ),
      '$resetPasswordPath?token=good': (
        'Новий пароль',
        'Новый пароль',
        'New password',
      ),
      '$verifyEmailPath?token=good': (
        'Підтвердження пошти',
        'Подтверждение почты',
        'Email confirmation',
      ),
    };
    for (final MapEntry(key: path, value: titles) in screens.entries) {
      for (final (lang, title) in [
        ('uk', titles.$1),
        ('ru', titles.$2),
        ('en', titles.$3),
      ]) {
        testWidgets('$path in $lang', (tester) async {
          final handle = tester.ensureSemantics();
          await pumpSignedOut(tester, at: path, locales: [Locale(lang)]);
          expect(find.text(title), findsWidgets);
          expect(unlabelledInteractiveNodes(tester), isEmpty);
          handle.dispose();
        });
      }
    }
  });

  group('sign in', () {
    testWidgets('unknown email and wrong password read the same', (
      tester,
    ) async {
      await pumpSignedOut(tester);
      await signIn(tester, 'nobody@example.com', 'right-password');
      expect(find.text('Неправильна пошта або пароль'), findsOneWidget);
      await signIn(tester, 'user@example.com', 'wrong-password');
      expect(find.text('Неправильна пошта або пароль'), findsOneWidget);
      expect(find.byKey(navBarKey), findsNothing);
    });

    testWidgets('fields are validated before any request', (tester) async {
      await pumpSignedOut(tester);
      await signIn(tester, 'not-an-email', '');
      expect(find.text('Введіть адресу пошти'), findsOneWidget);
      expect(find.text('Введіть пароль'), findsOneWidget);
      expect(server.to('/v1/auth/login'), isEmpty);
    });

    testWidgets('a right password opens the app shell', (tester) async {
      await pumpSignedOut(tester);
      await signIn(tester, 'user@example.com', 'right-password');
      expect(find.byKey(navBarKey), findsOneWidget);
      expect(await store.read(), 'r1');
      final login = server.to('/v1/auth/login').single;
      expect(login.headers, isNot(contains('Idempotency-Key')));
      expect(FakeAuthServer.bodyOf(login)['token_delivery'], 'body');
    });
  });

  group('second factor (202 + POST /v1/auth/login/mfa)', () {
    setUp(() => server.totp = true);

    testWidgets('a TOTP code completes the sign-in', (tester) async {
      await pumpSignedOut(tester);
      await signIn(tester, 'user@example.com', 'right-password');
      expect(find.text('Підтвердження входу'), findsWidgets);
      expect(find.byKey(navBarKey), findsNothing);
      expect(await store.read(), isNull);

      await tester.enterText(find.byKey(mfaCodeKey), '000000');
      await tester.tap(find.byKey(mfaSubmitKey));
      await tester.pumpAndSettle();
      expect(find.text('Неправильний код'), findsOneWidget);

      await tester.enterText(find.byKey(mfaCodeKey), '123456');
      await tester.tap(find.byKey(mfaSubmitKey));
      await tester.pumpAndSettle();
      expect(find.byKey(navBarKey), findsOneWidget);
      final mfa = FakeAuthServer.bodyOf(server.to('/v1/auth/login/mfa').last);
      expect(mfa, {
        'mfa_token': 'm1',
        'code': '123456',
        'token_delivery': 'body',
      });
    });

    testWidgets('a recovery code works too; screen is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedOut(tester, locales: const [Locale('en')]);
      await signIn(tester, 'user@example.com', 'right-password');
      expect(unlabelledInteractiveNodes(tester), isEmpty);
      await tester.tap(find.byKey(mfaToggleKey));
      await tester.pumpAndSettle();
      expect(find.text('Recovery code'), findsOneWidget);
      await tester.enterText(find.byKey(mfaCodeKey), 'ABCD-EFGH');
      await tester.tap(find.byKey(mfaSubmitKey));
      await tester.pumpAndSettle();
      expect(find.byKey(navBarKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets('without a challenge the screen sends back to sign-in', (
      tester,
    ) async {
      await pumpSignedOut(tester, at: mfaPath);
      expect(find.text('Час вийшов. Увійдіть ще раз'), findsOneWidget);
    });
  });

  group('passkey sign-in (web)', () {
    testWidgets('hidden where passkeys are not offered', (tester) async {
      await pumpSignedOut(tester);
      expect(find.byKey(passkeyButtonKey), findsNothing);
    });

    testWidgets('the browser assertion opens the session', (tester) async {
      Map<String, Object?>? seenOptions;
      await pumpSignedOut(
        tester,
        passkey: (options) async {
          seenOptions = options;
          return {'id': 'cred', 'type': 'public-key'};
        },
      );
      await tester.tap(find.byKey(passkeyButtonKey));
      await tester.pumpAndSettle();
      expect(seenOptions, {
        'publicKey': {'challenge': 'Y2hhbGxlbmdl'},
      });
      final finish = FakeAuthServer.bodyOf(
        server.to('/v1/auth/passkeys/login').single,
      );
      expect(finish['credential'], {'id': 'cred', 'type': 'public-key'});
      expect(find.byKey(navBarKey), findsOneWidget);
    });

    testWidgets('a cancelled ceremony shows an error', (tester) async {
      await pumpSignedOut(
        tester,
        passkey: (_) async => throw StateError('cancelled'),
      );
      await tester.tap(find.byKey(passkeyButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Не вдалося увійти з ключем доступу'), findsOneWidget);
      expect(server.to('/v1/auth/passkeys/login'), isEmpty);
    });
  });

  group('sign up and email confirmation', () {
    testWidgets('sign-up leads to «check your email» without a resend', (
      tester,
    ) async {
      await pumpSignedOut(tester, at: signUpPath);
      await tester.enterText(find.byKey(signUpEmailKey), 'new@example.com');
      await tester.enterText(find.byKey(signUpPasswordKey), 'short');
      await tester.tap(find.byKey(signUpSubmitKey));
      await tester.pumpAndSettle();
      expect(find.text('Щонайменше 8 символів'), findsOneWidget);
      expect(server.to('/v1/auth/register'), isEmpty);

      await tester.enterText(find.byKey(signUpPasswordKey), 'long-enough');
      await tester.tap(find.byKey(signUpSubmitKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('new@example.com'), findsOneWidget);
      expect(find.textContaining('теку «Спам»'), findsOneWidget);
      final registers = server.to('/v1/auth/register');
      expect(registers, hasLength(1));
      expect(FakeAuthServer.bodyOf(registers.single), {
        'email': 'new@example.com',
        'password': 'long-enough',
      });
      expect(registers.single.headers, isNot(contains('Idempotency-Key')));
      final container = containerOf(tester);
      expect(container.read(pendingRegistrationProvider), 'new@example.com');

      await tester.tap(find.byKey(signUpAgainKey));
      await tester.pumpAndSettle();
      expect(find.byKey(signUpSubmitKey), findsOneWidget);
      expect(container.read(pendingRegistrationProvider), isNull);
      expect(server.to('/v1/auth/register'), hasLength(1));
    });

    testWidgets('the emailed link confirms the address', (tester) async {
      await pumpSignedOut(tester, at: '$verifyEmailPath?token=good');
      expect(find.text('Пошту підтверджено. Тепер можна увійти'), findsOne);
      expect(FakeAuthServer.bodyOf(server.to('/v1/auth/email/verify').single), {
        'token': 'good',
      });
    });

    testWidgets('a used link says so', (tester) async {
      await pumpSignedOut(tester, at: '$verifyEmailPath?token=used');
      expect(find.text('Посилання недійсне або застаріло'), findsOneWidget);
    });
  });

  group('password reset', () {
    testWidgets('a request reads the same for any email', (tester) async {
      await pumpSignedOut(tester, at: forgotPasswordPath);
      await tester.enterText(find.byKey(forgotEmailKey), 'nobody@example.com');
      await tester.tap(find.byKey(forgotSubmitKey));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Якщо акаунт з цією поштою існує, ми надіслали на неї '
          'посилання для нового пароля.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the emailed link sets a new password', (tester) async {
      await pumpSignedOut(tester, at: '$resetPasswordPath?token=good');
      await tester.enterText(find.byKey(resetPasswordKey), 'brand-new-pass');
      await tester.tap(find.byKey(resetSubmitKey));
      await tester.pumpAndSettle();
      expect(find.text('Пароль змінено. Увійдіть з новим паролем'), findsOne);
      expect(
        FakeAuthServer.bodyOf(
          server.to('/v1/auth/password/reset/confirm').single,
        ),
        {'token': 'good', 'password': 'brand-new-pass'},
      );
    });

    testWidgets('an expired link offers a new one', (tester) async {
      await pumpSignedOut(tester, at: '$resetPasswordPath?token=old');
      await tester.enterText(find.byKey(resetPasswordKey), 'brand-new-pass');
      await tester.tap(find.byKey(resetSubmitKey));
      await tester.pumpAndSettle();
      expect(find.text('Посилання недійсне або застаріло'), findsOneWidget);
      expect(find.text('Забули пароль?'), findsOneWidget);
    });
  });

  group('router guard and sign-out', () {
    testWidgets('signed out, a shell route shows sign-in only', (tester) async {
      await pumpSignedOut(tester, at: operationsPath);
      expect(find.byKey(navBarKey), findsNothing);
      expect(find.byKey(signInSubmitKey), findsOneWidget);
    });

    testWidgets('a stored session resumes on the requested route', (
      tester,
    ) async {
      await store.write('r0');
      await pumpSignedOut(tester, at: operationsPath);
      expect(find.byKey(navBarKey), findsOneWidget);
      expect(find.byKey(signInSubmitKey), findsNothing);
      expect(await store.read(), 'r2');
    });

    testWidgets('a secret store that fails leads to sign-in, not a spinner', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedIn: false,
        initialLocation: operationsPath,
        transport: fakeApiTransport(server.adapter),
        store: BrokenRefreshTokenStore(),
      );
      expect(find.byKey(signInSubmitKey), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(navBarKey), findsNothing);
    });

    testWidgets('signed in, auth routes lead to the shell', (tester) async {
      await store.write('r0');
      await pumpSignedOut(tester, at: signUpPath);
      expect(find.byKey(navBarKey), findsOneWidget);
    });

    testWidgets('sign-out clears the store, the token and the cache', (
      tester,
    ) async {
      await store.write('r0');
      await pumpSignedOut(tester, at: morePath);
      final container = containerOf(tester);
      final session = container.read(authSessionProvider);
      expect(session.accessToken, 'a2');
      // Dio's timers run on the test clock: read, then pump.
      container.read(profileProvider);
      await tester.pumpAndSettle();
      expect(
        container.read(profileProvider).value?.email.value,
        'user@example.com',
      );

      await tester.scrollUntilVisible(find.byKey(signOutKey), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(signOutKey));
      await tester.pumpAndSettle();

      final logout = server.to('/v1/auth/logout').single;
      expect(logout.headers['Authorization'], 'Bearer a2');
      expect(await store.read(), isNull);
      expect(session.accessToken, isNull);
      expect(container.read(authStateProvider), AuthState.signedOut);
      // A read rebuilds the cache; the account data is gone after it.
      container.read(profileProvider);
      await tester.pumpAndSettle();
      expect(container.read(profileProvider).value, isNull);
      expect(find.byKey(navBarKey), findsNothing);
      expect(find.byKey(signInSubmitKey), findsOneWidget);
    });

    testWidgets('a revoked session signs out on the next 401', (tester) async {
      await store.write('r0');
      await pumpSignedOut(tester, at: overviewPath);
      final container = containerOf(tester);
      // The session is revoked elsewhere: neither token works any more.
      server
        ..validRefresh = null
        ..validAccess = null;
      final session = container.read(authSessionProvider);
      Object? failure;
      session.transport
          .call((api) => api.account.getMe())
          .then<void>((_) {}, onError: (Object e) => failure = e);
      await tester.pumpAndSettle();
      expect(failure, isA<ApiProblemException>());
      expect(container.read(authStateProvider), AuthState.signedOut);
      expect(await store.read(), isNull);
      expect(find.byKey(signInSubmitKey), findsOneWidget);
    });
  });
}
