import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytools/app.dart';
import 'package:mytools/pages/mobile/ipa_app_info.dart';
import 'package:mytools/pages/mobile/mobileprovision_profile_info.dart';
import 'package:mytools/pages/mobile/mobileprovision_profile_page.dart';
import 'package:mytools/pages/mobile/plist_document_info.dart';
import 'package:mytools/pages/mobile/plist_document_page.dart';
import 'package:mytools/pages/mobile/x509_certificate_info.dart';
import 'package:mytools/pages/shell/tool_shell_page.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ipa unpack page shows app info panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyToolsApp());
    await selectTool(tester, 'IPA解析');

    expect(find.text('当前结果'), findsOneWidget);
    expect(find.text('应用信息'), findsOneWidget);
    expect(find.text('解析 IPA 后会显示 App 名称、Bundle ID、版本号等信息。'), findsOneWidget);
  });

  testWidgets('ipa unpack page shows linked file actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileInfo = buildProfileInfo(
      '/tmp/Payload/MyTools.app/embedded.mobileprovision',
    );

    await pumpIpaShell(
      tester,
      appInfo: buildIpaAppInfo(
        infoPlistPath: '/tmp/Payload/MyTools.app/Info.plist',
        profileInfo: profileInfo,
      ),
    );

    expect(find.text('定位 Info.plist'), findsOneWidget);
    expect(find.text('查看 Info.plist'), findsOneWidget);
    expect(find.text('定位 Profile'), findsOneWidget);
    expect(find.text('解析 Profile'), findsOneWidget);
  });

  testWidgets('plist document page loads initial xml plist path', (
    WidgetTester tester,
  ) async {
    const path = '/tmp/Payload/MyTools.app/Info.plist';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlistDocumentPage(
            initialPath: path,
            parser: _FakePlistParser(buildPlistInfo(path)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Plist查看器'), findsOneWidget);
    expect(find.text('读取完成，共 2 个节点。'), findsOneWidget);
    expect(find.text('CFBundleIdentifier'), findsOneWidget);
    expect(find.text('com.example.mytools'), findsOneWidget);
  });

  testWidgets('profile page renders initial embedded profile info', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileInfo = buildProfileInfo(
      '/tmp/Payload/MyTools.app/embedded.mobileprovision',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileProvisionProfilePage(initialInfo: profileInfo),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Provisioning Profile解析'), findsOneWidget);
    expect(find.text('已从 IPA 载入 Profile。'), findsOneWidget);
    expect(find.text('MyTools Dev Profile'), findsWidgets);
    expect(find.text('com.example.mytools'), findsWidgets);
  });

  testWidgets(
    'profile page renders diagnostics and x509 certificate metadata',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profileInfo = buildProfileInfoWithCertificate(
        '/tmp/Payload/MyTools.app/embedded.mobileprovision',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileProvisionProfilePage(initialInfo: profileInfo),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('签名诊断'), findsOneWidget);
      expect(find.text('未发现明显签名风险'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(
        find.text('CN=Apple Development: MyTools, O=Example Team'),
        findsOneWidget,
      );
    },
  );

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
}

Future<void> pumpIpaShell(
  WidgetTester tester, {
  required IpaAppInfo appInfo,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ToolShellPage(
        initialTool: ToolItem.ipaUnpack,
        initialIpaAppInfo: appInfo,
      ),
    ),
  );
  await tester.pump();
}

IpaAppInfo buildIpaAppInfo({
  required String infoPlistPath,
  MobileProvisionProfileInfo? profileInfo,
}) {
  return IpaAppInfo(
    appName: 'MyTools',
    bundleIdentifier: 'com.example.mytools',
    shortVersion: '1.0.0',
    buildNumber: '42',
    minimumOsVersion: '15.0',
    executableName: 'MyTools',
    infoPlistPath: infoPlistPath,
    embeddedProfilePath: profileInfo?.filePath ?? '',
    embeddedProfileInfo: profileInfo,
    embeddedProfileError: '',
  );
}

MobileProvisionProfileInfo buildProfileInfo(String path) {
  return MobileProvisionProfileInfo(
    filePath: path,
    name: 'MyTools Dev Profile',
    uuid: '11111111-2222-3333-4444-555555555555',
    appIdName: 'MyTools',
    teamName: 'Example Team',
    teamIdentifiers: const <String>['ABCDE12345'],
    appIdentifierPrefixes: const <String>['ABCDE12345'],
    applicationIdentifier: 'ABCDE12345.com.example.mytools',
    bundleIdentifier: 'com.example.mytools',
    creationDate: DateTime.utc(2026),
    expirationDate: DateTime.utc(2027),
    timeToLive: 365,
    platforms: const <String>['iOS'],
    provisionedDevices: const <String>['00008030-001122334455802E'],
    certificates: const <MobileProvisionCertificateInfo>[],
    entitlements: const <String, Object?>{
      'application-identifier': 'ABCDE12345.com.example.mytools',
      'get-task-allow': true,
    },
    provisionsAllDevices: false,
    betaReportsActive: false,
  );
}

MobileProvisionProfileInfo buildProfileInfoWithCertificate(String path) {
  return MobileProvisionProfileInfo(
    filePath: path,
    name: 'MyTools Dev Profile',
    uuid: '11111111-2222-3333-4444-555555555555',
    appIdName: 'MyTools',
    teamName: 'Example Team',
    teamIdentifiers: const <String>['ABCDE12345'],
    appIdentifierPrefixes: const <String>['ABCDE12345'],
    applicationIdentifier: 'ABCDE12345.com.example.mytools',
    bundleIdentifier: 'com.example.mytools',
    creationDate: DateTime.utc(2026),
    expirationDate: DateTime.utc(2027),
    timeToLive: 365,
    platforms: const <String>['iOS'],
    provisionedDevices: const <String>[],
    certificates: const <MobileProvisionCertificateInfo>[
      MobileProvisionCertificateInfo(
        index: 1,
        byteLength: 910,
        sha1: 'AA:BB',
        sha256: 'CC:DD',
        x509: X509CertificateInfo(
          subject: 'CN=Apple Development: MyTools, O=Example Team',
          issuer: 'CN=Example CA',
          serialNumber: '01:02',
          notBefore: null,
          notAfter: null,
        ),
      ),
    ],
    entitlements: const <String, Object?>{
      'application-identifier': 'ABCDE12345.com.example.mytools',
      'get-task-allow': false,
    },
    provisionsAllDevices: false,
    betaReportsActive: false,
  );
}

PlistDocumentInfo buildPlistInfo(String path) {
  return const PlistDocumentParser().parseXml('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
<key>CFBundleIdentifier</key>
<string>com.example.mytools</string>
</dict>
</plist>
''', filePath: path);
}

class _FakePlistParser implements PlistDocumentParsing {
  const _FakePlistParser(this.info);

  final PlistDocumentInfo info;

  @override
  Future<PlistDocumentInfo> parse(String path) async => info;
}
