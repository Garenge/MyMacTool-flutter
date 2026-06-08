import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('qr code tool generates code with optional url encoding', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '二维码工具');

    expect(find.text('生成二维码'), findsWidgets);
    expect(find.text('解析二维码'), findsOneWidget);
    expect(find.text('生成前先 URL 编码'), findsOneWidget);
    expect(find.text('生成设置'), findsOneWidget);
    expect(find.text('纠错 M'), findsOneWidget);
    expect(find.text('定位点'), findsOneWidget);
    expect(find.text('码点'), findsOneWidget);
    expect(find.text('圆形'), findsOneWidget);
    expect(find.text('圆点'), findsOneWidget);
    expect(find.text('导出尺寸'), findsOneWidget);
    expect(find.text('Logo'), findsOneWidget);
    expect(find.text('选择Logo'), findsOneWidget);
    expect(find.text('移除Logo'), findsOneWidget);
    expect(find.text('可选嵌入 Logo，建议使用纠错 H 并控制在 24% 以内。'), findsOneWidget);
    expect(find.text('前景色'), findsOneWidget);
    expect(find.text('背景色'), findsOneWidget);
    expect(find.text('支持粘贴、拖拽或选择二维码图片。'), findsNothing);
    expect(find.text('输入字符串后会在这里生成二维码。'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Hello 世界');
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('生成前先 URL 编码'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('圆点'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('qr code tool switches to decode tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '二维码工具');

    await tester.tap(find.text('解析二维码'));
    await tester.pumpAndSettle();

    expect(find.text('支持粘贴、拖拽或选择二维码图片。'), findsOneWidget);
    expect(find.text('解析结果'), findsOneWidget);
    expect(find.text('粘贴解析'), findsOneWidget);
    expect(find.text('复制URL编码'), findsOneWidget);
    expect(find.text('打开URL'), findsOneWidget);
    expect(find.text('输入字符串后会在这里生成二维码。'), findsNothing);
  });

  testWidgets('qr code tool reports empty generated copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '二维码工具');

    await tester.ensureVisible(find.text('复制内容'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制内容'));
    await tester.pumpAndSettle();

    expect(find.text('请先输入要生成二维码的内容。'), findsOneWidget);
  });
}
