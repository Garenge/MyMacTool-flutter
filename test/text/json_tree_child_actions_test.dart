import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/text/json_tree_view.dart';

Future<void> showTree(WidgetTester tester, Object? value) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: JsonTreeView(value: value, indentSpaces: 2, onCopy: (_, _) {}),
      ),
    ),
  );
}

void main() {
  testWidgets('array actions control direct children and keep array open', (
    tester,
  ) async {
    await showTree(tester, {
      'items': [
        {
          'deep': {'leaf': 1},
        },
        {'id': 2},
        [
          {'nested': true},
        ],
      ],
      'other': {'sibling': true},
    });
    expect(find.text('[0]: Object · 1 项'), findsNothing);
    await tester.tap(find.byTooltip(r'展开子级 $["items"]'));
    await tester.pumpAndSettle();
    expect(find.text('"deep": Object · 1 项'), findsOneWidget);
    expect(find.text('"id": 2'), findsOneWidget);
    expect(find.text('[2]: Array · 1 项'), findsOneWidget);
    expect(find.text('[0]: Object · 1 项'), findsNWidgets(2));
    expect(find.text('"leaf": 1'), findsNothing);
    expect(find.text('"nested": true'), findsNothing);
    expect(find.text('"sibling": true'), findsNothing);

    await tester.tap(find.text('"deep": Object · 1 项'));
    await tester.pumpAndSettle();
    expect(find.text('"leaf": 1'), findsOneWidget);
    await tester.tap(find.byTooltip(r'收起子级 $["items"]'));
    await tester.pumpAndSettle();
    expect(find.text('[0]: Object · 1 项'), findsOneWidget);
    expect(find.text('[1]: Object · 1 项'), findsOneWidget);
    expect(find.text('[2]: Array · 1 项'), findsOneWidget);
    expect(find.text('"id": 2'), findsNothing);
    expect(find.text('"deep": Object · 1 项'), findsNothing);
    expect(find.text('"leaf": 1'), findsNothing);
  });

  testWidgets('root array actions open a collapsed array', (tester) async {
    await showTree(tester, [
      {'id': 1},
    ]);
    await tester.tap(find.text(r'$: Array · 1 项'));
    await tester.pumpAndSettle();
    expect(find.text('[0]: Object · 1 项'), findsNothing);
    await tester.tap(find.byTooltip(r'展开子级 $'));
    await tester.pumpAndSettle();
    expect(find.text('"id": 1'), findsOneWidget);
    await tester.tap(find.text(r'$: Array · 1 项'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(r'收起子级 $'));
    await tester.pumpAndSettle();
    expect(find.text('[0]: Object · 1 项'), findsOneWidget);
    expect(find.text('"id": 1'), findsNothing);
  });

  testWidgets('arrays without expandable children disable both actions', (
    tester,
  ) async {
    for (final value in [
      [],
      [1, 'text', null, {}, []],
    ]) {
      await showTree(tester, value);
      for (final label in [r'展开子级 $', r'收起子级 $']) {
        final button = tester.widget<IconButton>(
          find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == label,
          ),
        );
        expect(button.onPressed, isNull);
      }
    }
    await showTree(tester, {
      'object': {'id': 1},
    });
    expect(find.byIcon(Icons.unfold_more), findsNothing);
    expect(find.byIcon(Icons.unfold_less), findsNothing);
  });
}
