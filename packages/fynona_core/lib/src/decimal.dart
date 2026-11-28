/// Decimal numbers as they travel on the wire (API-5, DOM-11, ADR-002).
library;

final _wirePattern = RegExp(r'^-?[0-9]+(\.[0-9]+)?$');

/// A decimal amount, quantity, rate or price that keeps its wire string.
///
/// The value is never converted to a binary floating point number: the
/// string the server sent, including its scale (`"-100.00"` has scale 2), is
/// what [toString] and [toJson] return. Exponents, JSON numbers and blanks are
/// rejected.
final class WireDecimal implements Comparable<WireDecimal> {
  WireDecimal._(this._wire);

  /// Parses a wire string such as `"-100.00"`.
  ///
  /// Throws a [FormatException] for anything that is not a plain decimal:
  /// exponents (`"1e5"`), a leading `+`, spaces or a bare `"."`.
  factory WireDecimal.parse(String wire) {
    if (!_wirePattern.hasMatch(wire)) {
      throw FormatException('Not a decimal wire string', wire);
    }
    return WireDecimal._(wire);
  }

  /// Decodes a JSON value; only strings are accepted (API-5).
  factory WireDecimal.fromJson(Object? json) {
    if (json is! String) {
      throw FormatException('A decimal must be a JSON string', json);
    }
    return WireDecimal.parse(json);
  }

  final String _wire;

  /// Digits after the decimal point.
  int get scale {
    final point = _wire.indexOf('.');
    return point < 0 ? 0 : _wire.length - point - 1;
  }

  /// The value without its decimal point: `"-100.00"` is `-10000`.
  BigInt get unscaledValue => BigInt.parse(_wire.replaceFirst('.', ''));

  /// Whether the value is below zero; `"-0.00"` is not.
  bool get isNegative => unscaledValue.isNegative;

  /// The wire string, byte for byte as parsed.
  String toJson() => _wire;

  @override
  String toString() => _wire;

  /// Numeric order, independent of scale: `"1.0"` equals `"1.00"` here.
  @override
  int compareTo(WireDecimal other) {
    final shift = scale - other.scale;
    final a = shift < 0
        ? unscaledValue * BigInt.from(10).pow(-shift)
        : unscaledValue;
    final b = shift > 0
        ? other.unscaledValue * BigInt.from(10).pow(shift)
        : other.unscaledValue;
    return a.compareTo(b);
  }

  /// Wire equality: `"1.0"` and `"1.00"` carry different scales and differ.
  @override
  bool operator ==(Object other) =>
      other is WireDecimal && other._wire == _wire;

  @override
  int get hashCode => _wire.hashCode;
}

/// Codec used by the generated models (swagger_parser `type_mappings`).
WireDecimal wireDecimalFromJson(Object? json) => WireDecimal.fromJson(json);

/// Codec used by the generated models (swagger_parser `type_mappings`).
String wireDecimalToJson(WireDecimal value) => value.toJson();
