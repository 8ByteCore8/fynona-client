import 'package:flutter_test/flutter_test.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

// Test data: the package itself holds no user-facing strings.
const destinations = [
  FynonaDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'A',
  ),
  FynonaDestination(
    icon: Icons.list_outlined,
    selectedIcon: Icons.list,
    label: 'B',
  ),
  FynonaDestination(
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
    label: 'C',
    semanticLabel: 'C, 3',
  ),
];

Future<List<int>> pumpBar(WidgetTester tester, {double textScale = 1}) async {
  final taps = <int>[];
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: FynonaTheme.light(),
      home: Scaffold(
        bottomNavigationBar: FynonaNavBar(
          destinations: destinations,
          selectedIndex: 1,
          onSelected: taps.add,
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('tap selects; long press shows the large label until release', (
    tester,
  ) async {
    final taps = await pumpBar(tester);
    await tester.tap(find.text('A'));
    expect(taps, [0]);

    final gesture = await tester.startGesture(tester.getCenter(find.text('B')));
    await tester.pump(
      FynonaTokens.gestureLongPress + const Duration(milliseconds: 50),
    );
    expect(find.byKey(navLargeLabelKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(navLargeLabelKey),
        matching: find.text('B'),
      ),
      findsOneWidget,
    );
    await gesture.up();
    await tester.pump();
    expect(find.byKey(navLargeLabelKey), findsNothing);
    expect(taps, [0], reason: 'a long press is not a tap');
  });

  testWidgets('labels are capped at 1.15, the large label grows to 2.0', (
    tester,
  ) async {
    await pumpBar(tester, textScale: 2);
    expect(
      MediaQuery.textScalerOf(tester.element(find.text('A'))).scale(1),
      1.15,
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pump(
      FynonaTokens.gestureLongPress + const Duration(milliseconds: 50),
    );
    final large = find.descendant(
      of: find.byKey(navLargeLabelKey),
      matching: find.text('A'),
    );
    expect(MediaQuery.textScalerOf(tester.element(large)).scale(1), 2.0);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('each item is one labelled, selectable button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester);
    expect(
      tester.getSemantics(find.text('B')),
      matchesSemantics(
        label: 'B',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    expect(find.bySemanticsLabel('C, 3'), findsOneWidget);
    handle.dispose();
  });
}
