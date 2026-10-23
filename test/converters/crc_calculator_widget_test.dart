import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/app.dart';
import 'package:mytools/pages/converters/crc_algorithm.dart';
import 'package:mytools/pages/converters/crc_calculator_page.dart';
import 'package:mytools/pages/converters/crc_result_card.dart';

import '../test_helpers.dart';

void main() {
  Future<void> openPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CrcCalculatorPage())),
    );
  }

  Future<void> selectWidth(WidgetTester tester, int width) async {
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CRC$width').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectAlgorithm(WidgetTester tester, String name) async {
    final algorithm = crcAlgorithms.firstWhere((preset) => preset.name == name);
    final selectedWidth = tester
        .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
        .value;
    if (selectedWidth != algorithm.width) {
      await selectWidth(tester, algorithm.width);
    }
    final label = name == 'CRC8 (SMBUS)' ? 'SMBUS' : name.split('/').last;
    await tester.tap(find.byType(DropdownButton<CrcAlgorithm>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  void expectAlgorithmOptions(WidgetTester tester, int width, int count) {
    final selector = tester.widget<DropdownButton<CrcAlgorithm>>(
      find.byType(DropdownButton<CrcAlgorithm>),
    );
    expect(selector.items, hasLength(count));
    expect(selector.items!.every((item) => item.value!.width == width), isTrue);
  }

  testWidgets('sidebar opens CRC calculator', (tester) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'CRC校验');
    expect(find.byType(CrcCalculatorPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('type selection filters algorithms and resets to defaults', (
    tester,
  ) async {
    await openPage(tester);
    expect(find.text('CRC 类型'), findsOneWidget);
    expect(find.text('算法类型'), findsOneWidget);
    expect(find.text('CRC16'), findsOneWidget);
    expect(find.text('MODBUS'), findsOneWidget);
    expectAlgorithmOptions(tester, 16, 6);
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    await selectWidth(tester, 8);
    expectAlgorithmOptions(tester, 8, 3);
    expect(find.text('SMBUS'), findsOneWidget);
    expect(find.text('F4', findRichText: true), findsOneWidget);
    expect(find.text('高字节在前'), findsNothing);
    await selectAlgorithm(tester, 'CRC8/MAXIM');
    expect(find.text('A1', findRichText: true), findsOneWidget);
    await selectWidth(tester, 16);
    expectAlgorithmOptions(tester, 16, 6);
    expect(find.text('MODBUS'), findsOneWidget);
    expect(find.text('4B37', findRichText: true), findsOneWidget);
    await selectWidth(tester, 8);
    expect(find.text('SMBUS'), findsOneWidget);
    expect(find.text('F4', findRichText: true), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123456789',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculates only default algorithm and copies byte order', (
    tester,
  ) async {
    await openPage(tester);
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    expect(find.text('CRC 计算完成，共 9 字节。'), findsOneWidget);
    expect(find.byType(CrcResultCard), findsOneWidget);
    expect(find.text('4B37', findRichText: true), findsOneWidget);
    expect(find.text('CRC8/ROHC'), findsNothing);
    await tester.tap(find.byTooltip('复制 CRC16/MODBUS 低字节在前'));
    await tester.pumpAndSettle();
    expect(copied, '37 4B');
    expect(find.text('已复制 CRC16/MODBUS 低字节在前。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching algorithms recalculates and updates byte order rows', (
    tester,
  ) async {
    await openPage(tester);
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    const checks = {
      'CRC16/ARC (IBM)': 'BB3D',
      'CRC16/CCITT-FALSE': '29B1',
      'CRC16/XMODEM': '31C3',
      'CRC16/KERMIT': '2189',
      'CRC16/X-25': '906E',
      'CRC8 (SMBUS)': 'F4',
      'CRC8/MAXIM': 'A1',
      'CRC8/ROHC': 'D0',
      'CRC16/MODBUS': '4B37',
    };
    for (final entry in checks.entries) {
      await selectAlgorithm(tester, entry.key);
      expect(find.byType(CrcResultCard), findsOneWidget);
      expect(find.text(entry.value, findRichText: true), findsOneWidget);
      expect(
        find.text('高字节在前'),
        entry.key.startsWith('CRC16') ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('低字节在前'),
        entry.key.startsWith('CRC16') ? findsOneWidget : findsNothing,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123456789',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clear keeps algorithm and switching without results waits for calculate',
    (tester) async {
      await openPage(tester);
      await tester.enterText(find.byType(TextField), '123456789');
      await selectAlgorithm(tester, 'CRC8/ROHC');
      expect(find.byType(CrcResultCard), findsNothing);
      await tester.tap(find.text('计算'));
      await tester.pumpAndSettle();
      expect(find.text('D0', findRichText: true), findsOneWidget);
      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      expect(find.byType(CrcResultCard), findsNothing);
      expect(
        tester
            .widget<DropdownButton<CrcAlgorithm>>(
              find.byType(DropdownButton<CrcAlgorithm>),
            )
            .value!
            .name,
        'CRC8/ROHC',
      );
      await tester.enterText(find.byType(TextField), '123456789');
      await tester.tap(find.text('计算'));
      await tester.pumpAndSettle();
      expect(find.text('D0', findRichText: true), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'changed');
      await tester.pump();
      await selectAlgorithm(tester, 'CRC16/MODBUS');
      expect(find.byType(CrcResultCard), findsNothing);
      expect(find.text('CRC 计算完成，共 9 字节。'), findsNothing);
    },
  );

  testWidgets('hex mode validates input and clear resets state', (
    tester,
  ) async {
    await openPage(tester);
    await tester.tap(find.text('十六进制字节'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '01 03 00 00 00 01');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    expect(find.text('0A84', findRichText: true), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'A B');
    await tester.pump();
    expect(find.text('0A84', findRichText: true), findsNothing);
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    expect(find.textContaining('每组必须包含完整字节'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ZZ');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    expect(find.textContaining('十六进制只能包含'), findsOneWidget);
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.textContaining('十六进制只能包含'), findsNothing);
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    expect(find.text('请先输入需要计算 CRC 的内容。'), findsOneWidget);
  });

  testWidgets('changing input mode invalidates previous results', (
    tester,
  ) async {
    await openPage(tester);
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.tap(find.text('计算'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('十六进制字节'));
    await tester.pumpAndSettle();
    expect(find.text('4B37', findRichText: true), findsNothing);
    expect(find.text('CRC 计算完成，共 9 字节。'), findsNothing);
  });
}
