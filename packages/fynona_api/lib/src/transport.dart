import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'circuit_breaker.dart';
import 'contract.dart';
import 'errors.dart';
import 'gen/fynona_api.dart';
import 'retry.dart';
import 'uuid.dart';

/// Connection timeout (API-64).
const connectTimeout = Duration(seconds: 10);

/// Read timeout (API-64).
const readTimeout = Duration(seconds: 30);

const _mutatingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

/// The endpoint group of a request for the circuit breaker: the first two
/// path segments, e.g. `v1/meta` (API-63).
String endpointGroup(Uri uri) =>
    uri.pathSegments.where((segment) => segment.isNotEmpty).take(2).join('/');

/// The Fynona API client: generated [api] over a resilient [dio] (API-60…64).
///
/// Every request gets `X-Request-ID`, `User-Agent` and `X-Fynona-API`,
/// mutating requests an `Idempotency-Key`; all of them are reused on every
/// retry (API-12, API-20, API-21). Use [call] to get typed [ApiException]s
/// instead of `DioException`.
final class ApiTransport {
  ApiTransport({
    required String baseUrl,
    required String clientVersion,
    required String platform,
    String declaredContractVersion = contractVersion,
    HttpClientAdapter? adapter,
    RetryPolicy retryPolicy = const RetryPolicy(),
    RetryBudget? retryBudget,
    CircuitBreaker Function(void Function(CircuitState) onStateChange)?
    breakerFactory,
    DateTime Function()? now,
    Random? random,
    Future<void> Function(Duration)? sleep,
    UuidV7? uuid,
  }) {
    final clock = now ?? DateTime.now;
    _adapter = ResilientAdapter(
      adapter ?? HttpClientAdapter(),
      userAgent: 'Fynona/$clientVersion ($platform)',
      contractVersion: declaredContractVersion,
      retryPolicy: retryPolicy,
      retryBudget: retryBudget ?? RetryBudget(now: clock),
      breakerFactory:
          breakerFactory ??
          (onStateChange) =>
              CircuitBreaker(now: clock, onStateChange: onStateChange),
      random: random ?? Random(),
      sleep: sleep ?? Future<void>.delayed,
      uuid: uuid ?? UuidV7(now: clock),
    );
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: readTimeout,
      ),
    )..httpClientAdapter = _adapter;
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final exception = apiExceptionOf(error);
          if (exception is UpgradeRequiredException &&
              exception.code == apiVersionUnsupportedCode &&
              !_rejected.isClosed) {
            _rejected.add(exception);
          }
          handler.next(error);
        },
      ),
    );
    api = FynonaApi(dio);
  }

  late final ResilientAdapter _adapter;
  final _rejected = StreamController<UpgradeRequiredException>.broadcast();

  /// The underlying HTTP client; its adapter is the resilient one.
  late final Dio dio;

  /// Generated endpoint clients.
  late final FynonaApi api;

  /// Runs [request] and turns transport failures into [ApiException]s.
  Future<T> call<T>(Future<T> Function(FynonaApi api) request) async {
    try {
      return await request(api);
    } on DioException catch (error) {
      throw apiExceptionOf(error);
    }
  }

  /// Whether a circuit breaker is not closed: the UI shows «no connection».
  bool get isOffline => _adapter.isOffline;

  /// Emits [isOffline] whenever it changes.
  Stream<bool> get offlineChanges => _adapter.offlineChanges;

  /// Every `426 api_version_unsupported` the server answers, on any route:
  /// this client is outdated (API-12).
  Stream<UpgradeRequiredException> get contractRejections => _rejected.stream;

  /// Reads `GET /v1/meta` and decides whether this client's contract version
  /// works with the server (API-12). `404` or `410` on that route and a `426`
  /// with code `api_version_unsupported` mean the client is outdated. Other
  /// failures throw their [ApiException]; a server version that is not SemVer
  /// throws [ContractVersionException].
  Future<ContractCompatibility> checkContract() async {
    try {
      final meta = await call((api) => api.meta.getMeta());
      return checkCompatibility(
        client: _adapter.contractVersion,
        server: meta.contractVersion,
        minimum: meta.minContractVersion,
      );
    } on UpgradeRequiredException catch (error) {
      if (error.code == apiVersionUnsupportedCode) {
        return ContractCompatibility.clientOutdated;
      }
      rethrow;
    } on ApiException catch (error) {
      final status = switch (error) {
        ApiProblemException(:final status) => status,
        ApiHttpException(:final status) => status,
        _ => null,
      };
      if (status == 404 || status == 410) {
        return ContractCompatibility.clientOutdated;
      }
      rethrow;
    }
  }

  void close() {
    _rejected.close();
    dio.close(force: true);
  }
}

