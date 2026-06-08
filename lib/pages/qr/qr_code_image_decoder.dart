import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;
import 'package:zxing2/qrcode.dart';

class QrCodeImageDecoder {
  const QrCodeImageDecoder();

  String decode(Uint8List bytes) {
    late final image_lib.Image? image;

    try {
      image = image_lib.decodeImage(bytes);
    } catch (error) {
      throw const FormatException('无法读取图片，请选择 PNG、JPG、WebP 等常见图片格式。');
    }

    if (image == null) {
      throw const FormatException('无法读取图片，请选择 PNG、JPG、WebP 等常见图片格式。');
    }

    try {
      final source = RGBLuminanceSource(
        image.width,
        image.height,
        _buildArgbPixels(image),
      );
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final result = QRCodeReader().decode(bitmap);

      if (result.text.trim().isEmpty) {
        throw const FormatException('图片中没有识别到二维码内容。');
      }

      return result.text;
    } on ReaderException {
      throw const FormatException('图片中没有识别到二维码内容。');
    } on FormatException {
      rethrow;
    } catch (error) {
      throw const FormatException('二维码解析失败，请换一张更清晰的图片。');
    }
  }

  Int32List _buildArgbPixels(image_lib.Image image) {
    final pixels = Int32List(image.width * image.height);
    var index = 0;

    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.aNormalized;
        final red = _blendOnWhite(pixel.r.toInt(), alpha);
        final green = _blendOnWhite(pixel.g.toInt(), alpha);
        final blue = _blendOnWhite(pixel.b.toInt(), alpha);

        pixels[index] = 0xFF000000 | (red << 16) | (green << 8) | blue;
        index += 1;
      }
    }

    return pixels;
  }

  int _blendOnWhite(int channel, num alpha) {
    return (channel * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
  }
}
