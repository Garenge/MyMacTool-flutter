/// Returns the display name for POSIX, Windows, or archive-style paths.
String displayFileName(String path, {String emptyPlaceholder = ''}) {
  if (path.isEmpty) {
    return emptyPlaceholder;
  }

  final normalized = path.replaceAll('\\', '/');
  final trimmed = normalized.replaceFirst(RegExp(r'/+$'), '');

  if (trimmed.isEmpty) {
    return normalized;
  }

  final separatorIndex = trimmed.lastIndexOf('/');

  if (separatorIndex < 0) {
    return trimmed;
  }

  return trimmed.substring(separatorIndex + 1);
}

/// Returns the path without its final file extension.
String stripFileExtension(String path) {
  final dotIndex = path.lastIndexOf('.');

  if (dotIndex <= 0) {
    return path;
  }

  return path.substring(0, dotIndex);
}

/// Returns true when [path] has one of the provided extensions.
bool hasFileExtension(String path, Iterable<String> extensions) {
  final lowerPath = path.toLowerCase();

  return extensions.any((String extension) {
    final normalizedExtension = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';

    return lowerPath.endsWith(normalizedExtension);
  });
}

/// Splits an archive entry path into safe relative path segments.
List<String> safeArchivePathSegments(String archivePath) {
  final normalized = archivePath.replaceAll('\\', '/');

  if (normalized.isEmpty ||
      normalized.contains('\x00') ||
      normalized.startsWith('/') ||
      normalized.startsWith('//') ||
      RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    throw const FormatException('归档包含不安全的绝对路径。');
  }

  final segments = normalized
      .split('/')
      .where((String segment) => segment.isNotEmpty && segment != '.')
      .toList(growable: false);

  if (segments.isEmpty || segments.any((String segment) => segment == '..')) {
    throw const FormatException('归档包含不安全的相对路径。');
  }

  return segments;
}

/// Formats a byte count with binary units.
String formatByteSize(
  int? bytes, {
  String emptyPlaceholder = '-',
  bool compact = false,
}) {
  final value = bytes;

  if (value == null || value < 0) {
    return emptyPlaceholder;
  }

  const units = <String>['B', 'KB', 'MB', 'GB'];
  var unitIndex = 0;
  var scaledValue = value.toDouble();

  while (scaledValue >= 1024 && unitIndex < units.length - 1) {
    scaledValue /= 1024;
    unitIndex += 1;
  }

  final separator = compact ? '' : ' ';

  if (unitIndex == 0) {
    return '$value$separator${units[unitIndex]}';
  }

  final fractionDigits = compact || unitIndex == 1 ? 1 : 2;
  return '${scaledValue.toStringAsFixed(fractionDigits)}'
      '$separator${units[unitIndex]}';
}
