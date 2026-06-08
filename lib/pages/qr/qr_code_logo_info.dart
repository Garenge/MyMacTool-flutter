import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../../utils/path_utils.dart';

class QrCodeLogoInfo {
  const QrCodeLogoInfo({
    required this.filePath,
    required this.bytes,
    required this.width,
    required this.height,
  });

  final String filePath;
  final Uint8List bytes;
  final int width;
  final int height;

  String get fileName => displayFileName(filePath);

  String get sizeLabel => '${width}x$height';
}

class QrCodeLogoLoader {
  const QrCodeLogoLoader();

  Future<QrCodeLogoInfo> load(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw const FormatException('Logo 图片不存在，请重新选择。');
    }

    final bytes = await file.readAsBytes();
    final decodedImage = image_lib.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FormatException('无法读取 Logo 图片，请选择 PNG、JPG、WebP 等常见图片格式。');
    }

    return QrCodeLogoInfo(
      filePath: path,
      bytes: bytes,
      width: decodedImage.width,
      height: decodedImage.height,
    );
  }
}
