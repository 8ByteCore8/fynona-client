import '../tokens/tokens.g.dart';

/// Material 3 window size classes by window width (`breakpoint.*`).
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large;

  static WindowSizeClass of(double width) =>
      width < FynonaTokens.breakpointMedium
      ? compact
      : width < FynonaTokens.breakpointExpanded
      ? medium
      : width < FynonaTokens.breakpointLarge
      ? expanded
      : large;

  /// Compact windows use the bottom bar; wider ones the rail (CLI-10, CLI-13).
  bool get usesBottomBar => this == compact;
}
