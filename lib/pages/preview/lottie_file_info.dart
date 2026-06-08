import 'dart:io';

import '../../utils/path_utils.dart';
import '../../utils/time_utils.dart';

class LottieFileInfo {
  const LottieFileInfo({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.sizeInBytes,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  final int sizeInBytes;
}

class LottieFileCollector {
  const LottieFileCollector();

  Future<List<LottieFileInfo>> collectFromPaths(List<String> paths) async {
    final records = <LottieFileInfo>[];

    for (final path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final entityType = FileSystemEntity.typeSync(path);

      if (entityType == FileSystemEntityType.directory) {
        records.addAll(await _collectFromDirectory(path));
        continue;
      }

      if (_isSupportedLottiePath(path)) {
        final record = await _createRecord(path);

        if (record != null) {
          records.add(record);
        }
      }
    }

    records.sort(_compareByName);

    return records;
  }

  Future<List<LottieFileInfo>> _collectFromDirectory(
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      return <LottieFileInfo>[];
    }

    final entities = directory
        .listSync()
        .whereType<File>()
        .where((File file) => _isSupportedLottiePath(file.path))
        .toList(growable: false);
    final records = <LottieFileInfo>[];

    for (final file in entities) {
      final record = await _createRecord(file.path);

      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  Future<LottieFileInfo?> _createRecord(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    final stat = await file.stat();

    return LottieFileInfo(
      path: path,
      name: displayFileName(path),
      modifiedAt: stat.modified,
      sizeInBytes: stat.size,
    );
  }

  static int _compareByName(LottieFileInfo left, LottieFileInfo right) {
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }

  static bool _isSupportedLottiePath(String path) {
    return hasFileExtension(path, <String>['.json']);
  }
}

class LottieFileSummaryFormatter {
  const LottieFileSummaryFormatter();

  String formatSelectedSummary(List<LottieFileInfo> files) {
    return files
        .map(
          (LottieFileInfo file) => [
            'File: ${file.name}',
            'Size: ${formatFileSize(file.sizeInBytes)}',
            'Modified At: ${formatTimestamp(file.modifiedAt)}',
            'Path: ${file.path}',
          ].join('\n'),
        )
        .join('\n\n');
  }

  String formatTimestamp(DateTime value) {
    return formatDateTimeMinute(value);
  }

  String formatFileSize(int sizeInBytes) {
    return formatByteSize(sizeInBytes, compact: true);
  }
}
