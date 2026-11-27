import 'dart:async';

import 'package:dio/dio.dart';

import 'errors.dart';
import 'gen/fynona_api.dart';
import 'transport.dart';

/// Where the refresh token of the signed-in session lives between app runs
/// (SEC-5): the platform's secret store on mobile and desktop. Web keeps it
/// in the server's httpOnly cookie instead and needs no store.
abstract interface class RefreshTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// A [RefreshTokenStore] that forgets everything when the process ends.
final class MemoryRefreshTokenStore implements RefreshTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// How the server hands out the refresh token (SEC-5).
enum TokenMode {
  /// In the response body, kept in a [RefreshTokenStore] (mobile, desktop).
  body,

  /// In the `fynona_refresh` httpOnly cookie; the access token stays only in
  /// memory (web).
  cookie,
}

/// Whether there is a signed-in session.
enum AuthState {
  /// Not known yet: [AuthSession.restore] has not finished.
  unknown,
  signedOut,
  signedIn,
}

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

/// Request extra that marks a request already repeated after a refresh.
const _retriedExtra = 'fynona.auth.retried';

/// Routes that take no `Authorization` header: they open, renew or recover a
/// session, or need none.
const _publicAuthPaths = {
  '/v1/auth/register',
  '/v1/auth/email/verify',
  '/v1/auth/login',
  '/v1/auth/login/mfa',
  '/v1/auth/refresh',
  '/v1/auth/password/reset',
  '/v1/auth/password/reset/confirm',
  '/v1/auth/passkeys/login/options',
  '/v1/auth/passkeys/login',
};

