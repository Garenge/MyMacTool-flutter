import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/qr/qr_code_decode_source.dart';

void main() {
  test('qr decode source reads direct bytes and file bytes', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'mytools_qr_source_test_',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final file = File('${tempDirectory.path}/code.png');
    await file.writeAsBytes(<int>[1, 2, 3, 4]);

    final directSource = QrDecodeImageSource.bytes(
      'direct',
      Uint8List.fromList(<int>[9, 8]),
    );
    final fileSource = QrDecodeImageSource.path(file.path);

    expect(await directSource.readBytes(), <int>[9, 8]);
    expect(await fileSource.readBytes(), <int>[1, 2, 3, 4]);
  });

  test('qr decode source reports missing file clearly', () async {
    final source = QrDecodeImageSource.path('/tmp/not-exists-mytools-qr.png');

    expect(
      source.readBytes,
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          '剪贴板中的图片文件不存在。',
        ),
      ),
    );
  });

  test(
    'qr clipboard text path resolver accepts file uri and existing path',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'mytools_qr_path_test_',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final file = File('${tempDirectory.path}/code.png');
      await file.writeAsBytes(<int>[1]);

      expect(resolveQrClipboardTextPath(file.path), file.path);
      expect(resolveQrClipboardTextPath(file.uri.toString()), file.path);
      expect(
        resolveQrClipboardTextPath(' file://remote/share/code.png '),
        isNull,
      );
      expect(
        resolveQrClipboardTextPath('https://example.com/code.png'),
        isNull,
      );
      expect(resolveQrClipboardTextPath(''), isNull);
    },
  );

  test('looks like web url requires http scheme and host', () {
    expect(looksLikeWebUrl(' https://example.com/path '), isTrue);
    expect(looksLikeWebUrl('http://example.com/path'), isTrue);
    expect(looksLikeWebUrl('ftp://example.com/path'), isFalse);
    expect(looksLikeWebUrl('mailto:hello@example.com'), isFalse);
    expect(looksLikeWebUrl('/tmp/file.png'), isFalse);
  });
}
