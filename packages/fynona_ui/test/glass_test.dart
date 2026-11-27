import 'package:flutter_test/flutter_test.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpSurface(
  WidgetTester tester,
  GlassMode mode, {
  FynonaThemeVariant variant = FynonaThemeVariant.light,
}) => tester.pumpWidget(
  MaterialApp(
    theme: FynonaTheme.of(variant),
    home: GlassScope(
      mode: mode,
      child: const Stack(
        children: [
          Positioned.fill(child: FynonaBackground()),
          GlassSurface(
            edge: GlassEdge.bottom,
            child: SizedBox(width: 200, height: 60),
          ),
        ],
      ),
    ),
  ),
);

BoxDecoration surfaceDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(GlassSurface),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  group('resolveGlassMode (CLI-32)', () {
    test('auto: blur when supported, prebaked fallback when not', () {
      expect(
        resolveGlassMode(
          highContrast: false,
          noGlass: false,
          blurSupported: true,
        ),
        GlassMode.blur,
      );
      expect(
        resolveGlassMode(
          highContrast: false,
          noGlass: false,
          blurSupported: false,
        ),
        GlassMode.prebaked,
      );
    });

    test('manual switch gives opaque, high contrast wins over everything', () {
      expect(
        resolveGlassMode(
          highContrast: false,
          noGlass: true,
          blurSupported: true,
        ),
        GlassMode.opaque,
      );
      expect(
        resolveGlassMode(
          highContrast: true,
          noGlass: false,
          blurSupported: true,
        ),
        GlassMode.highContrast,
      );
      expect(
        resolveGlassMode(
          highContrast: true,
          noGlass: true,
          blurSupported: false,
        ),
        GlassMode.highContrast,
      );
    });
  });

  testWidgets('blur: one BackdropFilter, glass tint', (tester) async {
    await pumpSurface(tester, GlassMode.blur);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      surfaceDecoration(tester).color,
      FynonaColors.light.surfaceGlassTint,
    );
  });

  testWidgets('prebaked: no BackdropFilter, pre-blurred image under the tint', (
    tester,
  ) async {
    await pumpSurface(tester, GlassMode.prebaked);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(PrebakedBackdropSlice), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    expect(
      surfaceDecoration(tester).color,
      FynonaColors.light.surfaceGlassTint,
    );
  });

  testWidgets('opaque: no blur, opaque surface.chrome', (tester) async {
    await pumpSurface(tester, GlassMode.opaque);
    expect(find.byType(BackdropFilter), findsNothing);
    final color = surfaceDecoration(tester).color!;
    expect(color, FynonaColors.light.surfaceChrome);
    expect(color.a, 1.0);
  });

  testWidgets('high contrast: opaque hc chrome with a 1.5 px outline edge', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      GlassMode.highContrast,
      variant: FynonaThemeVariant.hcLight,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final decoration = surfaceDecoration(tester);
    expect(decoration.color, FynonaColors.hcLight.surfaceChrome);
    final border = decoration.border! as BorderDirectional;
    expect(border.bottom.width, FynonaTokens.glassHighContrastEdgeWidth);
    expect(border.bottom.color, FynonaColors.hcLight.borderOutline);
  });
}
