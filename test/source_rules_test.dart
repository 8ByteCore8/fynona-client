// Source rules for the app and fynona_ui:
// - CLI-40: no user-facing string literal in widgets (text comes from ARB);
// - CLI-43: direction-neutral layout (start/end, never left/right).
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widgets whose positional string argument is shown to the user.
const _textWidgets = {
  'Text',
  'SelectableText',
  'TextSpan',
  'Tooltip',
  'Semantics',
};

/// Named arguments that are shown or read to the user.
const _userFacingArgs = {
  'label',
  'labelText',
  'hintText',
  'helperText',
  'errorText',
  'counterText',
  'prefixText',
  'suffixText',
  'tooltip',
  'message',
  'semanticLabel',
  'semanticsLabel',
  'semanticsValue',
  'semanticsHint',
  'hint',
  'title',
  'text',
  'textSpan',
  'restorationId',
};

class _LiteralFinder extends RecursiveAstVisitor<void> {
  _LiteralFinder(this.file, this.unit);

  final String file;
  final CompilationUnit unit;
  final problems = <String>[];

  void _report(AstNode node, String why) {
    final line = unit.lineInfo.getLocation(node.offset).lineNumber;
    problems.add('$file:$line $why: ${node.toSource()}');
  }

  void _checkArguments(String callee, ArgumentList args) {
    for (final arg in args.arguments) {
      final value = arg.argumentExpression;
      if (arg is NamedArgument) {
        final name = arg.name.lexeme;
        if (_userFacingArgs.contains(name) && _isText(value)) {
          _report(arg, 'string literal for `$name`');
        }
      } else if (_textWidgets.contains(callee) && _isText(value)) {
        _report(arg, 'string literal in $callee');
      }
    }
  }

  static bool _isText(Expression e) =>
      e is StringLiteral &&
      (e is! SimpleStringLiteral || e.value.trim().isNotEmpty);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.name.lexeme;
    _checkArguments(type, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without `const`/`new`, `Text('x')` parses as a method invocation.
    final name = node.target == null
        ? node.methodName.name
        : node.target is SimpleIdentifier
        ? (node.target! as SimpleIdentifier).name
        : node.methodName.name;
    _checkArguments(name, node.argumentList);
    super.visitMethodInvocation(node);
  }
}

List<String> literalProblems(String path, String source) {
  final unit = parseString(content: source, path: path).unit;
  final finder = _LiteralFinder(path, unit);
  unit.accept(finder);
  return finder.problems;
}

final _directional = <RegExp, String>{
  RegExp(r'\b(left|right)\s*:'): 'left/right argument',
  RegExp(r'\bfromLTRB\b'): 'EdgeInsets.fromLTRB',
  RegExp(r'\bAlignment\.\w*(Left|Right)\b'): 'Alignment with left/right',
  RegExp(r'\bTextAlign\.(left|right)\b'): 'TextAlign.left/right',
  RegExp(r'\b(topLeft|topRight|bottomLeft|bottomRight)\s*:'): 'corner radius',
  RegExp(r'\bBorder\(\s*(left|right)\b'): 'Border left/right',
};

List<String> directionalProblems(String path, String source) {
  final problems = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final code = lines[i].split('//').first;
    for (final MapEntry(key: pattern, value: why) in _directional.entries) {
      if (pattern.hasMatch(code)) problems.add('$path:${i + 1} $why');
    }
  }
  return problems;
}

/// Hand-written Dart sources of the app and of fynona_ui.
List<File> sources() => [
  for (final dir in ['lib', 'packages/fynona_ui/lib'])
    ...Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('/l10n/gen/'))
        .where((f) => !f.path.endsWith('.g.dart')),
];

void main() {
  test('sources are found', () {
    expect(sources().length, greaterThan(10));
  });

  test('no user-facing string literal in widgets (CLI-40)', () {
    final problems = [
      for (final f in sources())
        ...literalProblems(f.path, f.readAsStringSync()),
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the literal rule catches the forms it is meant to catch', () {
    const bad = '''
      Widget a() => Text('Операції');
      Widget b() => const Text("Hello");
      Widget c() => Tooltip(message: 'Hi', child: x);
      Widget d() => Semantics(label: 'Кнопка', child: x);
      Widget e() => ListTile(title: Text('T \$n'));
      Widget f() => InputDecoration(hintText: 'Search');
    ''';
    expect(literalProblems('bad.dart', bad), hasLength(6));
    const good = '''
      Widget a() => Text(l.navOverview);
      Widget b() => const ValueKey('operations-list');
      final path = '/operations';
      Widget c() => Text(name, key: const Key('x'));
    ''';
    expect(literalProblems('good.dart', good), isEmpty);
  });

  test('direction-neutral paddings and alignment (CLI-43)', () {
    final problems = [
      for (final f in sources())
        ...directionalProblems(f.path, f.readAsStringSync()),
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the directional rule catches left/right forms', () {
    const bad = '''
      EdgeInsets.only(left: 8);
      EdgeInsets.fromLTRB(1, 2, 3, 4);
      Alignment.centerLeft;
      TextAlign.right;
      BorderRadius.only(topLeft: r);
    ''';
    expect(directionalProblems('bad.dart', bad), hasLength(5));
  });
}
