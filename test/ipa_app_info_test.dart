import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/ipa_app_info.dart';
import 'package:mytools/pages/mobileprovision_profile_info.dart';

void main() {
  test('ipa app info reports embedded profile bundle id match', () {
    final info = IpaAppInfo(
      appName: 'MyTools',
      bundleIdentifier: 'com.example.mytools',
      shortVersion: '1.0.0',
      buildNumber: '42',
      minimumOsVersion: '15.0',
      executableName: 'MyTools',
      infoPlistPath: '/tmp/Payload/MyTools.app/Info.plist',
      embeddedProfilePath: '/tmp/Payload/MyTools.app/embedded.mobileprovision',
      embeddedProfileInfo: MobileProvisionProfileInfo(
        filePath: '/tmp/Payload/MyTools.app/embedded.mobileprovision',
        name: 'MyTools Profile',
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
        certificates: const <MobileProvisionCertificateInfo>[],
        entitlements: const <String, Object?>{},
        provisionsAllDevices: false,
        betaReportsActive: true,
      ),
      embeddedProfileError: '',
    );

    expect(info.hasAnyValue, isTrue);
    expect(info.hasEmbeddedProfile, isTrue);
    expect(info.hasEmbeddedProfileInfo, isTrue);
    expect(info.isBundleIdentifierMatched, isTrue);
  });
}
