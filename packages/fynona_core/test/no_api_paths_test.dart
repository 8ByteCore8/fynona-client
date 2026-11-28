import 'dart:io';

import 'package:test/test.dart';

/// Path prefixes of the real Fynona APIs, built in pieces so this file does
/// not hold them itself.
final _apiPrefixes = [
  '/v'
      '1/',
  '/adm'
      'in/',
];

/// Every text file of the package except build output.
List<File> _sources() => Directory('.')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => !f.path.contains('/.dart_tool/'))
    .where((f) => !f.path.contains('/build/'))
    .where(
      (f) => const ['.dart', '.yaml', '.md'].any((ext) => f.path.endsWith(ext)),
    )
    .toList();

/// Lines of [source] that name an API path.
List<String> apiPathLines(String path, String source) {
  final lines = source.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      if (_apiPrefixes.any(lines[i].contains)) '$path:${i + 1}: ${lines[i]}',
  ];
}

void main() {
  test('the core names no API path: it knows no particular API', () {
    final files = _sources();
    expect(files.length, greaterThan(10));
    final problems = [
      for (final f in files) ...apiPathLines(f.path, f.readAsStringSync()),
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the rule catches public and admin paths', () {
    final source = [
      "'${_apiPrefixes[0]}me'",
      "'${_apiPrefixes[1]}users'",
      "'/x/v9/auth/login'",
    ].join('\n');
    expect(apiPathLines('bad.dart', source), hasLength(2));
  });
}
