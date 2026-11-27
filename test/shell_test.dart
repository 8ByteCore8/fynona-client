import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/screens/operations_screen.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/profile_switcher.dart';
import 'package:fynona/shell/router.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

Finder inBar(String text) =>
    find.descendant(of: find.byKey(navBarKey), matching: find.text(text));

void main() {
  testWidgets('compact: bottom bar Огляд · Операції · Аналітика · Ще', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(navBarKey), findsOneWidget);
    expect(find.byKey(navRailKey), findsNothing);
    final labels = ['Огляд', 'Операції', 'Аналітика', 'Ще'];
    final xs = [for (final l in labels) tester.getCenter(inBar(l)).dx];
    expect(xs, orderedEquals([...xs]..sort()), reason: 'in this order');
  });

  testWidgets('tapping a destination switches the branch', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OperationsScreen), findsNothing);
    await tester.tap(inBar('Операції'));
    await tester.pumpAndSettle();
    expect(find.byType(OperationsScreen), findsOneWidget);
    await tester.tap(inBar('Ще'));
    await tester.pumpAndSettle();
    expect(find.text('Без скла'), findsOneWidget);
  });

  testWidgets('bar hides on scroll down and returns on scroll up (CLI-21)', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: operationsPath);
    expect(barVisible(tester), isTrue);
    await tester.drag(find.byKey(operationsListKey), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(barVisible(tester), isFalse);
    await tester.drag(find.byKey(operationsListKey), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(barVisible(tester), isTrue);
  });

  for (final size in [const Size(700, 900), const Size(1280, 800)]) {
    testWidgets(
      'wide ${size.width.toInt()} px: rail instead of the bottom bar',
      (tester) async {
        await pumpApp(tester, size: size);
        expect(find.byKey(navRailKey), findsOneWidget);
        expect(find.byKey(navBarKey), findsNothing);
        await tester.tap(
          find.descendant(
            of: find.byKey(navRailKey),
            matching: find.text('Операції'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(OperationsScreen), findsOneWidget);
      },
    );
  }

  testWidgets('profile switcher on Огляд, Операції, Аналітика; not on Ще', (
    tester,
  ) async {
    await pumpApp(tester);
    for (final (tab, expected) in [
      ('Огляд', findsOneWidget),
      ('Операції', findsOneWidget),
      ('Аналітика', findsOneWidget),
      ('Ще', findsNothing),
    ]) {
      await tester.tap(inBar(tab));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSwitcher), expected, reason: tab);
    }
  });

  testWidgets('choosing a profile is shared by all three screens', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(ProfileSwitcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Особистий'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ProfileSwitcher),
        matching: find.text('Особистий'),
      ),
      findsOneWidget,
    );
    await tester.tap(inBar('Аналітика'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ProfileSwitcher),
        matching: find.text('Особистий'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('long press on a nav item shows a large label (CLI-24)', (
    tester,
  ) async {
    await pumpApp(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(inBar('Аналітика')),
    );
    await tester.pump(
      FynonaTokens.gestureLongPress + const Duration(milliseconds: 50),
    );
    expect(
      find.descendant(
        of: find.byKey(navLargeLabelKey),
        matching: find.text('Аналітика'),
      ),
      findsOneWidget,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(navLargeLabelKey), findsNothing);
    expect(find.byType(ProfileSwitcher), findsOneWidget, reason: 'still Огляд');
  });
}
