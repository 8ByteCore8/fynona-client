import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/contract_gate.dart';
import 'package:fynona_api/fynona_api.dart';
import 'package:material_ui/material_ui.dart';

import 'support/api_fakes.dart';
import 'support/harness.dart';

/// Card client-version criterion 4: the check on start and on resume and the
/// two blocking screens (API-12).
void main() {
  Future<ScriptedAdapter> pumpWith(
    WidgetTester tester,
    ResponseBody Function(RequestOptions) respond, {
    String declared = contractVersion,
    List<Locale> locales = const [Locale('uk')],
    bool web = false,
  }) async {
    final adapter = ScriptedAdapter(respond);
    await pumpApp(
      tester,
      locales: locales,
      transport: fakeApiTransport(adapter, declared: declared),
      overrides: [isWebProvider.overrideWithValue(web)],
    );
    return adapter;
  }

  void expectUsable() {
    expect(find.byKey(navBarKey), findsOneWidget);
    expect(find.byKey(appOutdatedKey), findsNothing);
    expect(find.byKey(serverBehindKey), findsNothing);
  }

  void expectBlocked(Key screen) {
    expect(find.byKey(screen), findsOneWidget);
    expect(find.byKey(navBarKey), findsNothing);
    expect(find.byKey(navRailKey), findsNothing);
  }

  testWidgets('compatible: the app checks on start and stays usable', (
    tester,
  ) async {
    final adapter = await pumpWith(tester, meta());
    expect(adapter.requests.map((r) => r.path), contains('/v1/meta'));
    expect(adapter.requests.first.headers['X-Fynona-API'], contractVersion);
    expectUsable();
  });

  testWidgets('no connection on start is no verdict: the app stays usable', (
    tester,
  ) async {
    await pumpWith(
      tester,
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'test: server down',
      ),
    );
    expectUsable();
  });

  testWidgets('a server contract that is not SemVer does not block', (
    tester,
  ) async {
    await pumpWith(tester, meta(server: 'next'));
    expectUsable();
  });

  for (final (name, respond) in [
    ('another major', meta(server: '2.0.0', minimum: '2.0.0')),
    ('below the minimum', meta(server: '1.9.0', minimum: '1.5.0')),
    ('/v1/meta 404', problem(404, 'not_found')),
    ('/v1/meta 410', problem(410, 'gone')),
    ('/v1/meta 426', problem(426, apiVersionUnsupportedCode)),
  ]) {
    testWidgets('outdated ($name): blocking «update the app» screen', (
      tester,
    ) async {
      await pumpWith(tester, respond);
      expectBlocked(appOutdatedKey);
      expect(find.text('Застосунок застарів'), findsOneWidget);
      expect(find.byKey(reloadButtonKey), findsNothing);
    });
  }

  for (final (locale, title, message) in [
    (
      const Locale('ru'),
      'Приложение устарело',
      'Обновите приложение, чтобы продолжить работу.',
    ),
    (
      const Locale('en'),
      'The app is out of date',
      'Update the app to keep using it.',
    ),
  ]) {
    testWidgets('outdated screen in $locale', (tester) async {
      await pumpWith(tester, meta(server: '2.0.0'), locales: [locale]);
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('outdated on web offers a reload button', (tester) async {
    await pumpWith(tester, meta(server: '2.0.0'), web: true);
    expectBlocked(appOutdatedKey);
    expect(find.byKey(reloadButtonKey), findsOneWidget);
    expect(find.text('Перезавантажити'), findsOneWidget);
  });

  testWidgets('any 426 api_version_unsupported blocks a running app', (
    tester,
  ) async {
    final adapter = ScriptedAdapter(meta());
    final transport = fakeApiTransport(adapter);
    await pumpApp(tester, transport: transport);
    expectUsable();
    adapter.respond = problem(426, apiVersionUnsupportedCode);
    await tester.runAsync(
      () => expectLater(
        transport.call((api) => api.meta.getOpenAPI()),
        throwsA(isA<UpgradeRequiredException>()),
      ),
    );
    await tester.pumpAndSettle();
    expectBlocked(appOutdatedKey);
  });

  testWidgets('server behind: «service is updating» with a working retry', (
    tester,
  ) async {
    final adapter = await pumpWith(
      tester,
      meta(server: '1.0.0'),
      declared: '1.4.0',
    );
    expectBlocked(serverBehindKey);
    expect(find.text('Сервіс оновлюється'), findsOneWidget);
    expect(find.text('Застосунок застарів'), findsNothing);
    expect(find.byKey(reloadButtonKey), findsNothing);

    final before = adapter.requests.length;
    await tester.tap(find.byKey(retryButtonKey));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, before + 1);
    expectBlocked(serverBehindKey);

    adapter.respond = meta(server: '1.4.0');
    await tester.tap(find.byKey(retryButtonKey));
    await tester.pumpAndSettle();
    expectUsable();
  });

  testWidgets('the app checks again on resume', (tester) async {
    final adapter = await pumpWith(tester, meta());
    expectUsable();
    adapter.respond = meta(server: '2.0.0', minimum: '2.0.0');
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expectBlocked(appOutdatedKey);
  });

  testWidgets('blocking screens carry semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWith(tester, meta(server: '1.0.0'), declared: '1.4.0');
    expect(find.bySemanticsLabel('Сервіс оновлюється'), findsWidgets);
    expect(find.bySemanticsLabel('Спробуйте пізніше.'), findsOneWidget);
    expect(find.bySemanticsLabel('Спробувати ще раз'), findsOneWidget);
    handle.dispose();
  });
}
