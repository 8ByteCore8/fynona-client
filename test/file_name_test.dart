// Saved files stay in their folder whatever the server sends.
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/shell/file_name.dart';

void main() {
  test('only a UUID export id becomes part of the file name', () {
    const id = '0193a1b2-0000-7000-8000-0000000000E1';
    expect(exportArchiveFileName(id), 'fynona-export-$id.json');
    for (final bad in ['e1', '../../.bashrc', '$id/x', '', 'C:\\x']) {
      expect(exportArchiveFileName(bad), 'fynona-export.json', reason: bad);
    }
  });

  test('a safe file name has no folder part', () {
    expect(isSafeFileName('fynona-recovery-codes.txt'), isTrue);
    expect(isSafeFileName('fynona-export.json'), isTrue);
    for (final bad in [
      '',
      '.',
      '..',
      '../x',
      'a/b',
      r'a\b',
      'C:x',
      'a\nb',
      'x' * 256,
    ]) {
      expect(isSafeFileName(bad), isFalse, reason: bad);
    }
  });
}
