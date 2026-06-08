import 'dart:io';

import 'package:archive/archive_io.dart';

import '../../utils/path_utils.dart';

abstract class IpaArchiveExtracting {
  Future<Directory> extractToTempDirectory(File ipaFile);
}

class IpaArchiveExtractor implements IpaArchiveExtracting {
  const IpaArchiveExtractor();

  @override
  Future<Directory> extractToTempDirectory(File ipaFile) async {
    final tempRoot = await Directory.systemTemp.createTemp('mytools_ipa_');

    try {
      final baseName = stripFileExtension(displayFileName(ipaFile.path));
      final outputDirectory = Directory('${tempRoot.path}/$baseName');
      await outputDirectory.create(recursive: true);

      final inputStream = InputFileStream(ipaFile.path);

      try {
        final archive = ZipDecoder().decodeStream(inputStream);
        await _extractArchive(archive, outputDirectory);
      } finally {
        await inputStream.close();
      }

      return outputDirectory;
    } catch (_) {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }

      rethrow;
    }
  }

  Future<void> _extractArchive(
    Archive archive,
    Directory outputDirectory,
  ) async {
    for (final file in archive) {
      final outputPath = _safeOutputPath(
        outputDirectory.path,
        file.name,
        isSymbolicLink: file.isSymbolicLink,
      );

      if (file.isFile) {
        await _writeFile(file, outputPath);
        continue;
      }

      await Directory(outputPath).create(recursive: true);
    }
  }

  Future<void> _writeFile(ArchiveFile archiveFile, String outputPath) async {
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);

    final outputStream = OutputFileStream(outputFile.path);

    try {
      archiveFile.writeContent(outputStream);
    } finally {
      await outputStream.close();
    }
  }

  String _safeOutputPath(
    String outputDirectoryPath,
    String archivePath, {
    required bool isSymbolicLink,
  }) {
    if (isSymbolicLink) {
      throw const FormatException('IPA 包含不安全的链接路径，已停止解压。');
    }

    final segments = _safeIpaArchiveSegments(archivePath);

    return <String>[
      outputDirectoryPath,
      ...segments,
    ].join(Platform.pathSeparator);
  }

  List<String> _safeIpaArchiveSegments(String archivePath) {
    try {
      return safeArchivePathSegments(archivePath);
    } on FormatException catch (error) {
      if (error.message.contains('绝对路径')) {
        throw const FormatException('IPA 包含不安全的绝对路径，已停止解压。');
      }

      if (error.message.contains('相对路径')) {
        throw const FormatException('IPA 包含不安全的相对路径，已停止解压。');
      }

      rethrow;
    }
  }
}
