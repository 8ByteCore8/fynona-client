// ignore_for_file: avoid_print
// CLI-20…CLI-22 work-zone rule on the Операції placeholder: the visible list
// area (between the bottom of the header and the top of the bottom bar, or
// the window bottom when the bar is hidden) is measured, not estimated.
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/screens/operations_screen.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/router.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

/// Share of the window height where list rows are visible and not covered.
double visibleListShare(WidgetTester tester) {
  final h = windowHeight(tester);
  final header = tester.getRect(find.byKey(operationsHeaderKey));
  final list = tester.getRect(find.byKey(operationsListKey));
  final bar = tester.getRect(find.byKey(navBarKey));
  final bottom = [bar.top, list.bottom, h].reduce((a, b) => a < b ? a : b);
  return (bottom - header.bottom) / h;
}

Future<void> pumpOperations(WidgetTester tester, Size size, double scale) =>
    pumpApp(
      tester,
      size: size,
      textScale: scale,
      initialLocation: operationsPath,
    );

void main() {
  const sizes = [Size(320, 568), Size(360, 640), Size(390, 844)];
  const scales = [1.0, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      final label = '${size.width.toInt()}×${size.height.toInt()}, text $scale';

      testWidgets('work zone: initial list area ≥ 60 % at $label', (
        tester,
      ) async {
        await pumpOperations(tester, size, scale);
        expect(barVisible(tester), isTrue);
        final share = visibleListShare(tester);
        print(
          'work-zone initial $label share=${(share * 100).toStringAsFixed(1)}%',
        );
        expect(share, greaterThanOrEqualTo(FynonaTokens.layoutWorkZoneInitial));
      });

      testWidgets('work zone: after scrolling list area ≥ 85 % at $label', (
        tester,
      ) async {
        await pumpOperations(tester, size, scale);
        await tester.drag(find.byKey(operationsListKey), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(barVisible(tester), isFalse, reason: 'bar hides on scroll down');
        final share = visibleListShare(tester);
        print(
          'work-zone after-scroll $label share=${(share * 100).toStringAsFixed(1)}%',
        );
        expect(
          share,
          greaterThanOrEqualTo(FynonaTokens.layoutWorkZoneScrolled),
        );
      });
    }
  }

  testWidgets(
    'CLI-24 caps at text 2.0: header 1.3, nav labels 1.15, rows 2.0',
    (tester) async {
      await pumpOperations(tester, const Size(320, 568), 2.0);
      double scaleOf(Finder f) =>
          MediaQuery.textScalerOf(tester.element(f)).scale(100) / 100;
      final headerText = find.descendant(
        of: find.byKey(operationsHeaderKey),
        matching: find.text('Усі профілі'),
      );
      final navLabel = find.descendant(
        of: find.byKey(navBarKey),
        matching: find.text('Аналітика'),
      );
      expect(scaleOf(headerText), 1.3);
      expect(scaleOf(navLabel), 1.15);
      expect(scaleOf(find.text('Операція 1')), 2.0);
    },
  );
}
