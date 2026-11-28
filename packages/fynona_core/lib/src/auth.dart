import 'dart:async';

import 'package:dio/dio.dart';

import 'errors.dart';
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

  /// In an httpOnly cookie ([AuthRoutes.refreshCookie]); the access token
  /// stays only in memory (web).
  cookie,
}

/// Whether there is a signed-in session.
enum AuthState {
  /// Not known yet: [AuthSession.restore] has not finished.
  unknown,
  signedOut,
  signedIn,
}

/// The session routes of one API and the routes that take no
/// `Authorization` header (SEC-2, SEC-4, SEC-5).
final class AuthRoutes {
  const AuthRoutes({
    required this.login,
    required this.loginMfa,
    required this.refresh,
    required this.logout,
    this.passkeyLogin,
    this.unauthenticated = const {},
    required this.refreshCookie,
    this.loginTakesTokenDelivery = true,
  });

  /// Password sign-in: `200` with tokens or `202` with a second-factor
  /// challenge.
  final String login;

  /// Second step of a sign-in with a TOTP or recovery code.
  final String loginMfa;
  final String refresh;
  final String logout;

  /// Passkey sign-in with a WebAuthn assertion; null where the API has none.
  final String? passkeyLogin;

  /// Further routes that open, renew or recover a session, or need none;
  /// [login], [loginMfa], [refresh] and [passkeyLogin] never take the header.
  final Set<String> unauthenticated;

  /// Name of the httpOnly refresh cookie of [TokenMode.cookie]; the token
  /// itself never reaches Dart code.
  final String refreshCookie;

  /// Whether the [login] body takes `token_delivery`; an API whose password
  /// step never answers tokens may refuse the member.
  final bool loginTakesTokenDelivery;

  /// Whether a request to [path] goes without `Authorization`.
  bool isUnauthenticated(String path) =>
      path == login ||
      path == loginMfa ||
      path == refresh ||
      path == passkeyLogin ||
      unauthenticated.contains(path);
}

/// The tokens of an opened or renewed session: `TokenPair` of every Fynona
/// API.
final class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.json = const {},
  });

  /// Throws a [FormatException] without an `access_token` string or with a
  /// `refresh_token` of another type.
  factory AuthTokens.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('A token pair must be an object', json);
    }
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    if (access is! String) {
      throw FormatException('access_token must be a string', access);
    }
    if (refresh != null && refresh is! String) {
      throw FormatException('refresh_token must be a string', refresh);
    }
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh as String?,
      json: json,
    );
  }

  final String accessToken;

  /// Absent in [TokenMode.cookie], where the cookie holds it.
  final String? refreshToken;

  /// The whole answer, for an API's own model of it.
  final Map<String, Object?> json;
}

/// The `202` answer of a password that needs a second factor: `MfaChallenge`
/// of every Fynona API (SEC-2).
final class AuthChallenge {
  const AuthChallenge({
    required this.mfaToken,
    required this.expiresIn,
    required this.methods,
    this.json = const {},
  });

  /// Throws a [FormatException] when a member is missing or of another type.
  factory AuthChallenge.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('A challenge must be an object', json);
    }
    final token = json['mfa_token'];
    final expiresIn = json['expires_in'];
    final methods = json['methods'];
    if (token is! String) {
      throw FormatException('mfa_token must be a string', token);
    }
    if (expiresIn is! int) {
      throw FormatException('expires_in must be an integer', expiresIn);
    }
    if (methods is! List<Object?> || methods.any((m) => m is! String)) {
      throw FormatException('methods must be strings', methods);
    }
    return AuthChallenge(
      mfaToken: token,
      expiresIn: expiresIn,
      methods: methods.cast<String>(),
      json: json,
    );
  }

  /// Single-use token of the second step.
  final String mfaToken;

  /// Seconds until [mfaToken] expires.
  final int expiresIn;

  /// The second factors the account accepts, e.g. `totp`, `recovery_code`.
  final List<String> methods;

  /// The whole answer, for an API's own model of it.
  final Map<String, Object?> json;
}

/// The answer to a password sign-in.
sealed class AuthLoginOutcome {
  const AuthLoginOutcome();
}

/// The session is open.
final class AuthSignedIn extends AuthLoginOutcome {
  const AuthSignedIn(this.tokens);

  final AuthTokens tokens;
}

/// The password is right and a second factor must finish the sign-in with
/// [AuthSession.completeMfa] (SEC-2).
final class AuthMfaRequired extends AuthLoginOutcome {
  const AuthMfaRequired(this.challenge);

  final AuthChallenge challenge;
}

/// Request extra that marks a request already repeated after a refresh.
const _retriedExtra = 'fynona.auth.retried';

