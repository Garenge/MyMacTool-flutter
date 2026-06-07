import 'dart:io';

import 'mobileprovision_profile_diagnostics.dart';
import 'mobileprovision_profile_info.dart';

class IpaAppInfo {
  const IpaAppInfo({
    required this.appName,
    required this.bundleIdentifier,
    required this.shortVersion,
    required this.buildNumber,
    required this.minimumOsVersion,
    required this.executableName,
    required this.infoPlistPath,
    required this.embeddedProfilePath,
    required this.embeddedProfileInfo,
    required this.embeddedProfileError,
  });

  final String appName;
  final String bundleIdentifier;
  final String shortVersion;
  final String buildNumber;
  final String minimumOsVersion;
  final String executableName;
  final String infoPlistPath;
  final String embeddedProfilePath;
  final MobileProvisionProfileInfo? embeddedProfileInfo;
  final String embeddedProfileError;

  bool get hasAnyValue {
    return <String>[
      appName,
      bundleIdentifier,
      shortVersion,
      buildNumber,
      minimumOsVersion,
      executableName,
      infoPlistPath,
      embeddedProfilePath,
    ].any((String value) => value.isNotEmpty);
  }

  bool get hasEmbeddedProfile => embeddedProfilePath.isNotEmpty;

  bool get hasEmbeddedProfileInfo => embeddedProfileInfo != null;

  BundleIdentifierMatchResult get bundleIdentifierMatch {
    return BundleIdentifierMatchResult.evaluate(
      appBundleIdentifier: bundleIdentifier,
      profileBundleIdentifier: embeddedProfileInfo?.bundleIdentifier,
    );
  }

  bool get isBundleIdentifierMatched {
    return bundleIdentifierMatch.isMatched;
  }

  MobileProvisionProfileDiagnostics? get embeddedProfileDiagnostics {
    final profile = embeddedProfileInfo;

    if (profile == null) {
      return null;
    }

    return MobileProvisionProfileDiagnostics.evaluate(
      profile,
      appBundleIdentifier: bundleIdentifier,
    );
  }

  String valueOrPlaceholder(String value) {
    return value.isEmpty ? '未读取到' : value;
  }
}

class IpaAppInfoParser {
  const IpaAppInfoParser();

  static const MobileProvisionProfileParser _profileParser =
      MobileProvisionProfileParser();

  Future<IpaAppInfo?> parseFromExtractedDirectory(Directory directory) async {
    final appDirectory = _findAppDirectory(directory);

    if (appDirectory == null) {
      return null;
    }

    final infoPlist = File('${appDirectory.path}/Info.plist');

    if (!infoPlist.existsSync()) {
      return null;
    }

    final displayName = await _readPlistValue(infoPlist, 'CFBundleDisplayName');
    final bundleName = await _readPlistValue(infoPlist, 'CFBundleName');
    final embeddedProfile = File(
      '${appDirectory.path}/embedded.mobileprovision',
    );
    final embeddedProfileResult = await _parseEmbeddedProfile(embeddedProfile);

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
      infoPlistPath: infoPlist.path,
      embeddedProfilePath: embeddedProfile.existsSync()
          ? embeddedProfile.path
          : '',
      embeddedProfileInfo: embeddedProfileResult.info,
      embeddedProfileError: embeddedProfileResult.errorText,
    );
  }

  Directory? _findAppDirectory(Directory directory) {
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
        return appDirectory;
      }
    }

    return null;
  }

  Future<_EmbeddedProfileParseResult> _parseEmbeddedProfile(File file) async {
    if (!file.existsSync()) {
      return const _EmbeddedProfileParseResult(info: null, errorText: '');
    }

    try {
      return _EmbeddedProfileParseResult(
        info: await _profileParser.parse(file.path),
        errorText: '',
      );
    } on FormatException catch (error) {
      return _EmbeddedProfileParseResult(info: null, errorText: error.message);
    } catch (error) {
      return const _EmbeddedProfileParseResult(
        info: null,
        errorText: 'embedded.mobileprovision 解析失败。',
      );
    }
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

class _EmbeddedProfileParseResult {
  const _EmbeddedProfileParseResult({
    required this.info,
    required this.errorText,
  });

  final MobileProvisionProfileInfo? info;
  final String errorText;
}
