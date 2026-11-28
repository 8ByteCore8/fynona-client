import 'dart:collection';
import 'dart:math';

/// Which requests are retried and how long to wait (API-60, API-61).
final class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 10),
  });

  /// At most this many retries per request.
  final int maxRetries;

  /// `base` of the exponential backoff.
  final Duration baseDelay;

  /// `cap` of the exponential backoff.
  final Duration maxDelay;

  /// Responses worth another attempt; network errors are retried as well.
  static const retryableStatuses = {408, 429, 502, 503, 504};

  /// Only `GET` and requests carrying an `Idempotency-Key` are retried.
  bool isRetryableRequest(String method, Map<String, Object?> headers) =>
      method.toUpperCase() == 'GET' ||
      headers.keys.any((name) => name.toLowerCase() == idempotencyKeyHeader);

  bool isRetryableStatus(int status) => retryableStatuses.contains(status);

  /// Delay before retry number [retry] (0 for the first retry).
  ///
  /// A valid `Retry-After` in seconds wins; otherwise full jitter:
  /// `random(0, min(cap, base × 2^retry))`.
  Duration delay(int retry, Random random, {String? retryAfter}) {
    final seconds = retryAfter == null ? null : int.tryParse(retryAfter.trim());
    if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
    final ceiling = min(
      maxDelay.inMicroseconds,
      baseDelay.inMicroseconds * pow(2, retry).toInt(),
    );
    return Duration(microseconds: (random.nextDouble() * ceiling).floor());
  }
}

/// Header name of the idempotency key, lowercase (API-20).
const idempotencyKeyHeader = 'idempotency-key';

/// Retry budget (API-62): retries stay within [ratio] of the primary requests
/// seen in a sliding [window], with a reserve of [minRetries] for quiet periods.
final class RetryBudget {
  RetryBudget({
    this.ratio = 0.1,
    this.minRetries = 3,
    this.window = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final double ratio;
  final int minRetries;
  final Duration window;
  final DateTime Function() _now;

  final _primaries = Queue<DateTime>();
  final _retries = Queue<DateTime>();

  /// First attempts currently held inside the [window].
  int get primaryCount => _primaries.length;

  /// Counts a first attempt; entries older than the [window] are dropped.
  void recordPrimary() {
    final now = _now();
    _evict(now);
    _primaries.addLast(now);
  }

  /// Takes one retry from the budget; false when it is exhausted.
  bool tryRetry() {
    final now = _now();
    _evict(now);
    final allowed = max(minRetries, (_primaries.length * ratio).floor());
    if (_retries.length >= allowed) return false;
    _retries.addLast(now);
    return true;
  }

  void _evict(DateTime now) {
    final cutoff = now.subtract(window);
    _evictBefore(_primaries, cutoff);
    _evictBefore(_retries, cutoff);
  }

  /// Entries are appended in time order, so the oldest sit at the front.
  static void _evictBefore(Queue<DateTime> times, DateTime cutoff) {
    while (times.isNotEmpty && !times.first.isAfter(cutoff)) {
      times.removeFirst();
    }
  }
}
