import 'package:dio/dio.dart';
import 'package:fynona_core/fynona_core.dart';
import 'package:test/test.dart';

import 'retry_test.dart' show uuidV7;
import 'support/fakes.dart';

void main() {
  group('headers (API-12, API-20, API-21)', () {
    test(
      'every request carries X-Request-ID (UUIDv7) and User-Agent',
      () async {
        final adapter = FakeAdapter([status(200, json: metaWith())]);
        final t = fakeTransport(adapter);
        await getFrom(t.transport);
        await getFrom(t.transport);
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
        status(200, json: metaWith()),
      ]);
      final t = fakeTransport(adapter);
      await getFrom(t.transport);
      await t.transport.dio.post<void>('/x/things');
      expect(adapter.requests, hasLength(4));
      expect(
        adapter.requests.map((r) => r.headers['X-Fynona-API']),
        everyElement(declaredVersion),
      );
      expect(
        adapter.requests.map((r) => r.headers['User-Agent']),
        everyElement('Fynona/1.2.3 (linux)'),
      );
    });

    test('a request may declare another contract version', () async {
      final adapter = FakeAdapter([status(200, json: metaWith())]);
      final t = fakeTransport(adapter);
      await t.transport.dio.get<void>(
        metaPath,
        options: Options(headers: {'X-Fynona-API': '2.0.0'}),
      );
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
          '/x/things',
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
        '/x/things',
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
          getFrom(fakeTransport(adapter).transport),
          throwsA(
            isA<ApiProblemException>()
                .having((e) => e.code, 'code', 'request.invalid')
                .having((e) => e.requestId, 'requestId', 'req-400')
                .having((e) => e.status, 'status', 400),
          ),
        );
      },
    );

    test('a Retry-After in seconds travels with the error', () async {
      final adapter = FakeAdapter([
        status(
          400,
          json: problemJson(400, 'request.invalid'),
          contentType: 'application/problem+json',
          headers: {'Retry-After': '7'},
        ),
        status(404, contentType: 'text/plain', headers: {'Retry-After': 'x'}),
      ]);
      final transport = fakeTransport(adapter).transport;
      await expectLater(
        getFrom(transport),
        throwsA(
          isA<ApiProblemException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        ),
      );
      await expectLater(
        getFrom(transport),
        throwsA(
          isA<ApiHttpException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            isNull,
          ),
        ),
      );
    });

    test('426 becomes UpgradeRequiredException with the link', () async {
      final adapter = FakeAdapter([
        status(
          426,
          json: problemJson(426, 'api_version_unsupported'),
          contentType: 'application/problem+json; charset=utf-8',
        ),
      ]);
      await expectLater(
        getFrom(fakeTransport(adapter).transport),
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
          getFrom(fakeTransport(adapter).transport),
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

  group('idempotency exemption of the consumer (API-20)', () {
    test('a request the consumer marks exempt goes without Idempotency-Key and '
        'is not retried on 503', () async {
      final adapter = FakeAdapter([status(503)]);
      final t = fakeTransport(adapter);
      await expectLater(
        t.transport.call(
          () => t.transport.dio.post<void>('/x/v9/auth/login', data: {}),
        ),
        throwsA(isA<ApiHttpException>().having((e) => e.status, '', 503)),
      );
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('idempotency-key')),
      );
      expect(t.sleeps, isEmpty);
    });

    test('the rule gets the method and the full URI', () async {
      final seen = <(String, String)>[];
      final adapter = FakeAdapter([status(204)]);
      final t = fakeTransport(
        adapter,
        idempotencyExempt: (method, uri) {
          seen.add((method, uri.path));
          return method == 'DELETE';
        },
      );
      await t.transport.dio.delete<void>('/x/me');
      await t.transport.dio.put<void>('/x/me');
      await t.transport.dio.get<void>('/x/me');
      expect(seen, [('DELETE', '/x/me'), ('PUT', '/x/me')]);
      expect(adapter.requests.map((r) => r.headers['Idempotency-Key']), [
        isNull,
        matches(uuidV7),
        isNull,
      ]);
    });
  });

  group('problems (API-30)', () {
    test('ProblemDetails keeps errors, update_url and other members', () {
      final problem = ProblemDetails.fromJson({
        ...problemJson(426, 'api_version_unsupported'),
        'detail': 'too old',
        'errors': [
          {'field': '/email', 'code': 'format', 'detail': 'not an email'},
        ],
        'limit': 'x.max',
      });
      expect(problem.detail, 'too old');
      expect(problem.updateUrl, 'https://fynona.app/download');
      expect(problem.errors!.single.field, '/email');
      expect(problem.extensions, {'limit': 'x.max'});
    });

    test('a malformed problem body is a bare HTTP error', () async {
      final adapter = FakeAdapter([
        status(
          400,
          json: {'title': 'no code', 'status': 400},
          contentType: 'application/problem+json',
        ),
      ]);
      await expectLater(
        getFrom(fakeTransport(adapter).transport),
        throwsA(isA<ApiHttpException>().having((e) => e.status, '', 400)),
      );
    });

    test(
      'every problem reaches the stream; the consumer may type it',
      () async {
        final adapter = FakeAdapter([
          status(
            402,
            json: problemJson(402, 'limit.exceeded'),
            contentType: 'application/problem+json',
          ),
        ]);
        final t = fakeTransport(
          adapter,
          classifyProblem: (status, problem, retryAfter) =>
              status == 402 ? _LimitException(problem) : null,
        );
        final next = t.transport.problems.first;
        await expectLater(
          getFrom(t.transport),
          throwsA(isA<_LimitException>()),
        );
        expect((await next).code, 'limit.exceeded');
      },
    );
  });
}

final class _LimitException extends ApiProblemException {
  const _LimitException(super.problem);
}
