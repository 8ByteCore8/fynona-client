import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app appearance switches (CLI-32). Not persisted yet (M2 adds storage).
@immutable
class Appearance {
  const Appearance({this.noGlass = false, this.highContrast = false});

  /// Manual «no glass»: opaque chrome.
  final bool noGlass;

  /// In-app high contrast, in addition to the OS setting.
  final bool highContrast;

  Appearance copyWith({bool? noGlass, bool? highContrast}) => Appearance(
    noGlass: noGlass ?? this.noGlass,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.noGlass == noGlass &&
      other.highContrast == highContrast;

  @override
  int get hashCode => Object.hash(noGlass, highContrast);
}

class AppearanceNotifier extends Notifier<Appearance> {
  @override
  Appearance build() => const Appearance();

  void setNoGlass(bool value) => state = state.copyWith(noGlass: value);

  void setHighContrast(bool value) =>
      state = state.copyWith(highContrast: value);
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

/// Whether the platform renders backdrop blur. All current Flutter renderers
/// do; a renderer known to lack it (or a test) overrides this with false.
final platformBlurSupportedProvider = Provider<bool>((ref) => true);

/// Set once per session when the frame detector finds blur too slow.
class GlassDegradedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trip() => state = true;
}

final glassDegradedProvider = NotifierProvider<GlassDegradedNotifier, bool>(
  GlassDegradedNotifier.new,
);

/// Blur is used in auto mode only when supported and not degraded.
final blurSupportedProvider = Provider<bool>(
  (ref) =>
      ref.watch(platformBlurSupportedProvider) &&
      !ref.watch(glassDegradedProvider),
);
