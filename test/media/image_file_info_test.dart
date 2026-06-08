import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:mytools/pages/media/image_file_info.dart';

void main() {
  test('image info parser reads png dimensions and alpha details', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'mytools_image_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final image = image_lib.Image(width: 2, height: 3, numChannels: 4);
    image.setPixelRgba(0, 0, 15, 118, 110, 255);
    image.setPixelRgba(1, 0, 15, 118, 110, 80);

    final file = File('${tempDir.path}/sample.png');
    await file.writeAsBytes(image_lib.encodePng(image));

    final info = await const ImageFileInfoParser().parse(file.path);

    expect(info.filePath, file.path);
    expect(info.fileName, 'sample.png');
    expect(info.format, 'PNG');
    expect(info.width, 2);
    expect(info.height, 3);
    expect(info.dimensionsText, '2 x 3 px');
    expect(info.fileSizeBytes, greaterThan(0));
    expect(info.fileSizeText, endsWith('B'));
    expect(info.hasAlphaChannel, isTrue);
    expect(info.hasTransparentPixels, isTrue);
    expect(info.alphaText, '有透明像素');
    expect(info.frameCountText, '单帧');
  });

  test('image info parser reports missing file clearly', () async {
    expect(
      () => const ImageFileInfoParser().parse('/tmp/mytools_missing_image.png'),
      throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          '文件不存在，请重新选择。',
        ),
      ),
    );
  });
}
