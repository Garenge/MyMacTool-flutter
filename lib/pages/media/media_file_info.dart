import 'dart:convert';
import 'dart:io';

import 'ffprobe_runtime.dart';
import '../../utils/path_utils.dart';

class MediaFileInfo {
  const MediaFileInfo({
    required this.filePath,
    required this.fileName,
    required this.formatName,
    required this.formatLongName,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.bitRate,
    required this.streams,
    required this.metadata,
  });

  final String filePath;
  final String fileName;
  final String formatName;
  final String formatLongName;
  final double? durationSeconds;
  final int? fileSizeBytes;
  final int? bitRate;
  final List<MediaStreamInfo> streams;
  final Map<String, String> metadata;

  List<MediaStreamInfo> get videoStreams =>
      streams.where((MediaStreamInfo stream) => stream.isVideo).toList();

  List<MediaStreamInfo> get audioStreams =>
      streams.where((MediaStreamInfo stream) => stream.isAudio).toList();

  List<MediaStreamInfo> get otherStreams => streams
      .where((MediaStreamInfo stream) => !stream.isVideo && !stream.isAudio)
      .toList();

  String get displayFormat {
    if (formatLongName.isNotEmpty) {
      return formatLongName;
    }

    if (formatName.isNotEmpty) {
      return formatName;
    }

    return '-';
  }

  String get durationText => MediaFormatters.duration(durationSeconds);

  String get fileSizeText => MediaFormatters.fileSize(fileSizeBytes);

  String get bitRateText => MediaFormatters.bitRate(bitRate);
}

class MediaStreamInfo {
  const MediaStreamInfo({
    required this.index,
    required this.type,
    required this.codecName,
    required this.codecLongName,
    required this.profile,
    required this.width,
    required this.height,
    required this.pixelFormat,
    required this.frameRate,
    required this.sampleRate,
    required this.channels,
    required this.channelLayout,
    required this.bitRate,
    required this.durationSeconds,
    required this.language,
  });

  final int index;
  final String type;
  final String codecName;
  final String codecLongName;
  final String profile;
  final int? width;
  final int? height;
  final String pixelFormat;
  final double? frameRate;
  final int? sampleRate;
  final int? channels;
  final String channelLayout;
  final int? bitRate;
  final double? durationSeconds;
  final String language;

  bool get isVideo => type == 'video';

  bool get isAudio => type == 'audio';

  String get codecText {
    if (codecLongName.isNotEmpty) {
      return codecName.isEmpty ? codecLongName : '$codecName · $codecLongName';
    }

    return codecName.isEmpty ? '-' : codecName;
  }

  String get resolutionText {
    final streamWidth = width;
    final streamHeight = height;

    if (streamWidth == null || streamHeight == null) {
      return '-';
    }

    return '$streamWidth x $streamHeight';
  }

  String get frameRateText {
    final value = frameRate;

    if (value == null || value <= 0) {
      return '-';
    }

    final rounded = value.toStringAsFixed(value >= 10 ? 2 : 3);
    return '${_trimTrailingZeros(rounded)} fps';
  }

  String get sampleRateText {
    final value = sampleRate;

    if (value == null || value <= 0) {
      return '-';
    }

    if (value >= 1000) {
      return '${_trimTrailingZeros((value / 1000).toStringAsFixed(1))} kHz';
    }

    return '$value Hz';
  }

  String get channelsText {
    final value = channels;

    if (value == null || value <= 0) {
      return channelLayout.isEmpty ? '-' : channelLayout;
    }

    if (channelLayout.isEmpty) {
      return '$value ch';
    }

    return '$value ch · $channelLayout';
  }

  String get bitRateText => MediaFormatters.bitRate(bitRate);

  String get durationText => MediaFormatters.duration(durationSeconds);

  String get languageText => language.isEmpty ? '-' : language;

