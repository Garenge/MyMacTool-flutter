import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/mobileprovision_profile_info.dart';

void main() {
  const testCertificateBase64 =
      'MIIDjzCCAnegAwIBAgIUO5+I0x+UGHZH2/IeMPzodosIPH4wDQYJKoZIhvcNAQELBQAwVzELMAkGA1UEBhMCVVMxFTATBgNVBAoMDEV4YW1wbGUgVGVhbTEMMAoGA1UECwwDRGV2MSMwIQYDVQQDDBpBcHBsZSBEZXZlbG9wbWVudDogTXlUb29sczAeFw0yNjA2MDcxMDA1MDFaFw0yNzA2MDcxMDA1MDFaMFcxCzAJBgNVBAYTAlVTMRUwEwYDVQQKDAxFeGFtcGxlIFRlYW0xDDAKBgNVBAsMA0RldjEjMCEGA1UEAwwaQXBwbGUgRGV2ZWxvcG1lbnQ6IE15VG9vbHMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRVxB/lK1DERj2llmv0JDdZ/KBMrTU9zf9/3rH1gg7zDvZBFHn3RWf/DLuTodCcXjizjeGk/l3bxHAYszbXMZKc8WRyLTkwUWvDGMP3iXr/h6sLpkiM1KF0TKpMIBwtKBT6LyiSDZ4uDNx2E1X44QDt7YHrtYJO7WyKLtl7HuyHp0j1oeHR076frXzmg1F0mLe1Hn7psbahXsC4gGbrGTB9vNwF6c3OOguXQP0riG5PKhZNux+f0rI5VveBos3uVHP2yScf8ZIACxFEPrPWRIDlCQa6L4NCNCMqVJrbBUUb5v2U/CpH5DC4pi339NTPjZ7qVPi1yLYINd8z2FF9QVXAgMBAAGjUzBRMB0GA1UdDgQWBBQaJCiBKTXVrtD2ss8qrAD/nMJMzzAfBgNVHSMEGDAWgBQaJCiBKTXVrtD2ss8qrAD/nMJMzzAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBNieTr1dU5MhQMeGy+8HH6gDH0BSqtZwmMtI1a2c1Jt5KF6gChy49fsO+XMSWD2qvcbw8XPH5dsUwsA+zuB7vsRSoxS67/1iDd1OPtzHtzyEE0DtCEiUYhXEIyBQaOUCLPhP93fPTIMHu90fl+oOubwZHwErO2/fiaryb1YPY9T+G5EDZ/y3ShX2dN1i/8PGiU6XSFYoJv2diOaH2fLXoPs3gHxZsAsDYerxy5p5r6gb4Np6OgJCdmLCx206M0uaM7Zda1XcObLjbLmgPQruB9xkPy6U4Um3O5bHQp230EMml7Ij3LRk7iJbflZ7QcZZRiAynuezwRkF0FyWEQnU+D';

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
    expect(info.certificates.single.hasX509Info, isFalse);
    expect(info.entitlements['aps-environment'], 'development');
    expect(info.entitlements['get-task-allow'], isTrue);
    expect(info.profileKindLabel, 'Development / Ad Hoc');
  });

  test('mobileprovision parser reads x509 certificate metadata', () {
    final plist =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Name</key>
  <string>MyTools Dev Profile</string>
  <key>UUID</key>
  <string>11111111-2222-3333-4444-555555555555</string>
  <key>TeamIdentifier</key>
  <array>
    <string>ABCDE12345</string>
  </array>
  <key>DeveloperCertificates</key>
  <array>
    <data>$testCertificateBase64</data>
  </array>
  <key>Entitlements</key>
  <dict>
    <key>application-identifier</key>
    <string>ABCDE12345.com.example.mytools</string>
  </dict>
</dict>
</plist>
''';

    final info = const MobileProvisionProfileParser().parsePlist(plist);
    final certificate = info.certificates.single;

    expect(certificate.hasX509Info, isTrue);
    expect(
      certificate.x509?.subject,
      contains('CN=Apple Development: MyTools'),
    );
    expect(certificate.x509?.issuer, contains('O=Example Team'));
    expect(certificate.x509?.serialNumber, isNotEmpty);
    expect(certificate.notBefore, DateTime.utc(2026, 6, 7, 10, 5, 1));
    expect(certificate.notAfter, DateTime.utc(2027, 6, 7, 10, 5, 1));
  });
}
