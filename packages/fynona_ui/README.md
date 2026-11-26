# fynona_ui

Design system of Fynona (brand A «Повітря»): tokens, Material 3 themes, glass
chrome and navigation components. Used by the Fynona app and the admin client.

## Contents

| Path | What it is |
|---|---|
| `tokens/tokens.json` | Design tokens (DTCG). A byte-identical copy of the canonical token file of the Fynona design system; do not edit it here. |
| `tool/gen_tokens.dart` | Generates `lib/src/tokens/tokens.g.dart` from `tokens/tokens.json`. |
| `lib/src/tokens/tokens.g.dart` | Generated: `FynonaColors` (`ThemeExtension`, four themes), `FynonaTokens`, `FynonaTypography`, brand and shadow colours. |
| `lib/src/theme/` | `FynonaTheme`: light, dark, high-contrast light and dark `ThemeData`. |
| `lib/src/glass/` | `GlassMode`, `GlassScope`, `GlassSurface`, background art, prebaked fallback, `LowFpsDetector`. |
| `lib/src/shell/` | `FynonaNavBar`, `FynonaNavRail`, `FynonaSliverHeader`, `ProfileSwitcherButton`, `WindowSizeClass`. |
| `fonts/` | Inter 4.1 variable font and its SIL Open Font License (`OFL.txt`). |

The package holds no user-facing strings: labels come from the app.

## Updating tokens

```sh
cp <canonical tokens.json> tokens/tokens.json
dart run tool/gen_tokens.dart
flutter test   # includes the check that the generated file is up to date
```

Call `registerFynonaLicenses()` at start-up to list the Inter licence on the
licence page.
