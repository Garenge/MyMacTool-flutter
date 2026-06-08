import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/qr/qr_code_image_decoder.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('qr image decoder reads generated qr png bytes', () async {
    final bytes = await _buildQrPngBytes('Hello MyTools');

    final decoded = const QrCodeImageDecoder().decode(bytes);

    expect(decoded, 'Hello MyTools');
  });

  test('qr image decoder rejects invalid image bytes clearly', () {
    expect(
      () => const QrCodeImageDecoder().decode(Uint8List.fromList(<int>[1, 2])),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          '无法读取图片，请选择 PNG、JPG、WebP 等常见图片格式。',
        ),
      ),
    );
  });
}

Future<Uint8List> _buildQrPngBytes(String data) async {
  const size = 240.0;
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    gapless: false,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  painter.paint(canvas, const Size.square(size));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  if (bytes == null) {
    throw StateError('Failed to generate qr test image.');
  }

  return bytes.buffer.asUint8List();
}
