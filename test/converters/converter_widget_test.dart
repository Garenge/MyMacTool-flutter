import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';
import 'package:mytools/pages/converters/color_palette_picker.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('encoding converter converts plain text to url encoded text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '编码转换');

    expect(find.text('编码转换'), findsWidgets);
    expect(find.text('URL'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Hello 世界');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('Hello%20%E4%B8%96%E7%95%8C'), findsOneWidget);
  });

  testWidgets('encoding converter converts url encoded text to plain text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '编码转换');

    await tester.enterText(
      find.byType(TextField).last,
      'Hello%20%E4%B8%96%E7%95%8C',
    );
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('Hello 世界'), findsOneWidget);
  });

  testWidgets('timestamp converter converts seconds timestamp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '时间戳转换');

    expect(find.text('当前时间'), findsOneWidget);
    expect(find.text('秒时间戳'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsWidgets);
    expect(find.text('毫秒时间戳'), findsOneWidget);
    expect(find.text('转换完成。'), findsOneWidget);
  });

  testWidgets('timestamp converter reports out of range timestamp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '时间戳转换');

    await tester.enterText(
      find.byType(TextField).first,
      '999999999999999999999999999999',
    );
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('时间戳超出可转换范围。'), findsOneWidget);
  });

  testWidgets('color converter converts hex color to common formats', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    expect(find.text('颜色值'), findsOneWidget);
    expect(find.text('HEX'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '#0F766E');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('#0F766E', findRichText: true), findsWidgets);
    expect(find.text('#FF0F766E', findRichText: true), findsOneWidget);
    expect(find.text('#0F766EFF', findRichText: true), findsOneWidget);
    expect(find.text('rgb(15, 118, 110)', findRichText: true), findsOneWidget);
    expect(
      find.text('rgba(15, 118, 110, 1)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('hsl(175, 77%, 26%)', findRichText: true), findsOneWidget);
    expect(find.text('hsv(175, 87%, 46%)', findRichText: true), findsWidgets);
    expect(
      find.text('cmyk(87%, 0%, 7%, 54%)', findRichText: true),
      findsOneWidget,
    );
    await expectVisibleText(tester, 'Color(0xFF0F766E)');
    await expectVisibleText(tester, '--color-primary: #0F766E;');
    await expectVisibleText(
      tester,
      'static const Color primary = Color(0xFF0F766E);',
    );
    await expectVisibleText(
      tester,
      'UIColor(red: 0.059, green: 0.463, blue: 0.431, alpha: 1)',
    );
    await expectVisibleText(tester, '<color name="primary">#FF0F766E</color>');
    expect(find.text('转换完成。'), findsOneWidget);
  });

  testWidgets('color converter converts rgba color to hex formats', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    await tester.enterText(
      find.byType(TextField).first,
      'rgba(15, 118, 110, 0.5)',
    );
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('#0F766E', findRichText: true), findsWidgets);
    expect(find.text('#800F766E', findRichText: true), findsOneWidget);
    expect(find.text('#0F766E80', findRichText: true), findsWidgets);
    expect(
      find.text('rgba(15, 118, 110, 0.502)', findRichText: true),
      findsOneWidget,
    );
    await expectVisibleText(tester, 'Color(0x800F766E)');
  });

  testWidgets('color converter accepts css rgba hex input', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    await tester.enterText(find.byType(TextField).first, '#0F766E80');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('#0F766E', findRichText: true), findsWidgets);
    expect(find.text('#800F766E', findRichText: true), findsOneWidget);
    expect(find.text('#0F766E80', findRichText: true), findsWidgets);
    expect(
      find.text('rgba(15, 118, 110, 0.502)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('color converter keeps flutter argb color input semantics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    await tester.enterText(find.byType(TextField).first, 'Color(0x800F766E)');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('#0F766E', findRichText: true), findsWidgets);
    expect(find.text('#800F766E', findRichText: true), findsOneWidget);
    expect(find.text('#0F766E80', findRichText: true), findsWidgets);
  });

  testWidgets('color converter reports invalid color input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    await tester.enterText(find.byType(TextField).first, '#XYZ');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(find.text('HEX 颜色只能包含 0-9、A-F。'), findsOneWidget);
  });

  testWidgets('color converter shows palette by default and selects color', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    expect(find.text('颜色盘'), findsWidgets);
    expect(find.text('拾取颜色'), findsNothing);

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('color-palette-saturation-value-area')),
      ),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, startsWith('#'));
    expect(find.text('已从颜色盘选取。'), findsOneWidget);
    expect(find.text('HEX'), findsOneWidget);
  });

  testWidgets('color converter syncs palette to converted input color', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '颜色转换');

    await tester.enterText(find.byType(TextField).first, '#336699');
    await tester.tap(find.text('转换'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ColorPalettePicker),
        matching: find.byKey(const ValueKey('color-palette-selected-text')),
      ),
      findsOneWidget,
    );
    expect(find.text('#336699', findRichText: true), findsWidgets);
  });

  testWidgets('hash calculator calculates common digest formats', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'Hash计算');

    expect(find.text('输入文本'), findsOneWidget);
    expect(find.text('MD5'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();

    expect(find.text('MD5'), findsOneWidget);
    expect(find.text('SHA-1'), findsOneWidget);
    expect(find.text('SHA-256'), findsOneWidget);
    expect(
      find.text('900150983cd24fb0d6963f7d28e17f72', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('a9993e364706816aba3e25717850c26c9cd0d89d', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text(
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Hash 计算完成。'), findsOneWidget);
  });

  testWidgets('hash calculator reports empty input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'Hash计算');

    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();

    expect(find.text('请先输入需要计算 Hash 的文本。'), findsOneWidget);
  });
}
