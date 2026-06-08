import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/media/ffprobe_runtime.dart';
import 'package:mytools/pages/media/media_file_info.dart';

void main() {
  test('media parser reads ffprobe json streams and format', () {
    const jsonText = '''
{
  "streams": [
    {
      "index": 0,
      "codec_name": "h264",
      "codec_long_name": "H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10",
      "profile": "High",
      "codec_type": "video",
      "width": 1920,
      "height": 1080,
      "pix_fmt": "yuv420p",
      "avg_frame_rate": "30000/1001",
      "duration": "12.345000",
      "bit_rate": "4000000",
      "tags": {
        "language": "und"
      }
    },
    {
      "index": 1,
      "codec_name": "aac",
      "codec_long_name": "AAC (Advanced Audio Coding)",
      "profile": "LC",
      "codec_type": "audio",
      "sample_rate": "48000",
      "channels": 2,
      "channel_layout": "stereo",
      "duration": "12.300000",
      "bit_rate": "128000",
      "tags": {
        "language": "eng"
      }
    }
  ],
  "format": {
    "filename": "sample.mp4",
    "nb_streams": 2,
    "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
    "format_long_name": "QuickTime / MOV",
    "duration": "12.345000",
    "size": "12345678",
    "bit_rate": "4123456",
    "tags": {
      "major_brand": "isom"
    }
  }
}
''';

    final info = const MediaFileInfoParser().parseJson(
      jsonText,
      filePath: '/tmp/sample.mp4',
    );

    expect(info.fileName, 'sample.mp4');
    expect(info.displayFormat, 'QuickTime / MOV');
    expect(info.durationText, '0:12.345');
    expect(info.fileSizeText, '11.77 MB');
    expect(info.bitRateText, '4.12 Mbps');
    expect(info.videoStreams, hasLength(1));
    expect(info.audioStreams, hasLength(1));
    expect(info.metadata['major_brand'], 'isom');

    final video = info.videoStreams.single;
    expect(video.codecName, 'h264');
    expect(video.resolutionText, '1920 x 1080');
    expect(video.frameRateText, '29.97 fps');
    expect(video.bitRateText, '4 Mbps');
    expect(video.languageText, 'und');

    final audio = info.audioStreams.single;
    expect(audio.codecName, 'aac');
    expect(audio.sampleRateText, '48 kHz');
    expect(audio.channelsText, '2 ch · stereo');
    expect(audio.bitRateText, '128 kbps');
    expect(audio.languageText, 'eng');
  });

  test('media parser reports missing file clearly', () async {
    expect(
      () => const MediaFileInfoParser().parse('/tmp/mytools_missing_media.mp4'),
      throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          '文件不存在，请重新选择。',
        ),
      ),
    );
  });

  test('media parser resolves runtime and runs ffprobe executable', () async {
    final tempDir = await _createTempDir('mytools_ffprobe_parse_');
    final mediaFile = File('${tempDir.path}/sample.mp4');
    await mediaFile.writeAsBytes(<int>[0]);

    final fakeFfprobe = File('${tempDir.path}/ffprobe');
    await _writeExecutable(
      fakeFfprobe,
      <String>[
        '#!/bin/sh',
        'if [ "\$1" = "-version" ]; then',
        '  echo "ffprobe test"',
        '  exit 0',
        'fi',
        "cat <<'JSON'",
        _fakeFfprobeJson.trim(),
        'JSON',
      ].join('\n'),
    );

    final runtime = _TestFfprobeRuntime(
      managedPath: '${tempDir.path}/managed/ffprobe',
      bundlePath: '${tempDir.path}/bundle/ffprobe',
      candidates: <String>[fakeFfprobe.path],
    );

    final info = await MediaFileInfoParser(
      runtime: runtime,
    ).parse(mediaFile.path);

    expect(info.fileName, 'sample.mp4');
    expect(info.displayFormat, 'QuickTime / MOV');
    expect(info.durationText, '0:01');
    expect(info.videoStreams.single.resolutionText, '160 x 90');
    expect(info.audioStreams.single.sampleRateText, '48 kHz');
  });

  test('ffprobe runtime imports executable into managed directory', () async {
    final tempDir = await _createTempDir('mytools_ffprobe_runtime_');

    final fakeFfprobe = File('${tempDir.path}/ffprobe');
    await _writeExecutable(fakeFfprobe, '#!/bin/sh\necho "ffprobe test"\n');

    final runtime = _TestFfprobeRuntime(
      managedPath: '${tempDir.path}/managed/ffprobe',
      bundlePath: '${tempDir.path}/bundle/ffprobe',
      candidates: <String>[fakeFfprobe.path],
    );

    final status = await runtime.resolve();
    expect(status.isAvailable, isTrue);
    expect(status.path, fakeFfprobe.path);

    final installedPath = await runtime.installFrom(fakeFfprobe.path);
    expect(installedPath, '${tempDir.path}/managed/ffprobe');
    expect(File(installedPath).existsSync(), isTrue);
  });

  test(
    'ffprobe runtime keeps current executable when import is invalid',
    () async {
      final tempDir = await _createTempDir('mytools_ffprobe_invalid_import_');

      final managedFfprobe = File('${tempDir.path}/managed/ffprobe');
      await managedFfprobe.parent.create(recursive: true);
      await _writeExecutable(
        managedFfprobe,
        '#!/bin/sh\necho "existing ffprobe"\n',
      );

      final invalidFfprobe = File('${tempDir.path}/invalid_ffprobe');
      await _writeExecutable(invalidFfprobe, '#!/bin/sh\nexit 1\n');

      final runtime = _TestFfprobeRuntime(
        managedPath: managedFfprobe.path,
        bundlePath: '${tempDir.path}/bundle/ffprobe',
        candidates: const <String>[],
      );

      await expectLater(
        runtime.installFrom(invalidFfprobe.path),
        throwsA(
          isA<FormatException>().having(
            (FormatException error) => error.message,
            'message',
            '导入的 ffprobe 无法执行，请确认文件适用于当前 Mac。',
          ),
        ),
      );

      expect(await managedFfprobe.readAsString(), contains('existing ffprobe'));
      expect(
        managedFfprobe.parent.listSync().where(
          (FileSystemEntity entity) => entity.path.contains('.importing.'),
        ),
        isEmpty,
      );
    },
  );

  test('ffprobe runtime enables bundled executable in place', () async {
    final tempDir = await _createTempDir('mytools_ffprobe_auto_install_');

    final bundledFfprobe = File('${tempDir.path}/bundle/ffprobe');
    await bundledFfprobe.parent.create(recursive: true);
    await _writeExecutable(bundledFfprobe, '#!/bin/sh\necho "ffprobe test"\n');

    final runtime = _TestFfprobeRuntime(
      managedPath: '${tempDir.path}/managed/ffprobe',
      bundlePath: bundledFfprobe.path,
      candidates: const <String>[],
    );

    final result = await runtime.installRequiredEnvironment();

    expect(result.path, bundledFfprobe.path);
    expect(result.message, 'App 内置 ffprobe 已可用。');
    expect(File('${tempDir.path}/managed/ffprobe').existsSync(), isFalse);

    final status = await runtime.resolve();
    expect(status.isAvailable, isTrue);
    expect(status.path, result.path);
  });

  test('ffprobe runtime reports missing bundled executable clearly', () async {
    final tempDir = await _createTempDir('mytools_ffprobe_missing_bundle_');
    final runtime = _TestFfprobeRuntime(
      managedPath: '${tempDir.path}/managed/ffprobe',
      bundlePath: '${tempDir.path}/bundle/ffprobe',
      candidates: const <String>[],
    );

    expect(
      runtime.installRequiredEnvironment,
      throwsA(
        isA<FormatException>()
            .having(
              (FormatException error) => error.message,
              'message',
              contains('当前 App 未包含内置 ffprobe'),
            )
            .having(
              (FormatException error) => error.message,
              'message',
              isNot(contains('Homebrew')),
            ),
      ),
    );
  });

  test('ffprobe runtime prioritizes bundled executable before homebrew', () {
    final runtime = const FfprobeRuntime();
    final candidates = runtime.candidatePaths();

    expect(candidates[0], runtime.managedExecutablePath());
    expect(candidates[1], runtime.bundleExecutablePath());
    expect(
      candidates.indexOf('/opt/homebrew/bin/ffprobe'),
      greaterThan(candidates.indexOf(runtime.bundleExecutablePath())),
    );
  });
}

