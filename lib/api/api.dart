import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

/// App version sent in `User-Agent` (API-12); equals `version` in pubspec.yaml
/// without the build number (a test keeps them in step).
const clientVersion = '0.1.0';

/// API origin, set at build time: `--dart-define=FYNONA_API_URL=https://…`.
/// Empty means the same origin as the web app.
const apiBaseUrl = String.fromEnvironment('FYNONA_API_URL');

/// Platform name for `User-Agent: Fynona/<version> (<platform>)`.
String clientPlatform() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux || TargetPlatform.fuchsia => 'linux',
  };
}

/// The one API transport of the app (retries, budget, breakers, headers).
final apiTransportProvider = Provider<ApiTransport>((ref) {
  final transport = ApiTransport(
    baseUrl: apiBaseUrl,
    clientVersion: clientVersion,
    platform: clientPlatform(),
  );
  ref.onDispose(transport.close);
  return transport;
});

/// Whether a circuit breaker of the transport is open: the shell shows
/// «no connection» (API-63).
final offlineProvider = StreamProvider<bool>((ref) async* {
  final transport = ref.watch(apiTransportProvider);
  yield transport.isOffline;
  yield* transport.offlineChanges;
});