/// The signed-in session of one API over an [HttpTransport] (SEC-4, SEC-5).
///
/// Adds `Authorization: Bearer` to every request outside
/// [AuthRoutes.isUnauthenticated]. A `401` on such a request refreshes the
/// tokens once and repeats the request; parallel `401`s share one refresh
/// (single flight). A refresh the server rejects (expired, revoked, reused)
/// signs out: the in-memory access token and the stored refresh token are
/// dropped. A refresh that fails for lack of a connection keeps the session
/// and passes the original error on. A `403` whose code is in
/// [revokingForbiddenCodes] on an authenticated request signs out at once.
///
/// In [TokenMode.cookie] every request is sent with browser credentials so
/// the refresh cookie is stored and sent across origins of the same site;
/// the refresh token never reaches Dart code.
final class AuthSession {
  AuthSession(
    this.transport, {
    required this.routes,
    required this.mode,
    RefreshTokenStore? store,
    this.device,
    this.revokingForbiddenCodes = const {},
  }) : store = store ?? MemoryRefreshTokenStore() {
    transport.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final HttpTransport transport;
  final AuthRoutes routes;
  final TokenMode mode;
  final RefreshTokenStore store;

  /// The device name shown in the session list (`device` of the sign-in).
  final String? device;

  /// Problem codes of a `403` that mean the session can no longer be used
  /// here, e.g. an account that lost the role the API needs.
  final Set<String> revokingForbiddenCodes;

  String? _accessToken;
  Future<bool>? _refreshing;
  AuthState _state = AuthState.unknown;
  final _changes = StreamController<AuthState>.broadcast();

  AuthState get state => _state;

  /// Emits [state] whenever it changes.
  Stream<AuthState> get changes => _changes.stream;

  /// The access token of the session; kept only in memory.
  String? get accessToken => _accessToken;

  String get _delivery => mode.name;

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
  Future<AuthLoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final response = await transport.call(
      () => transport.dio.post<Object?>(
        routes.login,
        data: {
          'email': email,
          'password': password,
          'device': ?device,
          if (routes.loginTakesTokenDelivery) 'token_delivery': _delivery,
        },
        options: Options(
          validateStatus: (status) => status == 200 || status == 202,
        ),
      ),
    );
    if (response.statusCode == 202) {
      return AuthMfaRequired(AuthChallenge.fromJson(response.data));
    }
    final tokens = AuthTokens.fromJson(response.data);
    await _signIn(tokens);
    return AuthSignedIn(tokens);
  }

  /// Completes a sign-in that answered [AuthMfaRequired] with a TOTP [code]
  /// or a [recoveryCode] (SEC-2).
  Future<AuthTokens> completeMfa(
    AuthChallenge challenge, {
    String? code,
    String? recoveryCode,
  }) => _openWith(routes.loginMfa, {
    'mfa_token': challenge.mfaToken,
    'code': ?code,
    'recovery_code': ?recoveryCode,
    'token_delivery': _delivery,
  });

  /// Signs in with the assertion of a passkey ceremony (SEC-1). Throws a
  /// [StateError] when the API has no [AuthRoutes.passkeyLogin].
  Future<AuthTokens> loginWithPasskey({
    required String ceremonyId,
    required Map<String, Object?> credential,
  }) {
    final route = routes.passkeyLogin;
    if (route == null) throw StateError('No passkey sign-in route');
    return _openWith(route, {
      'ceremony_id': ceremonyId,
      'credential': credential,
      'device': ?device,
      'token_delivery': _delivery,
    });
  }

  Future<AuthTokens> _openWith(String route, Map<String, Object?> body) async {
    final tokens = await _tokens(route, body);
    await _signIn(tokens);
    return tokens;
  }

  Future<AuthTokens> _tokens(String route, Map<String, Object?> body) =>
      transport.call(() async {
        final response = await transport.dio.post<Object?>(route, data: body);
        return AuthTokens.fromJson(response.data);
      });

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
      // The secret store failed or the answer was not a token pair: the
      // session cannot be kept on this device.
      await _forget();
      return false;
    }
  }

  Future<AuthTokens> _renew(String? refreshToken) => _tokens(routes.refresh, {
    'refresh_token': ?refreshToken,
    'token_delivery': _delivery,
  });

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
        if (statusOf(error) != 401) rethrow;
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
  Future<void> _signIn(AuthTokens tokens) async {
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

  /// The logout route with [accessToken], which need not be the one in
  /// memory; a `401` is final here, not a reason to refresh.
  Future<void> _endServerSession(String accessToken) => transport.call(
    () => transport.dio.post<Object?>(
      routes.logout,
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
    final status = statusOf(error);
    return status != null &&
        status >= 400 &&
        status < 500 &&
        status != 408 &&
        status != 426 &&
        status != 429;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (mode == TokenMode.cookie) options.extra['withCredentials'] = true;
    final token = _accessToken;
    if (token != null && !routes.isUnauthenticated(options.uri.path)) {
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
    final status = error.response?.statusCode;
    if (status == 403 && sentToken != null && _revokes(error)) {
      await _forget();
      handler.next(error);
      return;
    }
    if (status != 401 ||
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

  bool _revokes(DioException error) {
    if (revokingForbiddenCodes.isEmpty) return false;
    final exception = transport.exceptionOf(error);
    return exception is ApiProblemException &&
        revokingForbiddenCodes.contains(exception.code);
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
