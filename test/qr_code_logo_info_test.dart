import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:mytools/pages/qr_code_logo_info.dart';

void main() {
  test('qr logo loader reads image dimensions and file name', () async {
    final tempDir = await Directory.systemTemp.createTemp('mytools_qr_logo_');
    addTearDown(() => tempDir.delete(recursive: true));

    final image = image_lib.Image(width: 8, height: 6);
    image_lib.fill(image, color: image_lib.ColorRgb8(15, 118, 110));
    final file = File('${tempDir.path}/brand_logo.png');
    await file.writeAsBytes(image_lib.encodePng(image));

    final logo = await const QrCodeLogoLoader().load(file.path);

    expect(logo.filePath, file.path);
    expect(logo.fileName, 'brand_logo.png');
    expect(logo.sizeLabel, '8x6');
    expect(logo.bytes, isNotEmpty);
  });

  test('qr logo loader rejects invalid image files', () async {
    final tempDir = await Directory.systemTemp.createTemp('mytools_qr_logo_');
    addTearDown(() => tempDir.delete(recursive: true));

    final file = File('${tempDir.path}/broken.png');
    await file.writeAsString('not an image');

    expect(
      () => const QrCodeLogoLoader().load(file.path),
      throwsA(isA<FormatException>()),
    );
  });
}
