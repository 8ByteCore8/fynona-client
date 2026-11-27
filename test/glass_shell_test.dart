// CLI-32 in the shell: auto → blur, or the prebaked fallback when blur is
// unsupported; manual switch and high contrast → opaque surfaces.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/settings/appearance.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/router.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

GlassMode modeOf(WidgetTester tester) =>
    GlassScope.of(tester.element(find.byKey(navBarKey)));

void main() {
  testWidgets('auto with blur support: blur on chrome only', (tester) async {
    await pumpApp(tester, initialLocation: operationsPath);
    expect(modeOf(tester), GlassMode.blur);
    // Header + bottom bar; never on list rows (CLI-31).
    expect(find.byType(BackdropFilter), findsNWidgets(2));
  });

  testWidgets(
    'auto without blur support: prebaked fallback, no BackdropFilter',
    (tester) async {
      await pumpApp(
        tester,
        initialLocation: operationsPath,
        overrides: [platformBlurSupportedProvider.overrideWithValue(false)],
      );
      expect(modeOf(tester), GlassMode.prebaked);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(PrebakedBackdropSlice), findsNWidgets(2));
    },
  );

  testWidgets('frame detector trip switches auto mode to prebaked', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: operationsPath);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(navBarKey)),
    );
    container.read(glassDegradedProvider.notifier).trip();
    await tester.pumpAndSettle();
    expect(modeOf(tester), GlassMode.prebaked);
  });

  testWidgets('manual «Без скла» switch: opaque chrome', (tester) async {
    await pumpApp(tester, initialLocation: morePath);
    await tester.tap(find.text('Без скла'));
    await tester.pumpAndSettle();
    expect(modeOf(tester), GlassMode.opaque);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('in-app high contrast: hc theme and opaque chrome', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: morePath);
    await tester.tap(find.text('Високий контраст'));
    await tester.pumpAndSettle();
    expect(modeOf(tester), GlassMode.highContrast);
    expect(find.byType(BackdropFilter), findsNothing);
    final theme = Theme.of(tester.element(find.byKey(navBarKey)));
    expect(theme.extension<FynonaColors>(), same(FynonaColors.hcLight));
  });

  testWidgets('system high contrast: hc theme and opaque chrome', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, initialLocation: operationsPath);
    expect(modeOf(tester), GlassMode.highContrast);
    expect(find.byType(BackdropFilter), findsNothing);
    final theme = Theme.of(tester.element(find.byKey(navBarKey)));
    expect(theme.extension<FynonaColors>(), same(FynonaColors.hcLight));
  });

  testWidgets('switching the glass mode keeps the scroll position', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: operationsPath);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(position, greaterThan(0));
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(navBarKey)),
    );
    container.read(appearanceProvider.notifier).setNoGlass(true);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      position,
    );
  });
}
