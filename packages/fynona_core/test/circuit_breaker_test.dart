import 'package:fynona_core/fynona_core.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  group('CircuitBreaker (API-63)', () {
    late FakeClock clock;
    late CircuitBreaker breaker;
    late List<CircuitState> changes;

    setUp(() {
      clock = FakeClock();
      changes = [];
      breaker = CircuitBreaker(now: clock.now, onStateChange: changes.add);
    });

    void outcomes(int failures, int successes) {
      for (var i = 0; i < successes; i++) {
        breaker.record(success: true);
      }
      for (var i = 0; i < failures; i++) {
        breaker.record(success: false);
      }
    }

    test('stays closed below the minimum volume', () {
      outcomes(9, 0);
      expect(breaker.state, CircuitState.closed);
    });

    test('stays closed at or below the error ratio', () {
      outcomes(5, 5);
      expect(breaker.state, CircuitState.closed);
    });

    test('opens above the error ratio over the minimum volume', () {
      outcomes(6, 4);
      expect(breaker.state, CircuitState.open);
      expect(breaker.tryAcquire(), isFalse);
    });

    test('outcomes outside the window do not count', () {
      outcomes(9, 0);
      clock.advance(const Duration(seconds: 31));
      outcomes(1, 0);
      expect(breaker.state, CircuitState.closed);
    });

    test('half-open after the pause admits exactly one probe', () {
      outcomes(10, 0);
      clock.advance(const Duration(seconds: 14));
      expect(breaker.tryAcquire(), isFalse);
      clock.advance(const Duration(seconds: 1));
      expect(breaker.tryAcquire(), isTrue);
      expect(breaker.state, CircuitState.halfOpen);
      expect(breaker.tryAcquire(), isFalse);
    });

    test('a successful probe closes it', () {
      outcomes(10, 0);
      clock.advance(const Duration(seconds: 15));
      breaker.tryAcquire();
      breaker.record(success: true);
      expect(breaker.state, CircuitState.closed);
      expect(changes, [
        CircuitState.open,
        CircuitState.halfOpen,
        CircuitState.closed,
      ]);
    });

    test('a failed probe opens it again for another pause', () {
      outcomes(10, 0);
      clock.advance(const Duration(seconds: 15));
      breaker.tryAcquire();
      breaker.record(success: false);
      expect(breaker.state, CircuitState.open);
      expect(breaker.tryAcquire(), isFalse);
    });
  });

  group('transport with an open breaker', () {
    test('fails fast with CircuitOpenException and reports offline', () async {
      final adapter = FakeAdapter([networkError()]);
      final t = fakeTransport(adapter);
      final offline = <bool>[];
      t.transport.offlineChanges.listen(offline.add);
      expect(t.transport.isOffline, isFalse);

      await tripMetaBreaker(t.transport);
      expect(t.transport.isOffline, isTrue);
      final sent = adapter.requests.length;

      await expectLater(
        getFrom(t.transport),
        throwsA(
          isA<CircuitOpenException>().having((e) => e.group, 'group', 'x/meta'),
        ),
      );
      expect(adapter.requests, hasLength(sent));
      await Future<void>.delayed(Duration.zero);
      expect(offline, [true]);
    });

    test('groups are independent; recovery closes the breaker', () async {
      var down = true;
      final adapter = FakeAdapter([
        (request) => down || request.path == metaPath
            ? networkError()(request)
            : status(200, json: metaWith())(request),
      ]);
      final t = fakeTransport(adapter);
      await tripMetaBreaker(t.transport);
      down = false;
      await getFrom(t.transport, '/x/other');

      final breaker = (t.transport.dio.httpClientAdapter as ResilientAdapter)
          .breakerFor('x/meta');
      expect(breaker.state, CircuitState.open);
      t.clock.advance(const Duration(seconds: 15));
      // The probe still fails: open again, no retries spent on it.
      final before = adapter.requests.length;
      await expectLater(
        getFrom(t.transport),
        throwsA(isA<ApiNetworkException>()),
      );
      expect(adapter.requests.length - before, 1);
      expect(breaker.state, CircuitState.open);
    });

    test('a successful probe brings the transport back online', () async {
      var down = true;
      final adapter = FakeAdapter([
        (request) => down
            ? networkError()(request)
            : status(200, json: metaWith())(request),
      ]);
      final t = fakeTransport(adapter);
      await tripMetaBreaker(t.transport);
      expect(t.transport.isOffline, isTrue);
      down = false;
      t.clock.advance(const Duration(seconds: 15));
      await getFrom(t.transport);
      expect(t.transport.isOffline, isFalse);
    });
  });
}

/// Fails `GET /x/meta` until its breaker opens: the first call spends the
/// three reserve retries, then the budget is empty, so 7 calls make the 10
/// failures of the minimum volume.
Future<void> tripMetaBreaker(HttpTransport transport) async {
  var calls = 0;
  while (!transport.isOffline) {
    await expectLater(getFrom(transport), throwsA(isA<ApiNetworkException>()));
    calls++;
  }
  expect(calls, 7);
}
