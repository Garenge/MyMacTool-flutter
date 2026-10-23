import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/app.dart';
import 'package:mytools/pages/shell/tool_catalog.dart';
import 'package:mytools/pages/shell/tool_sidebar.dart';

void main() {
  testWidgets('search matches aliases and restores collapsed groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolSidebar(
            selectedTool: ToolItem.svgPreview,
            onToolSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('文本与数据'));
    await tester.tap(find.text('文本与数据'));
    await tester.pumpAndSettle();
    expect(find.text('编码转换'), findsNothing);

    await tester.enterText(find.byType(TextField), 'BASE64');
    await tester.pumpAndSettle();
    expect(find.text('编码转换'), findsOneWidget);
    expect(find.text('文本与数据'), findsOneWidget);
    expect(find.text('SVG预览'), findsNothing);

    await tester.enterText(find.byType(TextField), 'md5');
    await tester.pumpAndSettle();
    expect(find.text('Hash计算'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '不存在的工具');
    await tester.pumpAndSettle();
    expect(find.text('未找到匹配的工具'), findsOneWidget);

    await tester.tap(find.byTooltip('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('SVG预览'), findsOneWidget);
    expect(find.text('编码转换'), findsNothing);
  });

  testWidgets(
    'external navigation reveals selection through search and collapse',
    (tester) async {
      var selected = ToolItem.ipaUnpack;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return ToolSidebar(
                  selectedTool: selected,
                  onToolSelected: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Apple 开发'));
      await tester.tap(find.text('Apple 开发'));
      await tester.enterText(find.byType(TextField), 'base64');
      await tester.pumpAndSettle();
      update(() => selected = ToolItem.plistDocument);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Plist查看').hitTestable(), findsOneWidget);
      expect(find.text('Profile解析'), findsOneWidget);
    },
  );

  testWidgets('command K focuses search and escape clears and unfocuses', (
    tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    final search = tester.widget<TextField>(find.byType(TextField).first);
    expect(search.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField).first, 'base64');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(search.controller!.text, isEmpty);
    expect(search.focusNode!.hasFocus, isFalse);
    expect(find.text('SVG预览'), findsOneWidget);

    await tester.tap(find.byType(TextField).last);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(search.focusNode!.hasFocus, isTrue);
  });
}