  static String _trimTrailingZeros(String value) {
    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class MediaFileInfoParser {
  const MediaFileInfoParser({this.runtime = const FfprobeRuntime()});

  final FfprobeRuntime runtime;

  Future<MediaFileInfo> parse(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw const FormatException('文件不存在，请重新选择。');
    }

    final runtimeStatus = await runtime.resolve();

    if (!runtimeStatus.isAvailable) {
      throw const FormatException(FfprobeRuntime.missingMessage);
    }

    final result = await _runFfprobe(runtimeStatus.path, path);

    if (result.exitCode != 0) {
      throw FormatException(_formatFfprobeError(result.stderr));
    }

    return parseJson(result.stdout.toString(), filePath: path);
  }

  MediaFileInfo parseJson(String jsonText, {String filePath = ''}) {
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('ffprobe 返回内容不是有效对象。');
    }

    final format = _asMap(decoded['format']);
    final streams = _asList(
      decoded['streams'],
    ).whereType<Map<String, Object?>>().map(_parseStream).toList();

    if (format.isEmpty && streams.isEmpty) {
      throw const FormatException('未读取到有效的音视频信息。');
    }

    return MediaFileInfo(
      filePath: filePath,
      fileName: displayFileName(filePath, emptyPlaceholder: '-'),
      formatName: _stringValue(format['format_name']),
      formatLongName: _stringValue(format['format_long_name']),
      durationSeconds: _doubleValue(format['duration']),
      fileSizeBytes: _intValue(format['size']),
      bitRate: _intValue(format['bit_rate']),
      streams: streams,
      metadata: _stringMap(format['tags']),
    );
  }

  Future<ProcessResult> _runFfprobe(String command, String path) async {
    return Process.run(command, <String>[
      '-v',
      'error',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      path,
    ]);
  }

  MediaStreamInfo _parseStream(Map<String, Object?> stream) {
    return MediaStreamInfo(
      index: _intValue(stream['index']) ?? 0,
      type: _stringValue(stream['codec_type']),
      codecName: _stringValue(stream['codec_name']),
      codecLongName: _stringValue(stream['codec_long_name']),
      profile: _stringValue(stream['profile']),
      width: _intValue(stream['width']),
      height: _intValue(stream['height']),
      pixelFormat: _stringValue(stream['pix_fmt']),
      frameRate:
          _rateValue(stream['avg_frame_rate']) ??
          _rateValue(stream['r_frame_rate']),
      sampleRate: _intValue(stream['sample_rate']),
      channels: _intValue(stream['channels']),
      channelLayout: _stringValue(stream['channel_layout']),
      bitRate: _intValue(stream['bit_rate']),
      durationSeconds: _doubleValue(stream['duration']),
      language: _stringMap(stream['tags'])['language'] ?? '',
    );
  }

  String _formatFfprobeError(Object? stderr) {
    final errorText = stderr?.toString().trim() ?? '';

    if (errorText.isEmpty) {
      return 'ffprobe 解析失败，请确认文件是有效的音频或视频文件。';
    }

    return 'ffprobe 解析失败：$errorText';
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (Object? key, Object? item) => MapEntry(key.toString(), item),
      );
    }

    return const <String, Object?>{};
  }

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return value.cast<Object?>();
    }

    return const <Object?>[];
  }

  Map<String, String> _stringMap(Object? value) {
    final map = _asMap(value);

    return map.map(
      (String key, Object? item) => MapEntry(key, _stringValue(item)),
    );
  }

  String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(_stringValue(value));
  }

  double? _doubleValue(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(_stringValue(value));
  }

  double? _rateValue(Object? value) {
    final text = _stringValue(value);

    if (text.isEmpty || text == '0/0') {
      return null;
    }

    final parts = text.split('/');

    if (parts.length != 2) {
      return double.tryParse(text);
    }

    final numerator = double.tryParse(parts[0]);
    final denominator = double.tryParse(parts[1]);

    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }

    return numerator / denominator;
  }
}

class MediaFormatters {
  const MediaFormatters._();

  static String duration(double? seconds) {
    if (seconds == null || seconds < 0) {
      return '-';
    }

    final totalMilliseconds = (seconds * 1000).round();
    final totalSeconds = totalMilliseconds ~/ 1000;
    final milliseconds = totalMilliseconds % 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    final secondsText = remainingSeconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final minuteText = minutes.toString().padLeft(2, '0');
      return '$hours:$minuteText:$secondsText';
    }

    if (milliseconds == 0) {
      return '$minutes:$secondsText';
    }

    final decimal = (milliseconds / 1000).toStringAsFixed(3).substring(1);
    return '$minutes:$secondsText$decimal';
  }

  static String fileSize(int? bytes) {
    return formatByteSize(bytes);
  }

  static String bitRate(int? bitsPerSecond) {
    final value = bitsPerSecond;

    if (value == null || value <= 0) {
      return '-';
    }

    if (value < 1000) {
      return '$value bps';
    }

    if (value < 1000 * 1000) {
      return '${_trim((value / 1000).toStringAsFixed(1))} kbps';
    }

    return '${_trim((value / 1000 / 1000).toStringAsFixed(2))} Mbps';
  }

  static String _trim(String value) {
    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
