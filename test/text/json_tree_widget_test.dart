import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/text/json_formatter_page.dart';

Future<void> openTree(WidgetTester tester, String input) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: JsonFormatterPage())),
  );
  await tester.enterText(find.byType(TextField).first, input);
  await tester.tap(find.text('格式化'));
  await tester.tap(find.text('树形'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tree expands nested nodes and copies node paths and values', (
    tester,
  ) async {
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await openTree(tester, '{"items":[{"name":"MyTools"}],"empty":{}}');
    expect(find.text('"empty": Object · 0 项'), findsOneWidget);
    expect(find.text('"name": "MyTools"'), findsNothing);
    await tester.tap(find.text('"items": Array · 1 项'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[0]: Object · 1 项'));
    await tester.pumpAndSettle();
    expect(find.text('"name": "MyTools"'), findsOneWidget);

    final menu = find.byTooltip(r'节点操作 $["items"][0]["name"]');
    for (final action in {
      '复制路径': r'$["items"][0]["name"]',
      '复制值': 'MyTools',
      '复制子 JSON': '"MyTools"',
    }.entries) {
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text(action.key));
      await tester.pumpAndSettle();
      expect(clipboard, action.value);
    }
    await tester.tap(find.text('"items": Array · 1 项'));
    await tester.pumpAndSettle();
    expect(find.text('"name": "MyTools"'), findsNothing);
    await tester.tap(find.text('文本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"name": "MyTools"'), findsOneWidget);
  });

  testWidgets('tree handles null, stale input, errors and clearing', (
    tester,
  ) async {
    await openTree(tester, 'null');
    expect(find.text(r'$: null'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '{"new":true}');
    await tester.pump();
    expect(find.text('输出（待更新）'), findsOneWidget);
    await tester.tap(find.text('校验'));
    await tester.pumpAndSettle();
    expect(find.text('"new": true'), findsOneWidget);
    expect(find.text(r'$: null'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '{');
    await tester.tap(find.text('格式化'));
    await tester.pumpAndSettle();
    expect(find.text('"new": true'), findsNothing);
    expect(find.textContaining('JSON 解析失败'), findsOneWidget);
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('处理 JSON 后可查看树形结构'), findsOneWidget);
  });
}
