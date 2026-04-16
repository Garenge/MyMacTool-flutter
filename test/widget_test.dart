// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clipboardSvg =
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#0F766E"/></svg>';

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
      if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': clipboardSvg};
      }

      if (methodCall.method == 'Clipboard.setData') {
        return null;
      }

      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('tool shell renders svg preview entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());

    expect(find.text('SVG预览'), findsOneWidget);
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
      find.ancestor(
        of: find.text('SVG预览'),
        matching: find.byType(Material),
      ).first,
    );

    expect(material.color, const Color(0xFFEAF7F6));
  });

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
}
