import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

import '../api/api.dart';
import '../auth/auth.dart';
import '../auth/passkey.dart';
import '../shell/save_file.dart';

/// The signed-in user's sessions, most recently used first (SEC-4).
final sessionsProvider = FutureProvider.autoDispose<List<Session>>((ref) async {
  final transport = ref.watch(apiTransportProvider);
  final list = await transport.call((api) => api.sessions.listSessions());
  return list.items;
});

/// Whether TOTP is on and how many recovery codes are left (SEC-2).
final totpStatusProvider = FutureProvider.autoDispose<TotpStatus>(
  (ref) => ref.watch(apiTransportProvider).call((api) => api.auth.getTotp()),
);

/// The user's passkeys (SEC-1); listed only where they can be added.
final passkeysProvider = FutureProvider.autoDispose<List<Passkey>>((ref) async {
  final transport = ref.watch(apiTransportProvider);
  final list = await transport.call((api) => api.auth.listPasskeys());
  return list.items;
});

/// The account with its version for `If-Match` (API-23).
final accountProvider = FutureProvider.autoDispose<Versioned<Profile>>(
  (ref) => ref.watch(apiTransportProvider).getProfile(),
);

/// The user's plan and entitlement values, for display only (MON-3).
final entitlementsProvider = FutureProvider.autoDispose<Entitlements>(
  (ref) => ref
      .watch(apiTransportProvider)
      .call((api) => api.entitlements.getEntitlements()),
);

/// Every plan in display order (MON-2).
final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  final transport = ref.watch(apiTransportProvider);
  final list = await transport.call((api) => api.entitlements.listPlans());
  return list.items;
});

/// Every `402 entitlement.exceeded` of the session (MON-4).
final entitlementRejectionsProvider =
    StreamProvider<EntitlementExceededException>(
      (ref) => ref.watch(apiTransportProvider).entitlementRejections,
    );

/// Saves a file the user asked for and returns where it went (a file name
/// on web, a path elsewhere).
typedef FileSaver = Future<String> Function(
  String name,
  Uint8List bytes,
  String mimeType,
);

final fileSaverProvider = Provider<FileSaver>((ref) => saveFile);

/// Runs a WebAuthn registration with the server's options and returns the
/// new credential's JSON.
typedef PasskeyRegistrar = Future<Map<String, Object?>> Function(
  Map<String, Object?> options,
);

/// The browser's passkey registration; null where passkeys are not offered
/// (mobile and desktop until M2b, browsers without WebAuthn JSON support).
final passkeyRegistrarProvider = Provider<PasskeyRegistrar?>(
  (ref) => kIsWeb && passkeysSupported ? createPasskey : null,
);

/// How often a pending export is asked about.
final exportPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// A fresh `Idempotency-Key` for one user action (API-20); a retry of the
/// same request reuses it inside the transport.
String newIdempotencyKey() => UuidV7().next();

/// Deletes the account (SEC-60) and forgets the session here: the server has
/// already ended every session.
Future<void> deleteAccount(WidgetRef ref, DeleteAccountRequest request) async {
  await ref
      .read(apiTransportProvider)
      .call((api) => api.account.deleteAccount(body: request));
  await ref
      .read(authSessionProvider)
      .signOutLocally()
      .catchError((Object _) {});
}
