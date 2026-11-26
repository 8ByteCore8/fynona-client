import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fynona_api/fynona_api.dart';

/// One request as the fake adapter saw it.
final class SeenRequest {
  SeenRequest(this.method, this.path, this.headers, this.body);

  final String method;
  final String path;
  final Map<String, Object?> headers;
  final String? body;
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

const metaJson = <String, Object?>{
  'server_version': '0.1.0',
  'api_version': 'v1',
  'environment': 'sandbox',
  'min_client_versions': {'android': '1.0.0'},
  'features': {'demo': true},
  'update_url': 'https://fynona.app/download',
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

/// A transport over [adapter] with a fake clock, a fixed random and recorded
/// sleeps instead of real waiting.
({ApiTransport transport, List<Duration> sleeps, FakeClock clock})
fakeTransport(
  FakeAdapter adapter, {
  RetryBudget? budget,
  CircuitBreaker Function(void Function(CircuitState))? breakerFactory,
  FakeClock? clock,
  double random = 0.5,
}) {
  final fakeClock = clock ?? FakeClock();
  final sleeps = <Duration>[];
  final transport = ApiTransport(
    baseUrl: 'https://api.test',
    clientVersion: '1.2.3',
    platform: 'linux',
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
