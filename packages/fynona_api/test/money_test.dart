import 'dart:convert';
import 'dart:io';

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

void main() {
  group('WireDecimal (API-5, ADR-002)', () {
    test('"-100.00" parses and re-serializes byte-identically', () {
      final value = WireDecimal.parse('-100.00');
      expect(value.toString(), '-100.00');
      expect(value.toJson(), '-100.00');
      expect(value.scale, 2);
      expect(value.unscaledValue, BigInt.from(-10000));
      expect(value.isNegative, isTrue);
    });

    test('keeps precision beyond binary floating point', () {
      const wire = '123456789012345678901234567890.000000000000000001';
      expect(WireDecimal.parse(wire).toJson(), wire);
      expect(WireDecimal.parse('0.10').scale, 2);
    });

    test('rejects exponents, JSON numbers and other non-decimals', () {
      for (final bad in ['1e5', '+1', ' 1', '1.', '.5', '', '1,5', 'NaN']) {
        expect(
          () => WireDecimal.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
      expect(() => WireDecimal.fromJson(100), throwsFormatException);
      expect(() => WireDecimal.fromJson(-100.0), throwsFormatException);
    });

    test('equality keeps the scale, order compares the value', () {
      final a = WireDecimal.parse('1.0');
      final b = WireDecimal.parse('1.00');
      expect(a == b, isFalse);
      expect(a.compareTo(b), 0);
      expect(WireDecimal.parse('-0.01').compareTo(WireDecimal.parse('0')), -1);
    });
  });

  group('Money (generated)', () {
    test('round-trips its JSON byte for byte', () {
      const wire = '{"amount":"-100.00","currency":"UAH"}';
      final money = Money.fromJson(jsonDecode(wire) as Map<String, Object?>);
      expect(money.amount.scale, 2);
      expect(jsonEncode(money.toJson()), wire);
    });

    test('rejects a JSON number amount', () {
      expect(
        () => Money.fromJson({'amount': -100, 'currency': 'UAH'}),
        throwsA(anything),
      );
    });
  });

  test('no double or num in money code, generated or hand-written', () {
    final files = [
      ...Directory('lib/src/gen')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('lib/src/decimal.dart'),
    ];
    expect(files.length, greaterThan(5));
    final floating = RegExp(r'\b(double|num)\b');
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        expect(
          floating.hasMatch(code),
          isFalse,
          reason: '${file.path}:${i + 1}: ${lines[i]}',
        );
      }
    }
  });
}
