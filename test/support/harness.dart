import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/app.dart';
import 'package:fynona/shell/app_shell.dart';
import 'package:fynona/shell/router.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps the whole app at a logical [size] (dpr 1) and [textScale].
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  String initialLocation = overviewPath,
  List<Locale> locales = const [Locale('uk')],
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: FynonaApp(initialLocation: initialLocation),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Window height in logical pixels.
double windowHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

/// Whether the bottom bar is inside the window.
bool barVisible(WidgetTester tester) =>
    tester.getRect(find.byKey(navBarKey)).top < windowHeight(tester) - 0.5;

/// Loads the bundled Inter and the Material icon font so goldens show real
/// glyphs instead of the test font's boxes.
Future<void> loadAppFonts() async {
  final inter = FontLoader('packages/fynona_ui/Inter')
    ..addFont(rootBundle.load('packages/fynona_ui/fonts/InterVariable.ttf'));
  await inter.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
