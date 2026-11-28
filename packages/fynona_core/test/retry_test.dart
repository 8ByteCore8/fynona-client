import 'package:fynona_core/fynona_core.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  group('RetryPolicy (API-60, API-61)', () {
    const policy = RetryPolicy();

    test('retries only GET and requests with an Idempotency-Key', () {
      expect(policy.isRetryableRequest('GET', {}), isTrue);
      expect(policy.isRetryableRequest('POST', {}), isFalse);
      expect(policy.isRetryableRequest('HEAD', {}), isFalse);
      expect(
        policy.isRetryableRequest('POST', {'Idempotency-Key': 'k'}),
        isTrue,
      );
    });

    test('retryable statuses are 408, 429, 502, 503, 504', () {
      final retryable = [
        for (var code = 100; code < 600; code++)
          if (policy.isRetryableStatus(code)) code,
      ];
      expect(retryable, [408, 429, 502, 503, 504]);
    });

    test('full jitter: random(0, min(cap, 200 ms × 2^retry))', () {
      Duration at(int retry, double random) =>
          policy.delay(retry, FixedRandom(random));
      expect(at(0, 0.5), const Duration(milliseconds: 100));
      expect(at(1, 0.5), const Duration(milliseconds: 200));
      expect(at(2, 0.5), const Duration(milliseconds: 400));
      expect(at(0, 0), Duration.zero);
      expect(at(10, 0.5), const Duration(seconds: 5));
      expect(at(30, 0.999), lessThan(const Duration(seconds: 10)));
    });

    test('Retry-After wins over the computed delay', () {
      expect(
        policy.delay(0, FixedRandom(0.5), retryAfter: '7'),
        const Duration(seconds: 7),
      );
      expect(
        policy.delay(0, FixedRandom(0.5), retryAfter: 'soon'),
        const Duration(milliseconds: 100),
      );
    });
  });

  group('transport retries', () {
    test('GET: retries 503 and succeeds, with jittered sleeps', () async {
      final adapter = FakeAdapter([
        status(503),
        status(503),
        status(200, json: metaWith()),
      ]);
      final t = fakeTransport(adapter);
      final meta = await getFrom(t.transport);
      expect(meta.statusCode, 200);
      expect(adapter.requests, hasLength(3));
      expect(t.sleeps, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 200),
      ]);
    });

    for (final code in [408, 429, 502, 503, 504]) {
      test('GET: $code is retried', () async {
        final adapter = FakeAdapter([
          status(code),
          status(200, json: metaWith()),
        ]);
        await getFrom(fakeTransport(adapter).transport);
        expect(adapter.requests, hasLength(2));
      });
    }

    for (final code in [400, 404, 422, 500]) {
      test('GET: $code is not retried', () async {
        final adapter = FakeAdapter([status(code)]);
        await expectLater(
          getFrom(fakeTransport(adapter).transport),
          throwsA(isA<ApiHttpException>()),
        );
        expect(adapter.requests, hasLength(1));
      });
    }

    test('network errors are retried', () async {
      final adapter = FakeAdapter([
        networkError(),
        status(200, json: metaWith()),
      ]);
      await getFrom(fakeTransport(adapter).transport);
      expect(adapter.requests, hasLength(2));
    });

    test('at most 3 retries, then the last error', () async {
      final adapter = FakeAdapter([networkError()]);
      final t = fakeTransport(adapter);
      await expectLater(
        getFrom(t.transport),
        throwsA(isA<ApiNetworkException>()),
      );
      expect(adapter.requests, hasLength(4));
      expect(t.sleeps, hasLength(3));
    });

    test('Retry-After from a 429 is the wait', () async {
      final adapter = FakeAdapter([
        status(429, headers: {'Retry-After': '3'}),
        status(200, json: metaWith()),
      ]);
      final t = fakeTransport(adapter);
      await getFrom(t.transport);
      expect(t.sleeps, [const Duration(seconds: 3)]);
    });

    test(
      'a request without Idempotency-Key and not GET is not retried',
      () async {
        final adapter = FakeAdapter([status(503)]);
        final t = fakeTransport(adapter);
        await expectLater(
          t.transport.call(() => t.transport.dio.head<void>(metaPath)),
          throwsA(isA<ApiHttpException>()),
        );
        expect(adapter.requests, hasLength(1));
      },
    );

    test('POST is retried with the same Idempotency-Key and body', () async {
      final adapter = FakeAdapter([
        status(503),
        networkError(),
        status(201, json: {}),
      ]);
      final t = fakeTransport(adapter);
      await t.transport.dio.post<void>('/x/things', data: {'name': 'x'});
      expect(adapter.requests, hasLength(3));
      final keys = adapter.requests.map((r) => r.headers['Idempotency-Key']);
      expect(keys.toSet(), hasLength(1));
      expect(keys.first, matches(uuidV7));
      expect(adapter.requests.map((r) => r.body).toSet(), {'{"name":"x"}'});
    });
  });

  group('RetryBudget (API-62)', () {
    test('retries stay within 10 % of primaries in the window', () {
      final clock = FakeClock();
      final budget = RetryBudget(now: clock.now);
      for (var i = 0; i < 100; i++) {
        budget.recordPrimary();
      }
      var granted = 0;
      while (budget.tryRetry()) {
        granted++;
      }
      expect(granted, 10);
    });

    test('a small minimum reserve covers quiet periods', () {
      final budget = RetryBudget(now: FakeClock().now);
      budget.recordPrimary();
      expect(
        [for (var i = 0; i < 5; i++) budget.tryRetry()],
        [true, true, true, false, false],
      );
    });

    test('the window slides', () {
      final clock = FakeClock();
      final budget = RetryBudget(now: clock.now);
      while (budget.tryRetry()) {}
      expect(budget.tryRetry(), isFalse);
      clock.advance(const Duration(seconds: 61));
      expect(budget.tryRetry(), isTrue);
    });

    test('primaries stay bounded by the window without any retry', () {
      final clock = FakeClock();
      final budget = RetryBudget(now: clock.now);
      for (var i = 0; i < 10000; i++) {
        budget.recordPrimary();
        clock.advance(const Duration(seconds: 1));
      }
      expect(budget.primaryCount, 60);
    });

    test('healthy transport traffic keeps the budget bounded', () async {
      final clock = FakeClock();
      final budget = RetryBudget(now: clock.now);
      final adapter = FakeAdapter([status(200, json: metaWith())]);
      final t = fakeTransport(adapter, budget: budget, clock: clock);
      for (var i = 0; i < 300; i++) {
        await getFrom(t.transport);
        clock.advance(const Duration(seconds: 1));
      }
      expect(adapter.requests, hasLength(300));
      expect(budget.primaryCount, 60);
    });

    test('exhausted budget returns the error at once', () async {
      final clock = FakeClock();
      final budget = RetryBudget(now: clock.now, minRetries: 0);
      final adapter = FakeAdapter([status(503)]);
      final t = fakeTransport(adapter, budget: budget, clock: clock);
      await expectLater(getFrom(t.transport), throwsA(isA<ApiHttpException>()));
      expect(adapter.requests, hasLength(1));
      expect(t.sleeps, isEmpty);
    });
  });
}

final uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
