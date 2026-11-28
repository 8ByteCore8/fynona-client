import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fynona_core/fynona_core.dart';

/// One request as the fake adapter saw it.
final class SeenRequest {
  SeenRequest(
    this.method,
    this.path,
    this.headers,
    this.body, {
    this.extra = const {},
  });

  final String method;
  final String path;
  final Map<String, Object?> headers;
  final String? body;

  /// Request extras, e.g. `withCredentials` for the browser adapter.
  final Map<String, Object?> extra;
}

typedef Responder = ResponseBody Function(SeenRequest request);

/// An [HttpClientAdapter] that answers from a queue and records requests.
/// When the queue runs dry the last responder keeps answering.
final class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.responders);

  final List<Responder> responders;
  final requests = <SeenRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = requestStream == null
        ? null
        : utf8.decode(await requestStream.expand((chunk) => chunk).toList());
    final request = SeenRequest(
      options.method,
      options.uri.path,
      Map.of(options.headers),
      body,
      extra: Map.of(options.extra),
    );
    requests.add(request);
    final index = min(requests.length - 1, responders.length - 1);
    return responders[index](request);
  }

  @override
  void close({bool force = false}) {}
}

Responder status(
  int code, {
  Map<String, Object?>? json,
  String contentType = 'application/json',
  Map<String, String> headers = const {},
}) =>
    (_) => ResponseBody.fromString(
      json == null ? '' : jsonEncode(json),
      code,
      headers: {
        Headers.contentTypeHeader: [contentType],
        for (final entry in headers.entries) entry.key: [entry.value],
      },
    );

Responder networkError() =>
    (request) => throw DioException.connectionError(
      requestOptions: RequestOptions(path: request.path),
      reason: 'fake connection refused',
    );

/// The contract version the fake transports declare.
const declaredVersion = '1.4.0';

/// A fictitious meta route; the core knows no API path.
const metaPath = '/x/meta';

/// A meta answer serving contract [server] with minimum [minimum].
Map<String, Object?> metaWith({
  String server = declaredVersion,
  String? minimum,
}) => {
  'contract_version': server,
  'min_contract_version': minimum ?? '${server.split('.').first}.0.0',
};

Map<String, Object?> problemJson(int status, String code) => {
  'type': 'urn:fynona:problem:$code',
  'title': 'Problem',
  'status': status,
  'code': code,
  'request_id': 'req-$status',
  if (status == 426) 'update_url': 'https://fynona.app/download',
};

/// A clock that only moves when told to.
final class FakeClock {
  DateTime current = DateTime.utc(2026, 11, 27, 12);

  DateTime now() => current;

  void advance(Duration by) => current = current.add(by);
}

/// [Random] whose [nextDouble] always returns [value].
final class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

/// Exempts every mutating request under `/x/v9/auth/` from the key.
bool exemptAuth(String method, Uri uri) => uri.path.startsWith('/x/v9/auth/');

/// A transport over [adapter] with a fake clock, a fixed random and recorded
/// sleeps instead of real waiting.
({HttpTransport transport, List<Duration> sleeps, FakeClock clock})
fakeTransport(
  FakeAdapter adapter, {
  RetryBudget? budget,
  CircuitBreaker Function(void Function(CircuitState))? breakerFactory,
  FakeClock? clock,
  double random = 0.5,
  String declaredContractVersion = declaredVersion,
  IdempotencyExemption idempotencyExempt = exemptAuth,
  ProblemClassifier? classifyProblem,
}) {
  final fakeClock = clock ?? FakeClock();
  final sleeps = <Duration>[];
  final transport = HttpTransport(
    baseUrl: 'https://api.test',
    clientVersion: '1.2.3',
    platform: 'linux',
    declaredContractVersion: declaredContractVersion,
    idempotencyExempt: idempotencyExempt,
    classifyProblem: classifyProblem,
    adapter: adapter,
    retryBudget: budget ?? RetryBudget(now: fakeClock.now),
    breakerFactory: breakerFactory,
    now: fakeClock.now,
    random: FixedRandom(random),
    sleep: (delay) async {
      sleeps.add(delay);
      fakeClock.advance(delay);
    },
  );
  return (transport: transport, sleeps: sleeps, clock: fakeClock);
}

/// `GET` [path] through [transport], typed errors included.
Future<Response<Object?>> getFrom(
  HttpTransport transport, [
  String path = metaPath,
]) => transport.call(() => transport.dio.get<Object?>(path));
