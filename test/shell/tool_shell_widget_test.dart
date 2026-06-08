import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tool shell renders svg preview entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    expect(find.text('SVG预览'), findsOneWidget);
    expect(find.text('编码转换'), findsOneWidget);
    expect(find.text('JSON格式化'), findsOneWidget);
    expect(find.text('时间戳转换'), findsOneWidget);
    expect(find.text('颜色转换'), findsOneWidget);
    expect(find.text('Hash计算'), findsOneWidget);
    expect(find.text('图片信息'), findsOneWidget);
    expect(find.text('音视频信息'), findsOneWidget);
    expect(find.text('JWT解析'), findsOneWidget);
    await expectVisibleText(
      tester,
      '二维码工具',
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('打开文件'), findsOneWidget);
    expect(find.text('粘贴'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);
  });

  testWidgets('tool shell sidebar item uses visible selected background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('SVG预览'), matching: find.byType(Material))
          .first,
    );

    expect(material.color, const Color(0xFFEAF7F6));
  });

  testWidgets('tool shell does not log sidebar selections by default', (
    WidgetTester tester,
  ) async {
    final messages = <String>[];
    final oldDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        messages.add(message);
      }
    };

    try {
      await tester.pumpWidget(const MyToolsApp());
      await selectTool(tester, '颜色转换');
    } finally {
      debugPrint = oldDebugPrint;
    }

    expect(messages, isEmpty);
  });
}
