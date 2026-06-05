import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/mobileprovision_profile_info.dart';

void main() {
  test('mobileprovision parser reads profile plist values', () {
    const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Name</key>
  <string>MyTools Dev Profile</string>
  <key>UUID</key>
  <string>11111111-2222-3333-4444-555555555555</string>
  <key>AppIDName</key>
  <string>MyTools</string>
  <key>TeamName</key>
  <string>Example Team</string>
  <key>TeamIdentifier</key>
  <array>
    <string>ABCDE12345</string>
  </array>
  <key>ApplicationIdentifierPrefix</key>
  <array>
    <string>ABCDE12345</string>
  </array>
  <key>CreationDate</key>
  <date>2026-01-01T00:00:00Z</date>
  <key>ExpirationDate</key>
  <date>2027-01-01T00:00:00Z</date>
  <key>TimeToLive</key>
  <integer>365</integer>
  <key>Platform</key>
  <array>
    <string>iOS</string>
  </array>
  <key>ProvisionedDevices</key>
  <array>
    <string>00008030-001122334455802E</string>
  </array>
  <key>DeveloperCertificates</key>
  <array>
    <data>Y2VydGlmaWNhdGUtb25l</data>
  </array>
  <key>Entitlements</key>
  <dict>
    <key>application-identifier</key>
    <string>ABCDE12345.com.example.mytools</string>
    <key>com.apple.developer.team-identifier</key>
    <string>ABCDE12345</string>
    <key>aps-environment</key>
    <string>development</string>
    <key>get-task-allow</key>
    <true/>
  </dict>
</dict>
</plist>
''';

    final info = const MobileProvisionProfileParser().parsePlist(
      plist,
      filePath: '/tmp/MyTools.mobileprovision',
    );

    expect(info.filePath, '/tmp/MyTools.mobileprovision');
    expect(info.name, 'MyTools Dev Profile');
    expect(info.uuid, '11111111-2222-3333-4444-555555555555');
    expect(info.teamName, 'Example Team');
    expect(info.teamIdentifiers, <String>['ABCDE12345']);
    expect(info.bundleIdentifier, 'com.example.mytools');
    expect(info.applicationIdentifier, 'ABCDE12345.com.example.mytools');
    expect(info.platforms, <String>['iOS']);
    expect(info.provisionedDevices, <String>['00008030-001122334455802E']);
    expect(info.certificates, hasLength(1));
    expect(info.certificates.single.byteLength, 15);
    expect(info.entitlements['aps-environment'], 'development');
    expect(info.entitlements['get-task-allow'], isTrue);
    expect(info.profileKindLabel, 'Development / Ad Hoc');
  });
}
