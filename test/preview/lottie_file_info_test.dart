import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/preview/lottie_file_info.dart';

void main() {
  test(
    'lottie collector reads json files from paths and directories',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'mytools_lottie_test_',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final firstFile = File('${tempDirectory.path}/zeta.json');
      final secondFile = File('${tempDirectory.path}/alpha.json');
      final ignoredFile = File('${tempDirectory.path}/notes.txt');
      await firstFile.writeAsString('{"v":"5.7.0","layers":[]}');
      await secondFile.writeAsString('{"v":"5.7.0","layers":[]}');
      await ignoredFile.writeAsString('ignore me');

      final records = await const LottieFileCollector().collectFromPaths([
        tempDirectory.path,
        ignoredFile.path,
        '',
      ]);

      expect(records.map((record) => record.name), ['alpha.json', 'zeta.json']);
      expect(records.every((record) => record.path.endsWith('.json')), isTrue);
      expect(records.every((record) => record.sizeInBytes > 0), isTrue);
    },
  );

  test('lottie summary formatter formats metadata for copy action', () {
    const formatter = LottieFileSummaryFormatter();
    final summary = formatter.formatSelectedSummary([
      LottieFileInfo(
        path: '/tmp/alpha.json',
        name: 'alpha.json',
        modifiedAt: DateTime(2026, 6, 7, 10, 5),
        sizeInBytes: 1536,
      ),
    ]);

    expect(formatter.formatFileSize(12), '12B');
    expect(formatter.formatFileSize(1536), '1.5KB');
    expect(formatter.formatFileSize(2 * 1024 * 1024), '2.0MB');
    expect(
      formatter.formatTimestamp(DateTime(2026, 6, 7, 10, 5)),
      '2026-06-07 10:05',
    );
    expect(summary, contains('File: alpha.json'));
    expect(summary, contains('Size: 1.5KB'));
    expect(summary, contains('Modified At: 2026-06-07 10:05'));
    expect(summary, contains('Path: /tmp/alpha.json'));
  });
}
