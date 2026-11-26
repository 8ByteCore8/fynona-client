// CLI-42: every interactive element of the shell has a screen-reader label.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/shell/router.dart';

import 'support/harness.dart';

const _interactive = [
  SemanticsAction.tap,
  SemanticsAction.longPress,
  SemanticsAction.increase,
  SemanticsAction.decrease,
];

/// Labels of interactive semantics nodes that have no name.
List<String> unlabelledInteractiveNodes(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final problems = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final interactive = _interactive.any(data.hasAction);
    final named =
        data.label.trim().isNotEmpty ||
        data.tooltip.trim().isNotEmpty ||
        data.value.trim().isNotEmpty;
    if (interactive &&
        !named &&
        !node.isInvisible &&
        !node.isMergedIntoParent) {
      problems.add('${node.id} ${node.rect} actions=${data.actions}');
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return problems;
}

void main() {
  for (final (name, size) in [
    ('compact', const Size(390, 844)),
    ('wide', const Size(1280, 800)),
  ]) {
    for (final path in [
      overviewPath,
      operationsPath,
      analyticsPath,
      morePath,
    ]) {
      testWidgets('$name $path: every interactive node is labelled', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, size: size, initialLocation: path);
        expect(unlabelledInteractiveNodes(tester), isEmpty);
        handle.dispose();
      });
    }
  }

  testWidgets('profile switcher and nav items read their names', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    expect(
      find.bySemanticsLabel('Профіль: Усі профілі. Змінити профіль'),
      findsOneWidget,
    );
    for (final label in ['Огляд', 'Операції', 'Аналітика', 'Ще']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('Основна навігація'), findsOneWidget);
    handle.dispose();
  });
}
