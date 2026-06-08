import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/mobile/ipa_archive_extractor.dart';
import 'package:mytools/utils/path_utils.dart';

void main() {
  test('ipa archive extractor writes valid payload files', () async {
    final tempDir = await _createTempDir('mytools_ipa_extract_valid_');
    final ipaFile = File('${tempDir.path}/Sample.ipa');
    await _writeIpa(ipaFile, <ArchiveFile>[
      ArchiveFile.string('Payload/Sample.app/Info.plist', '<plist />'),
    ]);

    final outputDirectory = await const IpaArchiveExtractor()
        .extractToTempDirectory(ipaFile);
    addTearDown(() async {
      final tempRoot = outputDirectory.parent;

      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final infoPlist = File(
      '${outputDirectory.path}/Payload/Sample.app/Info.plist',
    );

    expect(infoPlist.existsSync(), isTrue);
    expect(await infoPlist.readAsString(), '<plist />');
  });

  test('ipa archive extractor rejects zip slip paths', () async {
    final tempDir = await _createTempDir('mytools_ipa_extract_slip_');
    final ipaFile = File('${tempDir.path}/Unsafe.ipa');
    final escapedFile = File('${tempDir.path}/escape.txt');
    await _writeIpa(ipaFile, <ArchiveFile>[
      ArchiveFile.string('../escape.txt', 'unsafe'),
    ]);

    await expectLater(
      const IpaArchiveExtractor().extractToTempDirectory(ipaFile),
      throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          contains('不安全的相对路径'),
        ),
      ),
    );
    expect(escapedFile.existsSync(), isFalse);
  });

  test('ipa archive extractor cleans temp directory on failure', () async {
    final tempDir = await _createTempDir('mytools_ipa_extract_cleanup_');
    final uniqueName = 'UnsafeCleanup${DateTime.now().microsecondsSinceEpoch}';
    final ipaFile = File('${tempDir.path}/$uniqueName.ipa');
    await _writeIpa(ipaFile, <ArchiveFile>[
      ArchiveFile.string('../escape.txt', 'unsafe'),
    ]);

    await expectLater(
      const IpaArchiveExtractor().extractToTempDirectory(ipaFile),
      throwsA(isA<FormatException>()),
    );

    expect(_findIpaExtractionDirs(uniqueName), isEmpty);
  });

  test('ipa archive extractor rejects absolute paths', () async {
    final tempDir = await _createTempDir('mytools_ipa_extract_absolute_');
    final ipaFile = File('${tempDir.path}/Unsafe.ipa');
    await _writeIpa(ipaFile, <ArchiveFile>[
      ArchiveFile.string('/tmp/escape.txt', 'unsafe'),
    ]);

    await expectLater(
      const IpaArchiveExtractor().extractToTempDirectory(ipaFile),
      throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          contains('不安全的绝对路径'),
        ),
      ),
    );
  });

  test('ipa archive extractor rejects windows drive paths', () async {
    final tempDir = await _createTempDir('mytools_ipa_extract_drive_');
    final ipaFile = File('${tempDir.path}/Unsafe.ipa');
    await _writeIpa(ipaFile, <ArchiveFile>[
      ArchiveFile.string(r'C:escape.txt', 'unsafe'),
    ]);

    await expectLater(
      const IpaArchiveExtractor().extractToTempDirectory(ipaFile),
      throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          contains('不安全的绝对路径'),
        ),
      ),
    );
  });
}

Future<Directory> _createTempDir(String prefix) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  addTearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  return tempDir;
}

Future<void> _writeIpa(File file, List<ArchiveFile> files) async {
  final archive = Archive();

  for (final archiveFile in files) {
    archive.addFile(archiveFile);
  }

  await file.writeAsBytes(ZipEncoder().encode(archive));
}

List<Directory> _findIpaExtractionDirs(String outputDirectoryName) {
  return Directory.systemTemp
      .listSync()
      .whereType<Directory>()
      .where(
        (Directory directory) =>
            displayFileName(directory.path).startsWith('mytools_ipa_') &&
            Directory('${directory.path}/$outputDirectoryName').existsSync(),
      )
      .toList(growable: false);
}
