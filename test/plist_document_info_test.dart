import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/plist_document_info.dart';

void main() {
  test('plist parser reads nested xml plist nodes', () {
    const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.example.mytools</string>
  <key>CFBundleVersion</key>
  <integer>42</integer>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
  </array>
  <key>Features</key>
  <dict>
    <key>Enabled</key>
    <true/>
    <key>Ratio</key>
    <real>1.5</real>
  </dict>
</dict>
</plist>
''';

    final info = const PlistDocumentParser().parseXml(
      plist,
      filePath: '/tmp/Info.plist',
    );

    expect(info.filePath, '/tmp/Info.plist');
    expect(info.root.type, PlistNodeType.dict);
    expect(info.itemCount, 9);
    expect(info.root.children.first.path, r'$.CFBundleIdentifier');
    expect(info.root.children.first.valueText, 'com.example.mytools');

    final orientations = info.root.children[2];
    expect(orientations.type, PlistNodeType.array);
    expect(
      orientations.children.first.path,
      r'$.UISupportedInterfaceOrientations[0]',
    );
    expect(
      orientations.children.first.valueText,
      'UIInterfaceOrientationPortrait',
    );

    final features = info.root.children[3];
    expect(features.children.first.type, PlistNodeType.boolean);
    expect(features.children.first.valueText, 'true');
    expect(features.children.last.type, PlistNodeType.real);
    expect(features.children.last.valueText, '1.5');
  });
}