/// Maps a dio failure to the typed error of the API (API-12, API-30).
ApiException apiExceptionOf(DioException error) {
  final inner = error.error;
  if (inner is ApiException) return inner;
  final response = error.response;
  if (response == null) return ApiNetworkException(error);
  final status = response.statusCode ?? 0;
  final data = response.data;
  final contentType = response.headers.value(Headers.contentTypeHeader);
  if (data is Map<String, Object?> &&
      contentType != null &&
      contentType.startsWith('application/problem+json')) {
    try {
      final problem = Problem.fromJson(data);
      return status == 426
          ? UpgradeRequiredException(problem)
          : ApiProblemException(problem);
    } on Object {
      // A malformed problem body falls back to the bare status below.
    }
  }
  return ApiHttpException(
    status,
    requestId: response.headers.value('x-request-id'),
  );
}

/// A dio adapter that adds the Fynona headers and the retry, retry budget and
/// circuit breaker rules around an [inner] adapter (API-20, API-21, API-60…63).
final class ResilientAdapter implements HttpClientAdapter {
  ResilientAdapter(
    this.inner, {
    required this.userAgent,
    required this.contractVersion,
    required this.retryPolicy,
    required this.retryBudget,
    required this._breakerFactory,
    required this._random,
    required this._sleep,
    required this._uuid,
  });

  final HttpClientAdapter inner;
  final String userAgent;

  /// Value of `X-Fynona-API` unless the request already declares one.
  final String contractVersion;
  final RetryPolicy retryPolicy;
  final RetryBudget retryBudget;
  final CircuitBreaker Function(void Function(CircuitState)) _breakerFactory;
  final Random _random;
  final Future<void> Function(Duration) _sleep;
  final UuidV7 _uuid;

  final _breakers = <String, CircuitBreaker>{};
  final _offline = StreamController<bool>.broadcast();
  bool _wasOffline = false;

  bool get isOffline =>
      _breakers.values.any((b) => b.state != CircuitState.closed);

  Stream<bool> get offlineChanges => _offline.stream;

  /// The breaker of [group], created on first use.
  CircuitBreaker breakerFor(String group) =>
      _breakers.putIfAbsent(group, () => _breakerFactory((_) => _notify()));

  void _notify() {
    final offline = isOffline;
    if (offline == _wasOffline) return;
    _wasOffline = offline;
    _offline.add(offline);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _addHeaders(options);
    final breaker = breakerFor(endpointGroup(options.uri));
    final body = requestStream == null ? null : await _buffer(requestStream);
    final retryable = retryPolicy.isRetryableRequest(
      options.method,
      options.headers,
    );
    retryBudget.recordPrimary();
    for (var retry = 0; ; retry++) {
      if (!breaker.tryAcquire()) {
        throw CircuitOpenException(endpointGroup(options.uri));
      }
      ResponseBody? response;
      Object? failure;
      StackTrace? failureTrace;
      try {
        response = await inner.fetch(
          options,
          body == null ? null : Stream.value(body),
          cancelFuture,
        );
      } on Object catch (error, trace) {
        failure = error;
        failureTrace = trace;
      }
      final cancelled =
          failure is DioException && failure.type == DioExceptionType.cancel;
      final status = response?.statusCode;
      final serverFailed = failure != null || (status != null && status >= 500);
      breaker.record(success: cancelled || !serverFailed);

      final again =
          !cancelled &&
          retryable &&
          retry < retryPolicy.maxRetries &&
          (failure != null || retryPolicy.isRetryableStatus(status!)) &&
          breaker.state == CircuitState.closed &&
          retryBudget.tryRetry();
      if (!again) {
        if (failure != null) Error.throwWithStackTrace(failure, failureTrace!);
        return response!;
      }
      final retryAfter = response?.headers.entries
          .where((header) => header.key.toLowerCase() == 'retry-after')
          .firstOrNull
          ?.value
          .firstOrNull;
      await response?.stream.drain<void>();
      await _sleep(retryPolicy.delay(retry, _random, retryAfter: retryAfter));
    }
  }

  void _addHeaders(RequestOptions options) {
    final headers = options.headers;
    bool has(String name) =>
        headers.keys.any((key) => key.toLowerCase() == name);
    if (!has('x-request-id')) headers['X-Request-ID'] = _uuid.next();
    headers['User-Agent'] = userAgent;
    if (!has(contractVersionHeader.toLowerCase())) {
      headers[contractVersionHeader] = contractVersion;
    }
    if (_mutatingMethods.contains(options.method.toUpperCase()) &&
        !has(idempotencyKeyHeader)) {
      headers['Idempotency-Key'] = _uuid.next();
    }
  }

  static Future<Uint8List> _buffer(Stream<Uint8List> stream) async {
    final builder = BytesBuilder(copy: false);
    await stream.forEach(builder.add);
    return builder.takeBytes();
  }

  @override
  void close({bool force = false}) {
    inner.close(force: force);
    _offline.close();
  }
}
