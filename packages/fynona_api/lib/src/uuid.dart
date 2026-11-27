import 'dart:math';

/// Generates RFC 9562 UUIDv7 strings for `X-Request-ID` and `Idempotency-Key`
/// (API-20, API-21): a 48-bit Unix millisecond timestamp, then random bits.
final class UuidV7 {
  UuidV7({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _now;
  final Random _random;

  /// A new UUIDv7 in the canonical lowercase 8-4-4-4-12 form.
  String next() {
    final millis = _now().toUtc().millisecondsSinceEpoch;
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    for (var i = 0; i < 6; i++) {
      bytes[i] = (millis >> (8 * (5 - i))) & 0xff;
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f);
    bytes[8] = 0x80 | (bytes[8] & 0x3f);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
