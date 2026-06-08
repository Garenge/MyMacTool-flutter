import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('json formatter formats compact json text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JSON格式化');

    expect(find.text('格式化'), findsOneWidget);
    expect(find.text('压缩'), findsOneWidget);
    expect(find.text('校验'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '{"b":2,"a":1}');
    await tester.tap(find.text('格式化'));
    await tester.pumpAndSettle();

    expect(find.textContaining('"b": 2'), findsOneWidget);
    expect(find.text('格式化完成。'), findsOneWidget);
  });

  testWidgets('json formatter reports invalid json errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JSON格式化');

    await tester.enterText(find.byType(TextField).first, '{"name":}');
    await tester.tap(find.text('校验'));
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON 解析失败'), findsOneWidget);
  });

  testWidgets('jwt decoder decodes header payload and time claims', (
    WidgetTester tester,
  ) async {
    const jwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjMiLCJuYW1lIjoiTXlUb29scyIsImlhdCI6MCwiZXhwIjoyMDAwMDAwMDAwfQ.'
        'signature';

    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JWT解析');

    expect(find.text('JWT'), findsOneWidget);
    expect(find.text('Header'), findsNothing);

    await tester.enterText(find.byType(TextField).first, jwt);
    await tester.tap(find.text('解析'));
    await tester.pumpAndSettle();

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Payload'), findsOneWidget);
    expect(find.text('时间声明'), findsOneWidget);
    expect(find.text('未过期'), findsOneWidget);
    expect(
      find.textContaining('"alg": "HS256"', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('"name": "MyTools"', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('JWT 解析完成。注意：当前仅解码内容，不校验签名。'), findsOneWidget);
  });

  testWidgets('jwt decoder reports invalid token segments', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JWT解析');

    await tester.enterText(find.byType(TextField).first, 'invalid-token');
    await tester.tap(find.text('解析'));
    await tester.pumpAndSettle();

    expect(find.text('JWT 需要包含 Header、Payload、Signature 三段。'), findsOneWidget);
  });

  testWidgets('regex tester shows matches groups and replacement preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '正则测试');

    expect(find.text('正则表达式'), findsOneWidget);
    expect(find.text('匹配结果和替换预览会显示在这里。'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), r'(\w+)');
    await tester.enterText(fields.at(1), 'foo bar');
    await tester.enterText(fields.at(2), 'X');
    await tester.tap(find.text('测试正则'));
    await tester.pumpAndSettle();

    expect(find.text('匹配到 2 处结果。'), findsOneWidget);
    expect(find.text('Match 1 · 0-3'), findsOneWidget);
    expect(find.text('Match 2 · 4-7'), findsOneWidget);
    expect(find.text('Group 1'), findsWidgets);
    expect(find.text('替换预览'), findsWidgets);
    expect(find.text('X X'), findsOneWidget);
  });

  testWidgets('text diff tool shows added and removed lines', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '文本Diff');

    expect(find.text('左侧文本'), findsOneWidget);
    expect(find.text('右侧文本'), findsOneWidget);
    expect(find.text('对比结果会显示在这里。'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a\nb\nc');
    await tester.enterText(fields.at(1), 'a\nx\nc');
    await tester.tap(find.text('对比'));
    await tester.pumpAndSettle();

    expect(find.text('对比完成，发现 2 行差异。'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('x'), findsOneWidget);
  });
}
