import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clipboardSvg =
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#0F766E"/></svg>';

  installClipboardTextMock(clipboardSvg);

  testWidgets('svg preview page supports drag-and-drop import', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.text('支持将 SVG 文件直接拖入左侧区域，内容会自动填充并立即渲染。'), findsOneWidget);
  });

  testWidgets('svg preview page shows preview zoom controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    expect(find.text('渲染预览'), findsOneWidget);
    expect(find.byTooltip('缩小'), findsOneWidget);
    expect(find.byTooltip('放大'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('支持滚轮缩放，最大可到 500%'), findsOneWidget);
  });

  testWidgets('svg preview page shows effective area label after render', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    await tester.enterText(
      find.byType(TextField),
      '<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#0F766E"/></svg>',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('图片有效区域'), findsOneWidget);
  });

  testWidgets(
    'svg preview page copies content summary and reports missing path',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyToolsApp());

      await tester.enterText(
        find.byType(TextField),
        '<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#0F766E"/></svg>',
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.text('复制内容'), findsOneWidget);
      expect(find.text('复制摘要'), findsOneWidget);
      expect(find.text('复制路径'), findsOneWidget);

      await tester.tap(find.text('复制内容'));
      await tester.pump();
      expect(find.text('已复制 SVG 内容。'), findsOneWidget);

      await tester.ensureVisible(find.text('复制摘要'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复制摘要'));
      await tester.pump();
      expect(find.text('已复制 SVG 摘要。'), findsOneWidget);

      await tester.ensureVisible(find.text('复制路径'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复制路径'));
      await tester.pump();
      expect(find.text('当前 SVG 没有关联文件路径。'), findsOneWidget);
    },
  );

  testWidgets('svg preview page caps zoom at 500 percent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    await tester.enterText(
      find.byType(TextField),
      '<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#0F766E"/></svg>',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 20; index++) {
      await tester.tap(find.byTooltip('放大'));
      await tester.pump();
    }

    expect(find.text('500%'), findsOneWidget);
  });

  testWidgets('svg preview page pastes clipboard content and stores history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await tester.tap(find.text('粘贴'));
    await tester.pump();

    expect(find.text('粘贴成功'), findsOneWidget);
    expect(find.text('最近记录'), findsOneWidget);
    expect(find.textContaining('剪切板粘贴'), findsOneWidget);
  });

  testWidgets('lottie preview page shows copy actions and empty state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'Lottie预览');

    expect(find.text('Lottie 预览'), findsOneWidget);
    expect(find.text('文件列表'), findsOneWidget);
    expect(find.text('复制摘要'), findsOneWidget);
    expect(find.text('复制路径'), findsOneWidget);
    expect(find.text('从右侧拖入多个 Lottie JSON 文件，或点击“打开文件夹”批量加载。'), findsOneWidget);
  });
}
