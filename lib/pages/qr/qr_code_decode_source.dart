import 'dart:io';
import 'dart:typed_data';

class QrDecodeImageSource {
  const QrDecodeImageSource._({
    required this.label,
    required this.bytes,
    required this.path,
  });

  factory QrDecodeImageSource.bytes(String label, Uint8List bytes) {
    return QrDecodeImageSource._(label: label, bytes: bytes, path: null);
  }

  factory QrDecodeImageSource.path(String path) {
    return QrDecodeImageSource._(label: path, bytes: null, path: path);
  }

  final String label;
  final Uint8List? bytes;
  final String? path;

  Future<Uint8List> readBytes() async {
    final directBytes = bytes;

    if (directBytes != null) {
      return directBytes;
    }

    final filePath = path;

    if (filePath == null || !File(filePath).existsSync()) {
      throw const FormatException('剪贴板中的图片文件不存在。');
    }

    return File(filePath).readAsBytes();
  }
}

String? resolveQrClipboardTextPath(String? text) {
  final value = text?.trim();

  if (value == null || value.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(value);

  if (uri != null && uri.isScheme('file')) {
    try {
      return uri.toFilePath();
    } on UnsupportedError {
      return null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  if (File(value).existsSync()) {
    return value;
  }

  return null;
}

bool looksLikeWebUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.isScheme('http') || uri.isScheme('https')) &&
      uri.host.isNotEmpty;
}
