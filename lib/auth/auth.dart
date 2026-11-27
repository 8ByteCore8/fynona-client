import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

import '../api/api.dart';
import 'passkey.dart';
import 'token_store.dart';

export 'package:fynona_api/fynona_api.dart' show AuthState;

/// Web keeps the refresh token in the server's httpOnly cookie and the access
/// token only in memory; the other platforms keep the refresh token in the
/// platform's secret store (SEC-5).
final tokenModeProvider = Provider<TokenMode>(
  (ref) => kIsWeb ? TokenMode.cookie : TokenMode.body,
);

/// Where the refresh token lives between runs (unused in cookie mode).
final refreshTokenStoreProvider = Provider<RefreshTokenStore>(
  (ref) => ref.watch(tokenModeProvider) == TokenMode.cookie
      ? MemoryRefreshTokenStore()
      : SecureRefreshTokenStore(),
);

/// The session over the app's transport: Bearer header, refresh on `401`.
final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(
    ref.watch(apiTransportProvider),
    mode: ref.watch(tokenModeProvider),
    store: ref.watch(refreshTokenStoreProvider),
    device: 'Fynona ${clientPlatform()}',
  );
  ref.onDispose(session.dispose);
  return session;
});

/// Whether someone is signed in. Starts [AuthState.unknown] and resumes the
/// session of an earlier run right away.
final authStateProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final session = ref.watch(authSessionProvider);
    final changes = session.changes.listen(_onChange);
    ref.onDispose(changes.cancel);
    if (session.state == AuthState.unknown) {
      scheduleMicrotask(() async {
        try {
          await session.restore();
        } on Object {
          // restore() ends signed out by itself, also when the secret store
          // fails; this only keeps anything unexpected from leaving the app
          // on the splash screen. The state is signed out even if the store
          // cannot be cleared.
          await session.signOutLocally().catchError((Object _) {});
        }
      });
    }
    return session.state;
  }

  void _onChange(AuthState next) {
    if (next == AuthState.signedOut) _clearLocalData();
    state = next;
  }

  /// Ends the session on the server and drops everything of the account on
  /// this device: the stored refresh token, the in-memory access token and
  /// the local cache ([profileProvider] follows the state). Signed out even
  /// when the secret store cannot be cleared; that failure is not reported.
  Future<void> signOut() =>
      ref.read(authSessionProvider).logout().catchError((Object _) {});

  void _clearLocalData() {
    ref.invalidate(pendingRegistrationProvider);
    ref.invalidate(mfaChallengeProvider);
  }
}

/// The signed-in account (`GET /v1/me`), the local cache of account data:
/// null and empty again as soon as the session ends.
final profileProvider = FutureProvider<Profile?>((ref) async {
  if (ref.watch(authStateProvider) != AuthState.signedIn) return null;
  final transport = ref.watch(apiTransportProvider);
  return transport.call((api) => api.account.getMe());
});

/// Runs a WebAuthn sign-in ceremony with the server's options and returns
/// the assertion JSON.
typedef PasskeyAuthenticator = Future<Map<String, Object?>> Function(
  Map<String, Object?> options,
);

/// The browser's passkey ceremony; null where passkey sign-in is not offered
/// (mobile and desktop until M2b, browsers without WebAuthn JSON support).
final passkeyAuthenticatorProvider = Provider<PasskeyAuthenticator?>(
  (ref) => kIsWeb && passkeysSupported ? getPasskeyAssertion : null,
);

/// The second-factor step of a sign-in in progress, in memory only.
final mfaChallengeProvider =
    NotifierProvider<MfaChallengeNotifier, MfaChallenge?>(
      MfaChallengeNotifier.new,
    );

class MfaChallengeNotifier extends Notifier<MfaChallenge?> {
  @override
  MfaChallenge? build() => null;

  void set(MfaChallenge? value) => state = value;
}

/// The email of the sign-up that waits for its confirmation, shown on
/// «check your email»; in memory only, never the password.
final pendingRegistrationProvider =
    NotifierProvider<PendingRegistrationNotifier, String?>(
      PendingRegistrationNotifier.new,
    );

class PendingRegistrationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}
