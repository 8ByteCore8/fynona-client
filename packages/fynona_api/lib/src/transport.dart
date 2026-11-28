import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fynona_core/fynona_core.dart';

import 'contract.dart';
import 'errors.dart';
import 'gen/fynona_api.dart';

/// Whether a mutating request is exempt from `Idempotency-Key` (API-20): every
/// `/v1/auth/*` route, `DELETE /v1/me` and `POST /v1/me/email`. Their
/// responses carry tokens or their bodies carry passwords, which the server's
/// idempotency store must not keep; without a key they are never retried.
bool takesNoIdempotencyKey(String method, Uri uri) {
  final path = uri.path;
  final verb = method.toUpperCase();
  return path.startsWith('/v1/auth/') ||
      (verb == 'DELETE' && path == '/v1/me') ||
      (verb == 'POST' && path == '/v1/me/email');
}

/// The Fynona public API client: generated [api] over the core's resilient
/// [HttpTransport] (API-60…64) with the public rules: [contractVersion],
/// [takesNoIdempotencyKey] and the `402` of [EntitlementExceededException].
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
  }) : http = HttpTransport(
         baseUrl: baseUrl,
         clientVersion: clientVersion,
         platform: platform,
         declaredContractVersion: declaredContractVersion,
         idempotencyExempt: takesNoIdempotencyKey,
         classifyProblem: classifyPublicProblem,
         adapter: adapter,
         retryPolicy: retryPolicy,
         retryBudget: retryBudget,
         breakerFactory: breakerFactory,
         now: now,
         random: random,
         sleep: sleep,
         uuid: uuid,
       ) {
    api = FynonaApi(dio);
  }

  /// The core transport under this client.
  final HttpTransport http;

  /// The underlying HTTP client; its adapter is the resilient one.
  Dio get dio => http.dio;

  /// Generated endpoint clients.
  late final FynonaApi api;

  /// Runs [request] and turns transport failures into [ApiException]s.
  Future<T> call<T>(Future<T> Function(FynonaApi api) request) =>
      http.call(() => request(api));

  /// Whether a circuit breaker is not closed: the UI shows «no connection».
  bool get isOffline => http.isOffline;

  /// Emits [isOffline] whenever it changes.
  Stream<bool> get offlineChanges => http.offlineChanges;

  /// Every `426 api_version_unsupported` the server answers, on any route:
  /// this client is outdated (API-12).
  Stream<UpgradeRequiredException> get contractRejections =>
      http.contractRejections;

  /// Every `402 entitlement.exceeded` the server answers, on any route: the
  /// app offers a plan (MON-4).
  Stream<EntitlementExceededException> get entitlementRejections =>
      http.problems.whereType<EntitlementExceededException>();

  /// Reads `GET /v1/meta` and decides whether this client's contract version
  /// works with the server (API-12), by the core's [checkContract] rules.
  Future<ContractCompatibility> checkContract() => http.checkContract(() async {
    final meta = await api.meta.getMeta();
    return (server: meta.contractVersion, minimum: meta.minContractVersion);
  });

  void close() => http.close();
}

extension<T> on Stream<T> {
  Stream<S> whereType<S>() => where((event) => event is S).cast<S>();
}
