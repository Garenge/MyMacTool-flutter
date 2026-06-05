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
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mytools/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clipboardSvg =
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#0F766E"/></svg>';

  Future<void> selectTool(WidgetTester tester, String title) async {
    final toolFinder = find.text(title);

    if (toolFinder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        toolFinder,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    await tester.tap(toolFinder);
    await tester.pumpAndSettle();
  }

  Future<void> expectVisibleText(
    WidgetTester tester,
    String text, {
    Finder? scrollable,
  }) async {
    final textFinder = find.text(text, findRichText: true);

    if (textFinder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        textFinder,
        120,
        scrollable: scrollable ?? find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
    }

    expect(textFinder, findsOneWidget);
  }

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
    expect(find.text('编码转换'), findsOneWidget);
    expect(find.text('JSON格式化'), findsOneWidget);
    expect(find.text('时间戳转换'), findsOneWidget);
    expect(find.text('颜色转换'), findsOneWidget);
    expect(find.text('Hash计算'), findsOneWidget);
    expect(find.text('图片信息'), findsOneWidget);
    expect(find.text('JWT解析'), findsOneWidget);
    expect(find.text('二维码工具'), findsOneWidget);
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

  testWidgets('json formatter formats compact json text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JSON格式化');

    expect(find.text('格式化'), findsOneWidget);
    expect(find.text('压缩'), findsOneWidget);
    expect(find.text('校验'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '{"b":2,"a":1}');
    await tester.tap(find.text('格式化'));
    await tester.pumpAndSettle();

    expect(find.textContaining('"b": 2'), findsOneWidget);
    expect(find.text('格式化完成。'), findsOneWidget);
  });

  testWidgets('json formatter reports invalid json errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JSON格式化');

    await tester.enterText(find.byType(TextField).first, '{"name":}');
    await tester.tap(find.text('校验'));
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON 解析失败'), findsOneWidget);
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

  testWidgets('ipa unpack page shows app info panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'IPA解析');

    expect(find.text('当前结果'), findsOneWidget);
    expect(find.text('应用信息'), findsOneWidget);
    expect(find.text('解析 IPA 后会显示 App 名称、Bundle ID、版本号等信息。'), findsOneWidget);
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
    expect(find.text('hsv(175, 87%, 46%)', findRichText: true), findsOneWidget);
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
    expect(find.text('#0F766E80', findRichText: true), findsOneWidget);
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

  testWidgets('jwt decoder decodes header payload and time claims', (
    WidgetTester tester,
  ) async {
    const jwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjMiLCJuYW1lIjoiTXlUb29scyIsImlhdCI6MCwiZXhwIjoyMDAwMDAwMDAwfQ.'
        'signature';

    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JWT解析');

    expect(find.text('JWT'), findsOneWidget);
    expect(find.text('Header'), findsNothing);

    await tester.enterText(find.byType(TextField).first, jwt);
    await tester.tap(find.text('解析'));
    await tester.pumpAndSettle();

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Payload'), findsOneWidget);
    expect(find.text('时间声明'), findsOneWidget);
    expect(find.text('未过期'), findsOneWidget);
    expect(
      find.textContaining('"alg": "HS256"', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('"name": "MyTools"', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('JWT 解析完成。注意：当前仅解码内容，不校验签名。'), findsOneWidget);
  });

  testWidgets('jwt decoder reports invalid token segments', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'JWT解析');

    await tester.enterText(find.byType(TextField).first, 'invalid-token');
    await tester.tap(find.text('解析'));
    await tester.pumpAndSettle();

    expect(find.text('JWT 需要包含 Header、Payload、Signature 三段。'), findsOneWidget);
  });

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

    await tester.tap(find.text('复制内容'));
    await tester.pumpAndSettle();

    expect(find.text('请先输入要生成二维码的内容。'), findsOneWidget);
  });

  testWidgets('mobileprovision profile page shows drop zone and empty result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'Profile解析');

    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.text('拖拽 Profile 到这里'), findsOneWidget);
    expect(find.text('选择文件'), findsOneWidget);
    expect(
      find.text('支持 .mobileprovision 和 .provisionprofile 文件。'),
      findsOneWidget,
    );
    expect(
      find.text('选择 Profile 后会显示 Bundle ID、Entitlements、证书和设备信息。'),
      findsOneWidget,
    );
  });

  testWidgets('plist document page shows drop zone and empty result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'Plist查看');

    expect(find.byType(DropTarget), findsOneWidget);
    expect(find.text('拖拽 Plist 到这里'), findsOneWidget);
    expect(find.text('选择文件'), findsOneWidget);
    expect(find.text('支持 XML plist 和 binary plist 文件。'), findsOneWidget);
    expect(find.text('选择 plist 后会显示 key、path、类型和值，并支持搜索。'), findsOneWidget);
  });

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

  testWidgets('regex tester shows matches groups and replacement preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '正则测试');

    expect(find.text('正则表达式'), findsOneWidget);
    expect(find.text('匹配结果和替换预览会显示在这里。'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), r'(\w+)');
    await tester.enterText(fields.at(1), 'foo bar');
    await tester.enterText(fields.at(2), 'X');
    await tester.tap(find.text('测试正则'));
    await tester.pumpAndSettle();

    expect(find.text('匹配到 2 处结果。'), findsOneWidget);
    expect(find.text('Match 1 · 0-3'), findsOneWidget);
    expect(find.text('Match 2 · 4-7'), findsOneWidget);
    expect(find.text('Group 1'), findsWidgets);
    expect(find.text('替换预览'), findsWidgets);
    expect(find.text('X X'), findsOneWidget);
  });

  testWidgets('text diff tool shows added and removed lines', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, '文本Diff');

    expect(find.text('左侧文本'), findsOneWidget);
    expect(find.text('右侧文本'), findsOneWidget);
    expect(find.text('对比结果会显示在这里。'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a\nb\nc');
    await tester.enterText(fields.at(1), 'a\nx\nc');
    await tester.tap(find.text('对比'));
    await tester.pumpAndSettle();

    expect(find.text('对比完成，发现 2 行差异。'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('x'), findsOneWidget);
  });
}
