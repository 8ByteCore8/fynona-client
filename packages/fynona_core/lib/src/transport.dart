import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'circuit_breaker.dart';
import 'contract.dart';
import 'errors.dart';
import 'problem.dart';
import 'retry.dart';
import 'uuid.dart';

/// Connection timeout (API-64).
const connectTimeout = Duration(seconds: 10);

/// Read timeout (API-64).
const readTimeout = Duration(seconds: 30);

const _mutatingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

/// The endpoint group of a request for the circuit breaker: the first two
/// path segments of its path (API-63).
String endpointGroup(Uri uri) =>
    uri.pathSegments.where((segment) => segment.isNotEmpty).take(2).join('/');

/// Whether a mutating request goes without `Idempotency-Key` (API-20): the
/// routes whose bodies carry passwords or whose answers carry tokens, which
/// the server's idempotency store must not keep. Each API names its own.
typedef IdempotencyExemption = bool Function(String method, Uri uri);

/// Turns a problem answer with HTTP [status] into an API's own
/// [ApiProblemException] subtype; null keeps the core's choice.
typedef ProblemClassifier = ApiProblemException? Function(
  int status,
  ProblemDetails problem,
  Duration? retryAfter,
);

/// A resilient dio client for one Fynona API (API-12, API-20, API-21,
/// API-60…64), with nothing of a particular API in it.
///
/// Every request gets `X-Request-ID`, `User-Agent` and `X-Fynona-API`,
/// mutating requests an `Idempotency-Key` unless [idempotencyExempt] says
/// otherwise; all of them are reused on every retry. A request without the
/// key is never retried. Use [call] to get typed [ApiException]s instead of
/// `DioException`.
final class HttpTransport {
  HttpTransport({
    required String baseUrl,
    required String clientVersion,
    required String platform,
    required this.declaredContractVersion,
    required IdempotencyExemption idempotencyExempt,
    ProblemClassifier? classifyProblem,
    HttpClientAdapter? adapter,
    RetryPolicy retryPolicy = const RetryPolicy(),
    RetryBudget? retryBudget,
    CircuitBreaker Function(void Function(CircuitState) onStateChange)?
    breakerFactory,
    DateTime Function()? now,
    Random? random,
    Future<void> Function(Duration)? sleep,
    UuidV7? uuid,
  }) : _classify = classifyProblem {
    final clock = now ?? DateTime.now;
    _adapter = ResilientAdapter(
      adapter ?? HttpClientAdapter(),
      userAgent: 'Fynona/$clientVersion ($platform)',
      contractVersion: declaredContractVersion,
      idempotencyExempt: idempotencyExempt,
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
          final exception = exceptionOf(error);
          if (exception is ApiProblemException && !_problems.isClosed) {
            _problems.add(exception);
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Value of `X-Fynona-API` unless a request declares its own (API-12).
  final String declaredContractVersion;
  final ProblemClassifier? _classify;
  late final ResilientAdapter _adapter;
  final _problems = StreamController<ApiProblemException>.broadcast();

  /// The underlying HTTP client; its adapter is the resilient one.
  late final Dio dio;

  /// Runs [request] and turns transport failures into [ApiException]s.
  Future<T> call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw exceptionOf(error);
    }
  }

  /// The typed error of a dio failure, with this transport's classifier.
  ApiException exceptionOf(DioException error) =>
      apiExceptionOf(error, classify: _classify);

  /// Whether a circuit breaker is not closed: the UI shows «no connection».
  bool get isOffline => _adapter.isOffline;

  /// Emits [isOffline] whenever it changes.
  Stream<bool> get offlineChanges => _adapter.offlineChanges;

  /// Every problem answer on any route, so the app can react to codes such
  /// as a plan limit wherever they happen.
  Stream<ApiProblemException> get problems => _problems.stream;

  /// Every `426 api_version_unsupported` the server answers, on any route:
  /// this client is outdated (API-12).
  Stream<UpgradeRequiredException> get contractRejections => problems
      .where(
        (problem) =>
            problem is UpgradeRequiredException &&
            problem.code == apiVersionUnsupportedCode,
      )
      .cast<UpgradeRequiredException>();

  /// [checkContract] of [declaredContractVersion] with the versions
  /// [readMeta] reads from the API's meta route through this transport.
  Future<ContractCompatibility> checkContract(
    Future<ContractMeta> Function() readMeta,
  ) => _checkContract(() => call(readMeta), client: declaredContractVersion);

  void close() {
    _problems.close();
    dio.close(force: true);
  }
}

const _checkContract = checkContract;

/// Maps a dio failure to the typed error of the API (API-12, API-30).
/// [classify] may pick an API's own subtype for a problem answer.
ApiException apiExceptionOf(DioException error, {ProblemClassifier? classify}) {
  final inner = error.error;
  if (inner is ApiException) return inner;
  final response = error.response;
  if (response == null) return ApiNetworkException(error);
  final status = response.statusCode ?? 0;
  final data = response.data;
  final contentType = response.headers.value(Headers.contentTypeHeader);
  final retrySeconds = int.tryParse(
    response.headers.value('retry-after')?.trim() ?? '',
  );
  final retryAfter = retrySeconds == null || retrySeconds < 0
      ? null
      : Duration(seconds: retrySeconds);
  if (data is Map<String, Object?> &&
      contentType != null &&
      contentType.startsWith('application/problem+json')) {
    try {
      final problem = ProblemDetails.fromJson(data);
      if (status == 426) {
        return UpgradeRequiredException(problem, retryAfter: retryAfter);
      }
      return classify?.call(status, problem, retryAfter) ??
          ApiProblemException(problem, retryAfter: retryAfter);
    } on FormatException {
      // A malformed problem body falls back to the bare status below.
    }
  }
  return ApiHttpException(
    status,
    requestId: response.headers.value('x-request-id'),
    retryAfter: retryAfter,
  );
}

/// A dio adapter that adds the Fynona headers and the retry, retry budget and
/// circuit breaker rules around an [inner] adapter (API-20, API-21, API-60…63).
final class ResilientAdapter implements HttpClientAdapter {
  ResilientAdapter(
    this.inner, {
    required this.userAgent,
    required this.contractVersion,
    required this.idempotencyExempt,
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

  /// Mutating requests that go without `Idempotency-Key` (API-20).
  final IdempotencyExemption idempotencyExempt;
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
        !idempotencyExempt(options.method, options.uri) &&
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
