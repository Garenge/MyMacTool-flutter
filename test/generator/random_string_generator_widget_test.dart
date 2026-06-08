import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('random generator creates uuid and random strings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '随机生成');

    expect(find.text('UUID v4'), findsOneWidget);
    expect(find.text('随机字符串'), findsWidgets);
    expect(find.text('生成后的内容会显示在这里。'), findsOneWidget);

    await tester.tap(find.text('生成 UUID'));
    await tester.pumpAndSettle();

    expect(find.text('已生成 5 个 UUID v4。'), findsOneWidget);

    await tester.tap(find.text('生成随机字符串'));
    await tester.pumpAndSettle();

    expect(find.text('已生成 5 个随机字符串。'), findsOneWidget);
  });
}
