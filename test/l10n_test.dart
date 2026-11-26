import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/app.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

Map<String, Object?> arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, Object?>;

Finder inBar(String text) =>
    find.descendant(of: find.byKey(navBarKey), matching: find.text(text));

void main() {
  group('resolveAppLocale (CLI-40)', () {
    test('system language when supported', () {
      expect(resolveAppLocale(const [Locale('en', 'US')]), const Locale('en'));
      expect(resolveAppLocale(const [Locale('ru')]), const Locale('ru'));
      expect(resolveAppLocale(const [Locale('uk', 'UA')]), const Locale('uk'));
    });

    test('first supported language of the preference list', () {
      expect(
        resolveAppLocale(const [Locale('de'), Locale('en'), Locale('uk')]),
        const Locale('en'),
      );
    });

    test('Ukrainian fallback', () {
      expect(resolveAppLocale(const [Locale('de', 'DE')]), const Locale('uk'));
      expect(resolveAppLocale(const []), const Locale('uk'));
      expect(resolveAppLocale(null), const Locale('uk'));
    });
  });

  test('uk, ru and en ARB files have the same messages', () {
    Set<String> keys(String lang) =>
        arb(lang).keys.where((k) => !k.startsWith('@')).toSet();
    final uk = keys('uk');
    expect(keys('ru'), uk);
    expect(keys('en'), uk);
  });

  for (final (locales, labels) in [
    (const [Locale('uk')], ['Огляд', 'Операції', 'Аналітика', 'Ще']),
    (const [Locale('ru', 'RU')], ['Обзор', 'Операции', 'Аналитика', 'Ещё']),
    (
      const [Locale('en', 'GB')],
      ['Overview', 'Operations', 'Analytics', 'More'],
    ),
    (const [Locale('de')], ['Огляд', 'Операції', 'Аналітика', 'Ще']),
  ]) {
    testWidgets('system locale ${locales.first} → ${labels.first}', (
      tester,
    ) async {
      await pumpApp(tester, locales: locales);
      for (final label in labels) {
        expect(inBar(label), findsOneWidget, reason: label);
      }
    });
  }
}
