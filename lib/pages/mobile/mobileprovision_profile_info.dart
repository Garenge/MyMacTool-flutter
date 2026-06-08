import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:xml/xml.dart';

import '../../utils/path_utils.dart';
import 'x509_certificate_info.dart';

class MobileProvisionProfileInfo {
  const MobileProvisionProfileInfo({
    required this.filePath,
    required this.name,
    required this.uuid,
    required this.appIdName,
    required this.teamName,
    required this.teamIdentifiers,
    required this.appIdentifierPrefixes,
    required this.applicationIdentifier,
    required this.bundleIdentifier,
    required this.creationDate,
    required this.expirationDate,
    required this.timeToLive,
    required this.platforms,
    required this.provisionedDevices,
    required this.certificates,
    required this.entitlements,
    required this.provisionsAllDevices,
    required this.betaReportsActive,
  });

  final String filePath;
  final String name;
  final String uuid;
  final String? appIdName;
  final String? teamName;
  final List<String> teamIdentifiers;
  final List<String> appIdentifierPrefixes;
  final String? applicationIdentifier;
  final String? bundleIdentifier;
  final DateTime? creationDate;
  final DateTime? expirationDate;
  final int? timeToLive;
  final List<String> platforms;
  final List<String> provisionedDevices;
  final List<MobileProvisionCertificateInfo> certificates;
  final Map<String, Object?> entitlements;
  final bool provisionsAllDevices;
  final bool betaReportsActive;

  bool get isExpired {
    final expiresAt = expirationDate;

    if (expiresAt == null) {
      return false;
    }

    return DateTime.now().isAfter(expiresAt);
  }

  String get profileKindLabel {
    if (provisionsAllDevices) {
      return 'Enterprise / In-House';
    }

    if (provisionedDevices.isNotEmpty) {
      return 'Development / Ad Hoc';
    }

    if (betaReportsActive) {
      return 'App Store / TestFlight';
    }

    return 'App Store / 未限制设备';
  }
}

class MobileProvisionCertificateInfo {
  const MobileProvisionCertificateInfo({
    required this.index,
    required this.byteLength,
    required this.sha1,
    required this.sha256,
    required this.x509,
  });

  final int index;
  final int byteLength;
  final String sha1;
  final String sha256;
  final X509CertificateInfo? x509;

  DateTime? get notBefore => x509?.notBefore;

  DateTime? get notAfter => x509?.notAfter;

  bool get hasX509Info => x509?.hasAnyValue ?? false;
}

class MobileProvisionProfileParser {
  const MobileProvisionProfileParser();

  static const X509CertificateParser _certificateParser =
      X509CertificateParser();

  Future<MobileProvisionProfileInfo> parse(String path) async {
    if (!_isProvisionPath(path)) {
      throw const FormatException(
        '当前仅支持 .mobileprovision 或 .provisionprofile 文件。',
      );
    }

    final file = File(path);

    if (!file.existsSync()) {
      throw const FormatException('文件不存在，请重新选择。');
    }

    if (!Platform.isMacOS) {
      throw const FormatException('mobileprovision 解码当前仅支持 macOS。');
    }

    final result = await Process.run('security', <String>[
      'cms',
      '-D',
      '-i',
      path,
    ]);

    if (result.exitCode != 0) {
      throw const FormatException('解码 mobileprovision 失败，请确认文件有效。');
    }

    return parsePlist(result.stdout.toString(), filePath: path);
  }

  MobileProvisionProfileInfo parsePlist(
    String xmlText, {
    String filePath = '',
  }) {
    final root = _parseRootDict(xmlText);
    final entitlements = _readStringMap(root['Entitlements']);
    final applicationIdentifier = _stringValue(
      entitlements['application-identifier'],
    );
    final topLevelTeamIds = _readStringList(root['TeamIdentifier']);
    final entitlementTeamId = _stringValue(
      entitlements['com.apple.developer.team-identifier'],
    );
    final teamIdentifiers = topLevelTeamIds.isEmpty && entitlementTeamId != null
        ? <String>[entitlementTeamId]
        : topLevelTeamIds;
    final appIdentifierPrefixes = _readStringList(
      root['ApplicationIdentifierPrefix'],
    );

    return MobileProvisionProfileInfo(
      filePath: filePath,
      name: _stringValue(root['Name']) ?? '未命名 Profile',
      uuid: _stringValue(root['UUID']) ?? '-',
      appIdName: _stringValue(root['AppIDName']),
      teamName: _stringValue(root['TeamName']),
      teamIdentifiers: teamIdentifiers,
      appIdentifierPrefixes: appIdentifierPrefixes,
      applicationIdentifier: applicationIdentifier,
      bundleIdentifier: _inferBundleIdentifier(
        applicationIdentifier,
        teamIdentifiers,
        appIdentifierPrefixes,
      ),
      creationDate: _dateValue(root['CreationDate']),
      expirationDate: _dateValue(root['ExpirationDate']),
      timeToLive: _intValue(root['TimeToLive']),
      platforms: _readStringList(root['Platform']),
      provisionedDevices: _readStringList(root['ProvisionedDevices']),
      certificates: _readCertificates(root['DeveloperCertificates']),
      entitlements: entitlements,
      provisionsAllDevices: _boolValue(root['ProvisionsAllDevices']) ?? false,
      betaReportsActive: _boolValue(root['BetaReportsActive']) ?? false,
    );
  }

