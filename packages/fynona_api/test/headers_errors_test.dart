import 'package:dio/dio.dart';
import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

import 'retry_test.dart' show uuidV7;
import 'support/fakes.dart';

void main() {
  group('headers (API-12, API-20, API-21)', () {
    test(
      'every request carries X-Request-ID (UUIDv7) and User-Agent',
      () async {
        final adapter = FakeAdapter([status(200, json: metaJson)]);
        final t = fakeTransport(adapter);
        await t.transport.call((a) => a.meta.getMeta());
        await t.transport.call((a) => a.meta.getMeta());
        final ids = adapter.requests.map((r) => r.headers['X-Request-ID']);
        expect(ids, everyElement(matches(uuidV7)));
        expect(ids.toSet(), hasLength(2));
        expect(
          adapter.requests.map((r) => r.headers['User-Agent']),
          everyElement('Fynona/1.2.3 (linux)'),
        );
        expect(
          adapter.requests.first.headers,
          isNot(contains('Idempotency-Key')),
        );
      },
    );

    test('every request declares X-Fynona-API, unchanged on retries', () async {
      final adapter = FakeAdapter([
        status(503),
        networkError(),
        status(200, json: metaJson),
      ]);
      final t = fakeTransport(adapter);
      await t.transport.call((a) => a.meta.getMeta());
      await t.transport.dio.post<void>('/v1/things');
      expect(adapter.requests, hasLength(4));
      expect(
        adapter.requests.map((r) => r.headers['X-Fynona-API']),
        everyElement(contractVersion),
      );
      expect(
        adapter.requests.map((r) => r.headers['User-Agent']),
        everyElement('Fynona/1.2.3 (linux)'),
      );
    });

    test('a request may declare another contract version', () async {
      final adapter = FakeAdapter([status(200, json: metaJson)]);
      final t = fakeTransport(adapter);
      await t.transport.call((a) => a.meta.getMeta(xFynonaApi: '2.0.0'));
      expect(adapter.requests.single.headers['X-Fynona-API'], '2.0.0');
    });

    test('UUIDv7 starts with the millisecond timestamp', () {
      final id = UuidV7(now: () => DateTime.utc(2026, 11, 27)).next();
      expect(id, matches(uuidV7));
      final millis = int.parse(
        id.replaceAll('-', '').substring(0, 12),
        radix: 16,
      );
      expect(millis, DateTime.utc(2026, 11, 27).millisecondsSinceEpoch);
    });

    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      test('$method carries an Idempotency-Key (UUIDv7)', () async {
        final adapter = FakeAdapter([status(200, json: {})]);
        final t = fakeTransport(adapter);
        await t.transport.dio.request<void>(
          '/v1/things',
          options: Options(method: method),
        );
        expect(
          adapter.requests.single.headers['Idempotency-Key'],
          matches(uuidV7),
        );
      });
    }

    test('a caller-provided Idempotency-Key is kept', () async {
      final adapter = FakeAdapter([status(503), status(200, json: {})]);
      final t = fakeTransport(adapter);
      await t.transport.dio.post<void>(
        '/v1/things',
        options: Options(headers: {'Idempotency-Key': 'caller-key'}),
      );
      expect(adapter.requests.map((r) => r.headers['Idempotency-Key']), [
        'caller-key',
        'caller-key',
      ]);
    });
  });

  group('typed errors (API-12, API-30)', () {
    test(
      'problem+json becomes ApiProblemException with code and request_id',
      () async {
        final adapter = FakeAdapter([
          status(
            400,
            json: problemJson(400, 'request.invalid'),
            contentType: 'application/problem+json',
          ),
        ]);
        await expectLater(
          fakeTransport(adapter).transport.call((a) => a.meta.getMeta()),
          throwsA(
            isA<ApiProblemException>()
                .having((e) => e.code, 'code', 'request.invalid')
                .having((e) => e.requestId, 'requestId', 'req-400')
                .having((e) => e.status, 'status', 400),
          ),
        );
      },
    );

    test('426 becomes UpgradeRequiredException with the link', () async {
      final adapter = FakeAdapter([
        status(
          426,
          json: problemJson(426, 'api_version_unsupported'),
          contentType: 'application/problem+json; charset=utf-8',
        ),
      ]);
      await expectLater(
        fakeTransport(adapter).transport.call((a) => a.meta.getMeta()),
        throwsA(
          isA<UpgradeRequiredException>()
              .having(
                (e) => e.updateUrl,
                'updateUrl',
                'https://fynona.app/download',
              )
              .having((e) => e.code, 'code', 'api_version_unsupported'),
        ),
      );
    });

    test(
      'an error without a problem body keeps the status and request id',
      () async {
        final adapter = FakeAdapter([
          status(
            404,
            contentType: 'text/plain',
            headers: {'X-Request-ID': 'r-1'},
          ),
        ]);
        await expectLater(
          fakeTransport(adapter).transport.call((a) => a.meta.getMeta()),
          throwsA(
            isA<ApiHttpException>()
                .having((e) => e.status, 'status', 404)
                .having((e) => e.requestId, 'requestId', 'r-1'),
          ),
        );
      },
    );
  });

  test('timeouts: connect 10 s, read 30 s (API-64)', () {
    final options = fakeTransport(FakeAdapter([])).transport.dio.options;
    expect(options.connectTimeout, const Duration(seconds: 10));
    expect(options.receiveTimeout, const Duration(seconds: 30));
  });
}
