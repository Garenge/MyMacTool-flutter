import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/mobile/plist_document_info.dart';

void main() {
  test('plist parser reads xml plist files directly', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'mytools_plist_direct_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final file = File('${tempDir.path}/Info.plist');
    await file.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.example.mytools</string>
</dict>
</plist>
''');

    final info = await const PlistDocumentParser().parse(file.path);

    expect(info.filePath, file.path);
    expect(info.itemCount, 2);
    expect(info.root.children.single.valueText, 'com.example.mytools');
  });

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
