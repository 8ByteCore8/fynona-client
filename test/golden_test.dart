// Goldens of the shell on Операції at 390×844 (CLI-32 visual states).
// Regenerate on Linux: flutter test --update-goldens test/golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/shell/router.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shell light', (tester) async {
    await pumpApp(tester, initialLocation: operationsPath);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/shell_light.png'),
    );
  });

  testWidgets('shell dark', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, initialLocation: operationsPath);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/shell_dark.png'),
    );
  });

  testWidgets('shell high contrast', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, initialLocation: operationsPath);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/shell_high_contrast.png'),
    );
  });
}
