import 'dart:io';

class IpaAppInfo {
  const IpaAppInfo({
    required this.appName,
    required this.bundleIdentifier,
    required this.shortVersion,
    required this.buildNumber,
    required this.minimumOsVersion,
    required this.executableName,
  });

  final String appName;
  final String bundleIdentifier;
  final String shortVersion;
  final String buildNumber;
  final String minimumOsVersion;
  final String executableName;

  bool get hasAnyValue {
    return <String>[
      appName,
      bundleIdentifier,
      shortVersion,
      buildNumber,
      minimumOsVersion,
      executableName,
    ].any((String value) => value.isNotEmpty);
  }

  String valueOrPlaceholder(String value) {
    return value.isEmpty ? '未读取到' : value;
  }
}

class IpaAppInfoParser {
  const IpaAppInfoParser();

  Future<IpaAppInfo?> parseFromExtractedDirectory(Directory directory) async {
    final infoPlist = _findInfoPlist(directory);

    if (infoPlist == null) {
      return null;
    }

    final displayName = await _readPlistValue(infoPlist, 'CFBundleDisplayName');
    final bundleName = await _readPlistValue(infoPlist, 'CFBundleName');

    return IpaAppInfo(
      appName: displayName.isNotEmpty ? displayName : bundleName,
      bundleIdentifier: await _readPlistValue(infoPlist, 'CFBundleIdentifier'),
      shortVersion: await _readPlistValue(
        infoPlist,
        'CFBundleShortVersionString',
      ),
      buildNumber: await _readPlistValue(infoPlist, 'CFBundleVersion'),
      minimumOsVersion: await _readPlistValue(infoPlist, 'MinimumOSVersion'),
      executableName: await _readPlistValue(infoPlist, 'CFBundleExecutable'),
    );
  }

  File? _findInfoPlist(Directory directory) {
    final payloadDirectory = Directory('${directory.path}/Payload');

    if (!payloadDirectory.existsSync()) {
      return null;
    }

    final appDirectories = payloadDirectory
        .listSync(followLinks: false)
        .whereType<Directory>()
        .where((Directory item) => item.path.toLowerCase().endsWith('.app'))
        .toList(growable: false);

    for (final appDirectory in appDirectories) {
      final infoPlist = File('${appDirectory.path}/Info.plist');

      if (infoPlist.existsSync()) {
        return infoPlist;
      }
    }

    return null;
  }

  Future<String> _readPlistValue(File plistFile, String key) async {
    if (!Platform.isMacOS) {
      return '';
    }

    final result = await Process.run('/usr/bin/plutil', <String>[
      '-extract',
      key,
      'raw',
      '-o',
      '-',
      plistFile.path,
    ]);

    if (result.exitCode != 0) {
      return '';
    }

    return '${result.stdout}'.trim();
  }
}