/// The signed-in session over an [ApiTransport] (SEC-4, SEC-5).
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
    required this.mode,
    RefreshTokenStore? store,
    this.device,
  }) : store = store ?? MemoryRefreshTokenStore() {
    transport.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final ApiTransport transport;
  final TokenMode mode;
  final RefreshTokenStore store;

  /// The device name shown in the session list (`device` of the sign-in).
  final String? device;

  String? _accessToken;
  Future<bool>? _refreshing;
  AuthState _state = AuthState.unknown;
  final _changes = StreamController<AuthState>.broadcast();

  AuthState get state => _state;

  /// Emits [state] whenever it changes.
  Stream<AuthState> get changes => _changes.stream;

  /// The access token of the session; kept only in memory.
  String? get accessToken => _accessToken;

  TokenDelivery get _delivery =>
      mode == TokenMode.cookie ? TokenDelivery.cookie : TokenDelivery.body;

  /// Resumes the session of an earlier run, if any: trades the stored refresh
  /// token (or the cookie) for a new pair.
  /// Ends [AuthState.signedOut] whenever the session cannot be resumed,
  /// including a secret store that cannot be read or cleared.
  Future<AuthState> restore() async {
    if (!await refresh() && _state == AuthState.unknown) {
      // No connection: nothing proves the session is gone, but nothing can
      // be shown either; the user signs in again.
      _set(AuthState.signedOut);
    }
    return _state;
  }

  /// Signs in with email and password (SEC-3). Throws the [ApiException] of
  /// a refusal, e.g. `401 auth.invalid_credentials`.
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final body = LoginRequest(
      email: Email(email),
      password: password,
      device: device,
      tokenDelivery: _delivery,
    );
    final response = await transport.call(
      (_) => transport.dio.post<Object?>(
        '/v1/auth/login',
        data: body.toJson(),
        options: Options(
          validateStatus: (status) => status == 200 || status == 202,
        ),
      ),
    );
    final json = response.data! as Map<String, Object?>;
    if (response.statusCode == 202) {
      return MfaRequired(MfaChallenge.fromJson(json));
    }
    final tokens = TokenPair.fromJson(json);
    await _signIn(tokens);
    return SignedIn(tokens);
  }

  /// Completes a sign-in that answered [MfaRequired] with a TOTP [code] or a
  /// [recoveryCode] (SEC-2).
  Future<void> completeMfa(
    MfaChallenge challenge, {
    String? code,
    String? recoveryCode,
  }) async {
    final tokens = await transport.call(
      (api) => api.auth.loginMfa(
        body: LoginMfaRequest(
          mfaToken: challenge.mfaToken,
          code: code == null ? null : TotpCode(code),
          recoveryCode: recoveryCode,
          tokenDelivery: _delivery,
        ),
      ),
    );
    await _signIn(tokens);
  }

  /// Signs in with the assertion of a passkey ceremony started by
  /// `beginPasskeyLogin` (SEC-1).
  Future<void> loginWithPasskey({
    required String ceremonyId,
    required Map<String, Object?> credential,
  }) async {
    final tokens = await transport.call(
      (api) => api.auth.finishPasskeyLogin(
        body: PasskeyLogin(
          ceremonyId: ceremonyId,
          credential: credential,
          device: device,
          tokenDelivery: _delivery,
        ),
      ),
    );
    await _signIn(tokens);
  }

  /// Trades the refresh token for a new pair; parallel callers share one
  /// request. Returns whether the session is renewed.
  Future<bool> refresh() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  Future<bool> _refresh() async {
    try {
      final stored = mode == TokenMode.body ? await store.read() : null;
      if (mode == TokenMode.body && stored == null) {
        await _setSignedOut();
        return false;
      }
      await _signIn(await _renew(stored));
      return true;
    } on ApiException catch (error) {
      if (_isRejection(error)) await _forget();
      return false;
    } on Object {
      // The secret store failed: the session cannot be kept on this device.
      await _forget();
      return false;
    }
  }

  Future<TokenPair> _renew(String? refreshToken) => transport.call(
    (api) => api.auth.refreshSession(
      body: RefreshRequest(
        refreshToken: refreshToken,
        tokenDelivery: _delivery,
      ),
    ),
  );

  /// Ends the session on the server and forgets it here. Forgets it even
  /// when the server cannot be reached. In [TokenMode.cookie] without an
  /// access token in memory, the cookie is traded for one first, so the
  /// server ends that session and clears the cookie. An access token the
  /// server no longer accepts is renewed once (shared with any refresh in
  /// flight) and the sign-out repeated with the new one.
  Future<void> logout() async {
    try {
      final token =
          _accessToken ??
          (mode == TokenMode.cookie ? (await _renew(null)).accessToken : null);
      if (token == null) return;
      try {
        await _endServerSession(token);
      } on ApiException catch (error) {
        if (_statusOf(error) != 401) rethrow;
        final renewed =
            (_accessToken != null && _accessToken != token) || await refresh();
        final fresh = _accessToken;
        if (!renewed || fresh == null) rethrow;
        await _endServerSession(fresh);
      }
    } on ApiException {
      // The local session ends anyway.
    } finally {
      await _setSignedOut();
    }
  }

  /// Forgets the session without telling the server.
  Future<void> signOutLocally() => _setSignedOut();

  void dispose() => _changes.close();

  /// Keeps the access token only once the refresh token is stored. When the
  /// store fails, the new server session is closed best-effort, nothing of it
  /// stays here and the store's error is rethrown.
  Future<void> _signIn(TokenPair tokens) async {
    final refreshToken = tokens.refreshToken;
    if (mode == TokenMode.body && refreshToken != null) {
      try {
        await store.write(refreshToken);
      } on Object {
        try {
          await _endServerSession(tokens.accessToken);
        } on ApiException {
          // Best effort: the server session expires on its own.
        }
        await _forget();
        rethrow;
      }
    }
    _accessToken = tokens.accessToken;
    _set(AuthState.signedIn);
  }

  /// `POST /v1/auth/logout` with [accessToken], which need not be the one in
  /// memory; a `401` is final here, not a reason to refresh.
  Future<void> _endServerSession(String accessToken) => transport.call(
    (_) => transport.dio.post<Object?>(
      '/v1/auth/logout',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        extra: {_retriedExtra: true},
      ),
    ),
  );

  /// Signed out even when the store cannot be cleared; the store's error is
  /// rethrown after the state is set.
  Future<void> _setSignedOut() async {
    _accessToken = null;
    try {
      await store.clear();
    } finally {
      _set(AuthState.signedOut);
    }
  }

  /// [_setSignedOut] for paths that cannot report a store failure.
  Future<void> _forget() async {
    try {
      await _setSignedOut();
    } on Object {
      // Already signed out; nothing else can be done with a broken store.
    }
  }

  void _set(AuthState next) {
    if (next == _state) return;
    _state = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  /// A definite answer that the refresh token is no good, as opposed to a
  /// missing connection or a server failure.
  static bool _isRejection(ApiException error) {
    final status = _statusOf(error);
    return status != null &&
        status >= 400 &&
        status < 500 &&
        status != 408 &&
        status != 426 &&
        status != 429;
  }

  static int? _statusOf(ApiException error) => switch (error) {
    ApiProblemException(:final status) => status,
    ApiHttpException(:final status) => status,
    _ => null,
  };

  static bool _isPublic(RequestOptions options) =>
      _publicAuthPaths.contains(options.uri.path);

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (mode == TokenMode.cookie) options.extra['withCredentials'] = true;
    final token = _accessToken;
    if (token != null && !_isPublic(options)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    final sentToken = _bearerOf(options);
    if (error.response?.statusCode != 401 ||
        sentToken == null ||
        options.extra[_retriedExtra] == true) {
      handler.next(error);
      return;
    }
    // Another request may have renewed the tokens since this one was sent.
    final renewed =
        (_accessToken != null && _accessToken != sentToken) || await refresh();
    if (!renewed) {
      handler.next(error);
      return;
    }
    options.extra[_retriedExtra] = true;
    try {
      handler.resolve(await transport.dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static String? _bearerOf(RequestOptions options) {
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() != 'authorization') continue;
      final value = entry.value;
      if (value is String && value.startsWith('Bearer ')) {
        return value.substring('Bearer '.length);
      }
    }
    return null;
  }
}