  bool _isProvisionPath(String path) {
    return hasFileExtension(path, <String>[
      '.mobileprovision',
      '.provisionprofile',
    ]);
  }

  Map<String, Object?> _parseRootDict(String xmlText) {
    final document = XmlDocument.parse(xmlText);
    final plist = document.findElements('plist').firstOrNull;
    final dict = plist?.findElements('dict').firstOrNull;

    if (dict == null) {
      throw const FormatException('未读取到有效的 plist dict。');
    }

    return _parseDict(dict);
  }

  Map<String, Object?> _parseDict(XmlElement dict) {
    final values = <String, Object?>{};
    final children = dict.children.whereType<XmlElement>().toList();

    for (var index = 0; index < children.length; index += 1) {
      final keyElement = children[index];

      if (keyElement.name.local != 'key') {
        continue;
      }

      if (index + 1 >= children.length) {
        break;
      }

      values[keyElement.innerText] = _parseValue(children[index + 1]);
      index += 1;
    }

    return values;
  }

  Object? _parseValue(XmlElement element) {
    switch (element.name.local) {
      case 'array':
        return element.children
            .whereType<XmlElement>()
            .map(_parseValue)
            .where((Object? value) => value != null)
            .toList();
      case 'dict':
        return _parseDict(element);
      case 'true':
        return true;
      case 'false':
        return false;
      case 'integer':
        return int.tryParse(element.innerText.trim());
      case 'real':
        return double.tryParse(element.innerText.trim());
      case 'date':
        return DateTime.tryParse(element.innerText.trim());
      case 'data':
        return _PlistData(element.innerText.replaceAll(RegExp(r'\s+'), ''));
      case 'string':
        return element.innerText;
      default:
        return element.innerText;
    }
  }

  Map<String, Object?> _readStringMap(Object? value) {
    if (value is! Map<String, Object?>) {
      return const <String, Object?>{};
    }

    return value;
  }

  List<String> _readStringList(Object? value) {
    if (value is! List<Object?>) {
      return const <String>[];
    }

    return value
        .map(_stringValue)
        .whereType<String>()
        .where((String item) => item.trim().isNotEmpty)
        .toList();
  }

  List<MobileProvisionCertificateInfo> _readCertificates(Object? value) {
    if (value is! List<Object?>) {
      return const <MobileProvisionCertificateInfo>[];
    }

    final certificates = <MobileProvisionCertificateInfo>[];

    for (final item in value) {
      if (item is! _PlistData) {
        continue;
      }

      final bytes = item.bytes;
      certificates.add(
        MobileProvisionCertificateInfo(
          index: certificates.length + 1,
          byteLength: bytes.length,
          sha1: _digestHex(crypto.sha1.convert(bytes)),
          sha256: _digestHex(crypto.sha256.convert(bytes)),
          x509: _parseCertificate(bytes),
        ),
      );
    }

    return certificates;
  }

  X509CertificateInfo? _parseCertificate(Uint8List bytes) {
    try {
      final info = _certificateParser.parse(bytes);
      return info.hasAnyValue ? info : null;
    } catch (_) {
      return null;
    }
  }

  String? _inferBundleIdentifier(
    String? applicationIdentifier,
    List<String> teamIdentifiers,
    List<String> appIdentifierPrefixes,
  ) {
    if (applicationIdentifier == null || applicationIdentifier.isEmpty) {
      return null;
    }

    for (final prefix in <String>[
      ...teamIdentifiers,
      ...appIdentifierPrefixes,
    ]) {
      final marker = '$prefix.';

      if (applicationIdentifier.startsWith(marker)) {
        return applicationIdentifier.substring(marker.length);
      }
    }

    final firstDotIndex = applicationIdentifier.indexOf('.');

    if (firstDotIndex < 0 ||
        firstDotIndex == applicationIdentifier.length - 1) {
      return applicationIdentifier;
    }

    return applicationIdentifier.substring(firstDotIndex + 1);
  }

  String? _stringValue(Object? value) {
    if (value is String) {
      return value;
    }

    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    return null;
  }

  DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    return null;
  }

  bool? _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    return null;
  }

  String _digestHex(crypto.Digest digest) {
    return digest.bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }
}

class _PlistData {
  const _PlistData(this.base64Text);

  final String base64Text;

  Uint8List get bytes => base64Decode(base64Text);
}
