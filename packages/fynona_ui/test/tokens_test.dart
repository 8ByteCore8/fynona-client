import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/gen_tokens.dart';

final Map<String, Object?> tokens = jsonDecode(
  File('tokens/tokens.json').readAsStringSync(),
) as Map<String, Object?>;

Object? token(String path) {
  Object? node = tokens;
  for (final p in path.split('.')) {
    node = (node as Map<String, Object?>)[p];
  }
  final value = (node as Map<String, Object?>)[r'$value'];
  if (value is String && value.startsWith('{')) {
    return token(value.substring(1, value.length - 1));
  }
  return value;
}

/// The ARGB colour of a token, read from tokens.json at test time.
Color tokenColor(String path) =>
    Color(colorArgb(token(path)! as Map<String, Object?>));

double tokenPx(String path) =>
    ((token(path)! as Map<String, Object?>)['value']! as num).toDouble();

void main() {
  test('generated Dart is up to date with tokens/tokens.json', () {
    expect(
      generateTokens(tokens),
      File('lib/src/tokens/tokens.g.dart').readAsStringSync(),
      reason: 'run `dart run tool/gen_tokens.dart` in packages/fynona_ui',
    );
  });

  test('token colours reach the colour schemes of all four themes', () {
    final light = FynonaTheme.light().colorScheme;
    expect(light.primary, tokenColor('color.light.accent.base'));
    expect(light.onPrimary, tokenColor('color.light.accent.on'));
    expect(light.surface, tokenColor('color.light.background.base'));
    expect(light.surfaceContainer, tokenColor('color.light.surface.chrome'));
    expect(light.error, tokenColor('color.light.status.danger'));

    final dark = FynonaTheme.dark().colorScheme;
    expect(dark.brightness, Brightness.dark);
    expect(dark.primary, tokenColor('color.dark.accent.base'));
    expect(dark.onSurface, tokenColor('color.dark.content.primary'));

    final hcLight = FynonaTheme.highContrastLight().colorScheme;
    expect(hcLight.onSurface, tokenColor('color.hcLight.content.primary'));
    expect(hcLight.surface, tokenColor('color.hcLight.background.base'));

    final hcDark = FynonaTheme.highContrastDark().colorScheme;
    expect(hcDark.primary, tokenColor('color.hcDark.accent.base'));
  });

  test('translucent roles are composited as in the Material 3 mapping', () {
    // docs/design/README.md: primaryContainer light = #E8E9FA (8-bit
    // rounded there, so compare within one step per channel).
    final actual = FynonaTheme.light().colorScheme.primaryContainer;
    const expected = Color(0xFFE8E9FA);
    expect(actual.a, 1.0);
    expect(actual.r, closeTo(expected.r, 1.5 / 255));
    expect(actual.g, closeTo(expected.g, 1.5 / 255));
    expect(actual.b, closeTo(expected.b, 1.5 / 255));
  });

  test('FynonaColors extension carries the full role set per theme', () {
    for (final variant in FynonaThemeVariant.values) {
      final colors = FynonaTheme.of(variant).extension<FynonaColors>()!;
      final name = variant.name;
      expect(colors, same(variant.colors));
      expect(colors.moneyIncome, tokenColor('color.$name.money.income'));
      expect(colors.moneyExpense, tokenColor('color.$name.money.expense'));
      expect(
        colors.surfaceGlassTint,
        tokenColor('color.$name.surface.glassTint'),
      );
      expect(colors.profileColor3, tokenColor('color.$name.profile.color3'));
    }
    // Translucent originals keep their alpha (light glass tint at 50 %).
    expect(FynonaColors.light.surfaceGlassTint.a, closeTo(0.5, 0.002));
  });

  test(
    'typography: bundled Inter is the default family, sizes from tokens',
    () {
      final theme = FynonaTheme.light();
      final title = theme.textTheme.titleLarge!;
      expect(title.fontFamily, 'packages/fynona_ui/Inter');
      expect(theme.textTheme.bodyLarge!.fontFamily, 'packages/fynona_ui/Inter');
      expect(title.fontSize, tokenPx('font.size.title'));
      expect(
        title.fontWeight,
        FontWeight((token('font.weight.heading')! as num).toInt()),
      );
      expect(theme.textTheme.labelSmall!.fontSize, tokenPx('font.size.nav'));
      expect(
        title.fontFeatures,
        containsAll(const [
          FontFeature.tabularFigures(),
          FontFeature.liningFigures(),
        ]),
      );
    },
  );

  test('numeric tokens: glass, caps, breakpoints', () {
    expect(FynonaTokens.glassBlurSigma, tokenPx('glass.blurSigma'));
    expect(FynonaTokens.glassSaturation, token('glass.saturation'));
    expect(FynonaTokens.textScaleMaxHeader, 1.3);
    expect(FynonaTokens.textScaleMaxNavLabel, 1.15);
    expect(FynonaTokens.breakpointMedium, tokenPx('breakpoint.medium'));
    expect(FynonaTokens.gestureLongPress, const Duration(milliseconds: 550));
  });

  test('the OFL licence of Inter ships with the font', () {
    expect(
      File('fonts/OFL.txt').readAsStringSync(),
      contains('SIL Open Font License'),
    );
    expect(File('fonts/InterVariable.ttf').existsSync(), isTrue);
  });
}
