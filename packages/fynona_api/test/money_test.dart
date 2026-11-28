import 'dart:convert';
import 'dart:io';

import 'package:fynona_api/fynona_api.dart';
import 'package:test/test.dart';

// WireDecimal itself is tested in fynona_core (test/money_test.dart).
void main() {
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
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
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
