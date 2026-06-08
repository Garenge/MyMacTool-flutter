import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/utils/path_utils.dart';

void main() {
  test('display file name handles platform separators', () {
    expect(displayFileName('/tmp/MyTools/sample.png'), 'sample.png');
    expect(
      displayFileName(r'C:\Users\garenge\Downloads\sample.png'),
      'sample.png',
    );
    expect(displayFileName(r'\\server\share\sample.ipa'), 'sample.ipa');
  });

  test('display file name handles root and relative paths', () {
    expect(displayFileName('sample.png'), 'sample.png');
    expect(displayFileName('/'), '/');
    expect(displayFileName(r'C:\'), 'C:');
    expect(displayFileName(r'\\server\share\'), 'share');
  });

  test('display file name handles empty and trailing separator paths', () {
    expect(displayFileName(''), '');
    expect(displayFileName('', emptyPlaceholder: '-'), '-');
    expect(displayFileName('/tmp/MyTools/sample.png/'), 'sample.png');
  });

  test('strip file extension only removes final extension', () {
    expect(stripFileExtension('Sample.ipa'), 'Sample');
    expect(stripFileExtension('Archive.v1.ipa'), 'Archive.v1');
    expect(stripFileExtension('.env'), '.env');
    expect(stripFileExtension('README'), 'README');
  });

  test('has file extension handles case and optional leading dot', () {
    expect(hasFileExtension('Info.PLIST', <String>['.plist']), isTrue);
    expect(
      hasFileExtension('App.mobileprovision', <String>['mobileprovision']),
      isTrue,
    );
    expect(
      hasFileExtension('App.provisionprofile', <String>[
        '.mobileprovision',
        '.provisionprofile',
      ]),
      isTrue,
    );
    expect(hasFileExtension('notes.txt', <String>['.plist']), isFalse);
  });

  test('safe archive path segments accepts relative archive paths', () {
    expect(safeArchivePathSegments('Payload/Sample.app/Info.plist'), <String>[
      'Payload',
      'Sample.app',
      'Info.plist',
    ]);
    expect(safeArchivePathSegments(r'Payload\Sample.app\Info.plist'), <String>[
      'Payload',
      'Sample.app',
      'Info.plist',
    ]);
    expect(
      safeArchivePathSegments('./Payload//Sample.app/./Info.plist'),
      <String>['Payload', 'Sample.app', 'Info.plist'],
    );
  });

  test('safe archive path segments rejects unsafe paths', () {
    const unsafePaths = <String>[
      '',
      '../escape.txt',
      'Payload/../escape.txt',
      '/tmp/escape.txt',
      '//server/share/escape.txt',
      r'C:\escape.txt',
      'Payload/\x00/Info.plist',
    ];

    for (final path in unsafePaths) {
      expect(
        () => safeArchivePathSegments(path),
        throwsA(isA<FormatException>()),
        reason: path,
      );
    }
  });

  test('format byte size supports readable and compact styles', () {
    expect(formatByteSize(null), '-');
    expect(formatByteSize(-1), '-');
    expect(formatByteSize(12), '12 B');
    expect(formatByteSize(12, compact: true), '12B');
    expect(formatByteSize(1536), '1.5 KB');
    expect(formatByteSize(1536, compact: true), '1.5KB');
    expect(formatByteSize(2 * 1024 * 1024), '2.00 MB');
    expect(formatByteSize(2 * 1024 * 1024, compact: true), '2.0MB');
    expect(formatByteSize(3 * 1024 * 1024 * 1024), '3.00 GB');
  });
}
