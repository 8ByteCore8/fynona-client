import 'package:material_ui/material_ui.dart';

import '../tokens/tokens.g.dart';

/// The four themes of the token set (`color.light`, `dark`, `hcLight`, `hcDark`).
enum FynonaThemeVariant {
  light(Brightness.light, FynonaColors.light),
  dark(Brightness.dark, FynonaColors.dark),
  hcLight(Brightness.light, FynonaColors.hcLight),
  hcDark(Brightness.dark, FynonaColors.hcDark);

  const FynonaThemeVariant(this.brightness, this.colors);

  final Brightness brightness;
  final FynonaColors colors;

  bool get highContrast => this == hcLight || this == hcDark;
}

/// Material 3 themes built from the tokens (docs/design/README.md, «Material 3
/// mapping»). Translucent roles are composited over the surface they sit on;
/// the originals stay in the [FynonaColors] extension.
abstract final class FynonaTheme {
  static ThemeData light() => of(FynonaThemeVariant.light);
  static ThemeData dark() => of(FynonaThemeVariant.dark);
  static ThemeData highContrastLight() => of(FynonaThemeVariant.hcLight);
  static ThemeData highContrastDark() => of(FynonaThemeVariant.hcDark);

  static ThemeData of(FynonaThemeVariant variant) {
    final c = variant.colors;
    Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);
    final high = c.surfaceContainerHigh;
    final primaryContainer = over(c.accentContainer, high);
    final scheme = ColorScheme(
      brightness: variant.brightness,
      primary: c.accentBase,
      onPrimary: c.accentOn,
      primaryContainer: primaryContainer,
      onPrimaryContainer: c.accentOnContainer,
      secondary: c.accentBase,
      onSecondary: c.accentOn,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: c.accentOnContainer,
      tertiary: c.moneyTransfer,
      onTertiary: c.accentOn,
      tertiaryContainer: over(c.statusKindContainer, high),
      onTertiaryContainer: c.moneyTransfer,
      error: c.statusDanger,
      onError: c.statusOnDanger,
      errorContainer: over(c.statusDangerContainer, high),
      onErrorContainer: c.statusDanger,
      surface: c.backgroundBase,
      onSurface: c.contentPrimary,
      onSurfaceVariant: c.contentSecondary,
      surfaceContainerLowest: high,
      surfaceContainerLow: over(c.surfaceContainer, c.backgroundBase),
      surfaceContainer: c.surfaceChrome,
      surfaceContainerHigh: high,
      surfaceContainerHighest: high,
      outline: over(c.borderField, high),
      outlineVariant: over(c.borderOutline, high),
      scrim: c.surfaceScrim.withValues(alpha: 1),
      shadow: const Color(0xFF000000),
      surfaceTint: const Color(0x00000000),
    );
    final textTheme = _textTheme(c.contentPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: variant.brightness,
      colorScheme: scheme,
      fontFamily: FynonaTypography.fontFamily,
      package: FynonaTypography.fontPackage,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: c.backgroundBase,
      canvasColor: c.backgroundBase,
      dividerColor: scheme.outlineVariant,
      extensions: [c],
    );
  }

  static TextTheme _textTheme(Color color) {
    TextStyle s(TextStyle style) => style.copyWith(color: color);
    return TextTheme(
      headlineLarge: s(FynonaTypography.hero),
      headlineMedium: s(FynonaTypography.detailAmount),
      headlineSmall: s(FynonaTypography.authTitle),
      titleLarge: s(FynonaTypography.title),
      titleMedium: s(FynonaTypography.sheetTitle),
      titleSmall: s(FynonaTypography.sectionTitle),
      bodyLarge: s(FynonaTypography.body),
      bodyMedium: s(FynonaTypography.bodySmall),
      bodySmall: s(FynonaTypography.caption),
      labelLarge: s(FynonaTypography.button),
      labelMedium: s(FynonaTypography.label),
      labelSmall: s(FynonaTypography.navLabel),
    );
  }
}

/// Access to the token colours of the current theme.
extension FynonaThemeContext on BuildContext {
  FynonaColors get fynonaColors =>
      Theme.of(this).extension<FynonaColors>() ?? FynonaColors.light;
}
