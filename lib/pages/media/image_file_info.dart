import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../../utils/path_utils.dart';

class ImageFileInfo {
  const ImageFileInfo({
    required this.filePath,
    required this.fileName,
    required this.format,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.hasAlphaChannel,
    required this.hasTransparentPixels,
    required this.frameCount,
  });

  final String filePath;
  final String fileName;
  final String format;
  final int width;
  final int height;
  final int fileSizeBytes;
  final bool hasAlphaChannel;
  final bool hasTransparentPixels;
  final int frameCount;

  String get dimensionsText => '$width x $height px';

  String get fileSizeText {
    return formatByteSize(fileSizeBytes);
  }

  String get alphaText {
    if (!hasAlphaChannel) {
      return '无透明通道';
    }

    return hasTransparentPixels ? '有透明像素' : '有透明通道，无透明像素';
  }

  String get frameCountText {
    if (frameCount <= 1) {
      return '单帧';
    }

    return '$frameCount 帧';
  }
}

class ImageFileInfoParser {
  const ImageFileInfoParser();

  Future<ImageFileInfo> parse(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw const FormatException('文件不存在，请重新选择。');
    }

    final bytes = await file.readAsBytes();
    final decoder = image_lib.findDecoderForData(bytes);

    if (decoder == null) {
      throw const FormatException('无法识别图片格式，请选择 PNG、JPG、WebP、GIF 等图片文件。');
    }

    final image = decoder.decode(Uint8List.fromList(bytes));

    if (image == null) {
      throw const FormatException('图片解析失败，请确认文件没有损坏。');
    }

    return ImageFileInfo(
      filePath: path,
      fileName: displayFileName(path),
      format: decoder.format.name.toUpperCase(),
      width: image.width,
      height: image.height,
      fileSizeBytes: bytes.length,
      hasAlphaChannel: image.hasAlpha,
      hasTransparentPixels: _hasTransparentPixels(image),
      frameCount: image.numFrames,
    );
  }

  bool _hasTransparentPixels(image_lib.Image image) {
    if (!image.hasAlpha) {
      return false;
    }

    for (final pixel in image) {
      if (pixel.aNormalized < 1) {
        return true;
      }
    }

    return false;
  }
}
