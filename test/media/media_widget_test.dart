import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('image info page shows drop zone and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '图片信息');

    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.text('拖拽图片到这里'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('当前图片'), findsOneWidget);
    expect(find.text('等待选择图片'), findsOneWidget);
    expect(find.text('选择图片后会显示尺寸、格式、大小和透明通道信息。'), findsOneWidget);
  });

  testWidgets('media info page shows drop zone and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '音视频信息');

    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.text('音视频信息'), findsWidgets);
    expect(find.text('拖拽音视频到这里'), findsOneWidget);
    expect(find.text('选择文件'), findsOneWidget);
    expect(find.text('启用内置组件'), findsOneWidget);
    expect(find.text('导入ffprobe'), findsOneWidget);
    expect(find.text('正在检测 ffprobe 运行时...'), findsOneWidget);
    expect(find.text('选择音频或视频文件后会显示容器、编码、时长、码率和流信息。'), findsOneWidget);
  });
}