const String _fakeFfprobeJson = '''
{
  "streams": [
    {
      "index": 0,
      "codec_name": "h264",
      "codec_long_name": "H.264",
      "codec_type": "video",
      "width": 160,
      "height": 90,
      "avg_frame_rate": "10/1",
      "duration": "1.000000"
    },
    {
      "index": 1,
      "codec_name": "aac",
      "codec_long_name": "AAC",
      "codec_type": "audio",
      "sample_rate": "48000",
      "channels": 1,
      "channel_layout": "mono",
      "duration": "1.000000"
    }
  ],
  "format": {
    "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
    "format_long_name": "QuickTime / MOV",
    "duration": "1.000000",
    "size": "14439",
    "bit_rate": "115512"
  }
}
''';

Future<Directory> _createTempDir(String prefix) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  addTearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  return tempDir;
}

Future<void> _writeExecutable(File file, String content) async {
  await file.writeAsString(content);
  await Process.run('chmod', <String>['755', file.path]);
}

class _TestFfprobeRuntime extends FfprobeRuntime {
  const _TestFfprobeRuntime({
    required this.managedPath,
    required this.bundlePath,
    required this.candidates,
  });

  final String managedPath;
  final String bundlePath;
  final List<String> candidates;

  @override
  List<String> candidatePaths() {
    return <String>[...candidates, managedPath, bundlePath];
  }

  @override
  String managedExecutablePath() => managedPath;

  @override
  String bundleExecutablePath() => bundlePath;
}
