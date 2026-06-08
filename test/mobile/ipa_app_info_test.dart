import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/mobile/ipa_app_info.dart';
import 'package:mytools/pages/mobile/ipa_unpack_page.dart';
import 'package:mytools/pages/mobile/mobileprovision_profile_diagnostics.dart';
import 'package:mytools/pages/mobile/mobileprovision_profile_info.dart';

void main() {
  MobileProvisionProfileInfo buildProfileInfo({
    String bundleIdentifier = 'com.example.mytools',
    String applicationIdentifier = 'ABCDE12345.com.example.mytools',
    DateTime? expirationDate,
    Map<String, Object?> entitlements = const <String, Object?>{},
  }) {
    return MobileProvisionProfileInfo(
      filePath: '/tmp/Payload/MyTools.app/embedded.mobileprovision',
      name: 'MyTools Profile',
      uuid: '11111111-2222-3333-4444-555555555555',
      appIdName: 'MyTools',
      teamName: 'Example Team',
      teamIdentifiers: const <String>['ABCDE12345'],
      appIdentifierPrefixes: const <String>['ABCDE12345'],
      applicationIdentifier: applicationIdentifier,
      bundleIdentifier: bundleIdentifier,
      creationDate: DateTime.utc(2026),
      expirationDate: expirationDate ?? DateTime.utc(2027),
      timeToLive: 365,
      platforms: const <String>['iOS'],
      provisionedDevices: const <String>[],
      certificates: const <MobileProvisionCertificateInfo>[],
      entitlements: entitlements,
      provisionsAllDevices: false,
      betaReportsActive: true,
    );
  }

  IpaAppInfo buildAppInfo({
    String bundleIdentifier = 'com.example.mytools',
    MobileProvisionProfileInfo? profileInfo,
  }) {
    return IpaAppInfo(
      appName: 'MyTools',
      bundleIdentifier: bundleIdentifier,
      shortVersion: '1.0.0',
      buildNumber: '42',
      minimumOsVersion: '15.0',
      executableName: 'MyTools',
      infoPlistPath: '/tmp/Payload/MyTools.app/Info.plist',
      embeddedProfilePath: profileInfo?.filePath ?? '',
      embeddedProfileInfo: profileInfo,
      embeddedProfileError: '',
    );
  }

  test('ipa app info reports embedded profile bundle id match', () {
    final info = buildAppInfo(profileInfo: buildProfileInfo());

    expect(info.hasAnyValue, isTrue);
    expect(info.hasEmbeddedProfile, isTrue);
    expect(info.hasEmbeddedProfileInfo, isTrue);
    expect(info.isBundleIdentifierMatched, isTrue);
    expect(info.bundleIdentifierMatch.kind, BundleIdentifierMatchKind.exact);
  });

  test('ipa parse status keeps parsed result when auto open fails', () {
    final info = buildAppInfo();

    expect(
      formatIpaParseStatusText(info, didOpenOutputDirectory: false),
      '解析完成，已读取应用信息，自动打开输出目录失败，可手动打开。',
    );
    expect(
      formatIpaParseStatusText(null, didOpenOutputDirectory: true),
      '解析完成，未读取到 Info.plist，已自动打开输出目录。',
    );
  });

  test('ipa app info treats wildcard profile bundle id as matched', () {
    final info = buildAppInfo(
      profileInfo: buildProfileInfo(
        bundleIdentifier: 'com.example.*',
        applicationIdentifier: 'ABCDE12345.com.example.*',
      ),
    );

    expect(info.isBundleIdentifierMatched, isTrue);
    expect(info.bundleIdentifierMatch.kind, BundleIdentifierMatchKind.wildcard);
  });

  test('ipa app info reports embedded profile diagnostics', () {
    final info = buildAppInfo(
      profileInfo: buildProfileInfo(
        bundleIdentifier: 'com.other.app',
        applicationIdentifier: 'ABCDE12345.com.other.app',
        expirationDate: DateTime.utc(2025),
        entitlements: const <String, Object?>{
          'application-identifier': 'ABCDE12345.com.other.app',
          'com.apple.developer.team-identifier': 'OTHERTEAM',
          'get-task-allow': true,
          'aps-environment': 'development',
          'com.apple.developer.associated-domains': <String>[
            'applinks:example.com',
          ],
        },
      ),
    );
    final diagnostics = info.embeddedProfileDiagnostics;

    expect(info.isBundleIdentifierMatched, isFalse);
    expect(diagnostics, isNotNull);
    expect(diagnostics!.riskCount, greaterThanOrEqualTo(3));
    expect(diagnostics.warningCount, greaterThanOrEqualTo(2));
    expect(diagnostics.summaryText, contains('风险'));
    expect(
      diagnostics.items.map((ProfileDiagnosticItem item) => item.title),
      containsAll(<String>[
        'Bundle ID',
        '有效期',
        'Team ID',
        '调试权限',
        '推送环境',
        'Associated Domains',
      ]),
    );
  });

  test('profile diagnostics summarizes healthy profile', () {
    final diagnostics = MobileProvisionProfileDiagnostics.evaluate(
      buildProfileInfo(
        entitlements: const <String, Object?>{
          'application-identifier': 'ABCDE12345.com.example.mytools',
          'com.apple.developer.team-identifier': 'ABCDE12345',
          'get-task-allow': false,
        },
      ),
      appBundleIdentifier: 'com.example.mytools',
      now: DateTime.utc(2026, 1, 1),
    );

    expect(diagnostics.riskCount, 0);
    expect(diagnostics.warningCount, 0);
    expect(diagnostics.summaryText, '未发现明显签名风险');
    expect(
      diagnostics.bundleIdentifierMatch.kind,
      BundleIdentifierMatchKind.exact,
    );
  });
}
