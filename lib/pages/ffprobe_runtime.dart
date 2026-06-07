import 'dart:io';

class FfprobeRuntime {
  const FfprobeRuntime();

  static const String missingMessage =
      '未检测到可用 ffprobe。请更新到包含内置 ffprobe 的 App，或使用“导入ffprobe”。';

  Future<FfprobeInstallResult> installRequiredEnvironment() async {
    final currentStatus = await resolve();

    if (currentStatus.isAvailable) {
      return FfprobeInstallResult(
        path: currentStatus.path,
        message: currentStatus.path == bundleExecutablePath()
            ? 'App 内置 ffprobe 已可用。'
            : 'ffprobe 已可用，无需重复启用。',
      );
    }

    final bundlePath = bundleExecutablePath();

    if (File(bundlePath).existsSync()) {
      throw FormatException(
        '检测到 App 内置 ffprobe，但当前无法执行。请重新构建或更新 App，'
        '也可以使用“导入ffprobe”。期望路径：$bundlePath',
      );
    }

    throw FormatException(
      '当前 App 未包含内置 ffprobe。请重新构建或更新 App，'
      '也可以使用“导入ffprobe”。期望路径：$bundlePath',
    );
  }

  Future<FfprobeRuntimeStatus> resolve() async {
    final candidates = candidatePaths();

    for (final candidate in candidates) {
      if (await _canRun(candidate)) {
        return FfprobeRuntimeStatus.available(path: candidate);
      }
    }

    return FfprobeRuntimeStatus.missing(
      managedPath: managedExecutablePath(),
      bundlePath: bundleExecutablePath(),
    );
  }

  Future<String> installFrom(String sourcePath) async {
    final source = File(sourcePath);

    if (!source.existsSync()) {
      throw const FormatException('选择的 ffprobe 文件不存在。');
    }

    final targetPath = managedExecutablePath();
    final target = File(targetPath);
    await target.parent.create(recursive: true);
    await source.copy(targetPath);
    await _makeExecutable(targetPath);

    if (!await _canRun(targetPath)) {
      throw const FormatException('导入的 ffprobe 无法执行，请确认文件适用于当前 Mac。');
    }

    return targetPath;
  }

  Future<bool> _canRun(String command) async {
    try {
      final result = await runProcess(command, const <String>['-version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  Future<ProcessResult> runProcess(String executable, List<String> arguments) {
    return Process.run(executable, arguments);
  }

  List<String> candidatePaths() {
    return <String>[
      managedExecutablePath(),
      bundleExecutablePath(),
      '/opt/homebrew/bin/ffprobe',
      '/usr/local/bin/ffprobe',
      'ffprobe',
    ];
  }

  Future<void> _makeExecutable(String path) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    await Process.run('chmod', <String>['755', path]);
  }

  String managedExecutablePath() {
    return '${_applicationSupportPath()}${Platform.pathSeparator}bin${Platform.pathSeparator}ffprobe';
  }

  String _applicationSupportPath() {
    final home = Platform.environment['HOME'];

    if (home == null || home.isEmpty) {
      return Directory.current.path;
    }

    if (Platform.isMacOS) {
      return '$home/Library/Application Support/MyTools';
    }

    return '$home/.mytools';
  }

  String bundleExecutablePath() {
    final executable = Platform.resolvedExecutable;
    final macOsMarker =
        '${Platform.pathSeparator}Contents${Platform.pathSeparator}MacOS${Platform.pathSeparator}';
    final markerIndex = executable.indexOf(macOsMarker);

    if (markerIndex == -1) {
      return '${Directory.current.path}${Platform.pathSeparator}Resources${Platform.pathSeparator}bin${Platform.pathSeparator}ffprobe';
    }

    final contentsPath =
        '${executable.substring(0, markerIndex)}${Platform.pathSeparator}Contents';
    return '$contentsPath${Platform.pathSeparator}Resources${Platform.pathSeparator}bin${Platform.pathSeparator}ffprobe';
  }
}

class FfprobeInstallResult {
  const FfprobeInstallResult({required this.path, required this.message});

  final String path;
  final String message;
}

class FfprobeRuntimeStatus {
  const FfprobeRuntimeStatus._({
    required this.isAvailable,
    required this.path,
    required this.managedPath,
    required this.bundlePath,
  });

  factory FfprobeRuntimeStatus.available({required String path}) {
    return FfprobeRuntimeStatus._(
      isAvailable: true,
      path: path,
      managedPath: '',
      bundlePath: '',
    );
  }

  factory FfprobeRuntimeStatus.missing({
    required String managedPath,
    required String bundlePath,
  }) {
    return FfprobeRuntimeStatus._(
      isAvailable: false,
      path: '',
      managedPath: managedPath,
      bundlePath: bundlePath,
    );
  }

  final bool isAvailable;
  final String path;
  final String managedPath;
  final String bundlePath;

  String get displayPath => isAvailable ? path : managedPath;
}
