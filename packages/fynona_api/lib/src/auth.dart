import 'package:fynona_core/fynona_core.dart' as core;
import 'package:fynona_core/fynona_core.dart'
    show AuthRoutes, AuthState, RefreshTokenStore, TokenMode;

import 'gen/fynona_api.dart';
import 'transport.dart';

/// The session routes of the public API (SEC-2, SEC-4, SEC-5) and the routes
/// that take no `Authorization` header: they open, renew or recover a
/// session, or need none. Web mode keeps the refresh token in the
/// `fynona_refresh` cookie.
const publicAuthRoutes = AuthRoutes(
  login: '/v1/auth/login',
  loginMfa: '/v1/auth/login/mfa',
  refresh: '/v1/auth/refresh',
  logout: '/v1/auth/logout',
  passkeyLogin: '/v1/auth/passkeys/login',
  unauthenticated: {
    '/v1/auth/register',
    '/v1/auth/email/verify',
    '/v1/auth/password/reset',
    '/v1/auth/password/reset/confirm',
    '/v1/auth/passkeys/login/options',
  },
  refreshCookie: 'fynona_refresh',
);

/// The answer to a password sign-in.
sealed class LoginOutcome {
  const LoginOutcome();
}

/// The session is open.
final class SignedIn extends LoginOutcome {
  const SignedIn(this.tokens);

  final TokenPair tokens;
}

/// The password is right and the account has TOTP on: finish with
/// [AuthSession.completeMfa] (SEC-2).
final class MfaRequired extends LoginOutcome {
  const MfaRequired(this.challenge);

  final MfaChallenge challenge;
}

/// The signed-in session of the public API over an [ApiTransport] (SEC-4,
/// SEC-5): the core's session on [publicAuthRoutes], with the public models.
///
/// Adds `Authorization: Bearer` to every authenticated request. A `401` on
/// such a request refreshes the tokens once and repeats the request; parallel
/// `401`s share one refresh (single flight). A refresh the server rejects
/// (expired, revoked, reused) signs out: the in-memory access token and the
/// stored refresh token are dropped. A refresh that fails for lack of a
/// connection keeps the session and passes the original error on.
///
/// In [TokenMode.cookie] every request is sent with browser credentials so
/// the `fynona_refresh` cookie is stored and sent across origins of the same
/// site; the refresh token never reaches Dart code.
final class AuthSession {
  AuthSession(
    this.transport, {
    required TokenMode mode,
    RefreshTokenStore? store,
    String? device,
  }) : session = core.AuthSession(
         transport.http,
         routes: publicAuthRoutes,
         mode: mode,
         store: store,
         device: device,
       );

  final ApiTransport transport;

  /// The core session this one runs on.
  final core.AuthSession session;

  TokenMode get mode => session.mode;

  RefreshTokenStore get store => session.store;

  /// The device name shown in the session list (`device` of the sign-in).
  String? get device => session.device;

  AuthState get state => session.state;

  /// Emits [state] whenever it changes.
  Stream<AuthState> get changes => session.changes;

  /// The access token of the session; kept only in memory.
  String? get accessToken => session.accessToken;

  /// Resumes the session of an earlier run, if any: trades the stored refresh
  /// token (or the cookie) for a new pair.
  /// Ends [AuthState.signedOut] whenever the session cannot be resumed,
  /// including a secret store that cannot be read or cleared.
  Future<AuthState> restore() => session.restore();

  /// Signs in with email and password (SEC-3). Throws the [core.ApiException]
  /// of a refusal, e.g. `401 auth.invalid_credentials`.
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async => switch (await session.login(email: email, password: password)) {
    core.AuthSignedIn(:final tokens) => SignedIn(
      TokenPair.fromJson(tokens.json),
    ),
    core.AuthMfaRequired(:final challenge) => MfaRequired(
      MfaChallenge.fromJson(challenge.json),
    ),
  };

  /// Completes a sign-in that answered [MfaRequired] with a TOTP [code] or a
  /// [recoveryCode] (SEC-2).
  Future<void> completeMfa(
    MfaChallenge challenge, {
    String? code,
    String? recoveryCode,
  }) async {
    await session.completeMfa(
      core.AuthChallenge.fromJson(challenge.toJson()),
      code: code,
      recoveryCode: recoveryCode,
    );
  }

  /// Signs in with the assertion of a passkey ceremony started by
  /// `beginPasskeyLogin` (SEC-1).
  Future<void> loginWithPasskey({
    required String ceremonyId,
    required Map<String, Object?> credential,
  }) async {
    await session.loginWithPasskey(
      ceremonyId: ceremonyId,
      credential: credential,
    );
  }

  /// Trades the refresh token for a new pair; parallel callers share one
  /// request. Returns whether the session is renewed.
  Future<bool> refresh() => session.refresh();

  /// Ends the session on the server and forgets it here, even when the
  /// server cannot be reached; a stale access token is renewed once first
  /// (see [core.AuthSession.logout]).
  Future<void> logout() => session.logout();

  /// Forgets the session without telling the server.
  Future<void> signOutLocally() => session.signOutLocally();

  void dispose() => session.dispose();
}
