import 'dart:convert';
import 'dart:typed_data';

class X509CertificateInfo {
  const X509CertificateInfo({
    required this.subject,
    required this.issuer,
    required this.serialNumber,
    required this.notBefore,
    required this.notAfter,
  });

  final String? subject;
  final String? issuer;
  final String? serialNumber;
  final DateTime? notBefore;
  final DateTime? notAfter;

  bool get hasAnyValue {
    return subject != null ||
        issuer != null ||
        serialNumber != null ||
        notBefore != null ||
        notAfter != null;
  }
}

class X509CertificateParser {
  const X509CertificateParser();

  X509CertificateInfo parse(Uint8List bytes) {
    final certificate = _Asn1Reader(bytes).readNode();
    final certificateChildren = _children(certificate);

    if (certificate.tag != _Asn1Tags.sequence || certificateChildren.isEmpty) {
      throw const FormatException('未读取到有效的 X.509 证书。');
    }

    final tbsCertificate = certificateChildren.first;
    final tbsChildren = _children(tbsCertificate);

    if (tbsCertificate.tag != _Asn1Tags.sequence || tbsChildren.length < 6) {
      throw const FormatException('未读取到有效的 X.509 TBSCertificate。');
    }

    var index = _isExplicitVersion(tbsChildren.first) ? 1 : 0;
    final serialNumber = _parseIntegerHex(tbsChildren[index]);
    index += 1;
    index += 1;
    final issuer = _parseName(tbsChildren[index]);
    index += 1;
    final validity = _parseValidity(tbsChildren[index]);
    index += 1;
    final subject = _parseName(tbsChildren[index]);

    return X509CertificateInfo(
      subject: subject,
      issuer: issuer,
      serialNumber: serialNumber,
      notBefore: validity.notBefore,
      notAfter: validity.notAfter,
    );
  }

  bool _isExplicitVersion(_Asn1Node node) {
    return node.tagClass == _Asn1TagClass.contextSpecific &&
        node.tagNumber == 0;
  }

  List<_Asn1Node> _children(_Asn1Node node) {
    final reader = _Asn1Reader(node.content);
    final children = <_Asn1Node>[];

    while (reader.hasBytes) {
      children.add(reader.readNode());
    }

    return children;
  }

  String? _parseIntegerHex(_Asn1Node node) {
    if (node.tag != _Asn1Tags.integer) {
      return null;
    }

    final content = node.content;
    var start = 0;

    while (start < content.length - 1 && content[start] == 0) {
      start += 1;
    }

    if (start >= content.length) {
      return null;
    }

    return content
        .sublist(start)
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  _CertificateValidity _parseValidity(_Asn1Node node) {
    if (node.tag != _Asn1Tags.sequence) {
      return const _CertificateValidity();
    }

    final children = _children(node);

    if (children.length < 2) {
      return const _CertificateValidity();
    }

    return _CertificateValidity(
      notBefore: _parseTime(children[0]),
      notAfter: _parseTime(children[1]),
    );
  }

  DateTime? _parseTime(_Asn1Node node) {
    final text = _parseString(node);

    if (text == null || text.isEmpty) {
      return null;
    }

    if (node.tag == _Asn1Tags.utcTime) {
      return _parseUtcTime(text);
    }

    if (node.tag == _Asn1Tags.generalizedTime) {
      return _parseGeneralizedTime(text);
    }

    return null;
  }

  DateTime? _parseUtcTime(String text) {
    final match = RegExp(
      r'^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:(\d{2}))?(Z|[+-]\d{4})?$',
    ).firstMatch(text.trim());

    if (match == null) {
      return null;
    }

    final yearValue = _parseInt(match.group(1));
    final year = yearValue >= 50 ? 1900 + yearValue : 2000 + yearValue;

    return _buildDateTimeFromMatch(
      match,
      year: year,
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
      zoneGroup: 7,
    );
  }

  DateTime? _parseGeneralizedTime(String text) {
    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(?:(\d{2}))?(?:\.\d+)?(Z|[+-]\d{4})?$',
    ).firstMatch(text.trim());

    if (match == null) {
      return null;
    }

    return _buildDateTimeFromMatch(
      match,
      year: _parseInt(match.group(1)),
      monthGroup: 2,
      dayGroup: 3,
      hourGroup: 4,
      minuteGroup: 5,
      secondGroup: 6,
      zoneGroup: 7,
    );
  }

  DateTime _buildDateTimeFromMatch(
    RegExpMatch match, {
    required int year,
    required int monthGroup,
    required int dayGroup,
    required int hourGroup,
    required int minuteGroup,
    required int secondGroup,
    required int zoneGroup,
  }) {
    final dateTime = DateTime.utc(
      year,
      _parseInt(match.group(monthGroup)),
      _parseInt(match.group(dayGroup)),
      _parseInt(match.group(hourGroup)),
      _parseInt(match.group(minuteGroup)),
      _parseInt(match.group(secondGroup), fallback: 0),
    );
    final zone = match.group(zoneGroup);

    if (zone == null || zone == 'Z') {
      return dateTime;
    }

    final sign = zone.startsWith('-') ? -1 : 1;
    final hours = int.parse(zone.substring(1, 3));
    final minutes = int.parse(zone.substring(3, 5));
    final offsetMinutes = sign * (hours * 60 + minutes);

    return dateTime.subtract(Duration(minutes: offsetMinutes));
  }

  String? _parseName(_Asn1Node node) {
    if (node.tag != _Asn1Tags.sequence) {
      return null;
    }

    final parts = <String>[];

    for (final relativeDistinguishedName in _children(node)) {
      if (relativeDistinguishedName.tag != _Asn1Tags.set) {
        continue;
      }

      for (final attribute in _children(relativeDistinguishedName)) {
        final attributeParts = _children(attribute);

        if (attribute.tag != _Asn1Tags.sequence || attributeParts.length < 2) {
          continue;
        }

        final oid = _parseObjectIdentifier(attributeParts[0]);
        final value = _parseString(attributeParts[1]);

        if (oid == null || value == null || value.trim().isEmpty) {
          continue;
        }

        parts.add('${_oidLabel(oid)}=${value.trim()}');
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }

  String? _parseObjectIdentifier(_Asn1Node node) {
    if (node.tag != _Asn1Tags.objectIdentifier) {
      return null;
    }

    final content = node.content;

    if (content.isEmpty) {
      return null;
    }

    final subIdentifiers = <int>[];
    var current = 0;

    for (final byte in content) {
      current = (current << 7) | (byte & 0x7F);

      if ((byte & 0x80) == 0) {
        subIdentifiers.add(current);
        current = 0;
      }
    }

    if (subIdentifiers.isEmpty) {
      return null;
    }

    final first = subIdentifiers.first;
    final firstPart = first < 40 ? 0 : (first < 80 ? 1 : 2);
    final secondPart = first - firstPart * 40;
    final parts = <int>[firstPart, secondPart, ...subIdentifiers.skip(1)];

    return parts.join('.');
  }

  String? _parseString(_Asn1Node node) {
    final content = node.content;

    switch (node.tag) {
      case _Asn1Tags.utf8String:
        return utf8.decode(content, allowMalformed: true);
      case _Asn1Tags.printableString:
      case _Asn1Tags.teletexString:
      case _Asn1Tags.ia5String:
      case _Asn1Tags.utcTime:
      case _Asn1Tags.generalizedTime:
        return latin1.decode(content, allowInvalid: true);
      case _Asn1Tags.bmpString:
        return _decodeBmpString(content);
      case _Asn1Tags.universalString:
        return _decodeUniversalString(content);
      default:
        return null;
    }
  }

  String _decodeBmpString(Uint8List bytes) {
    final codeUnits = <int>[];

    for (var index = 0; index + 1 < bytes.length; index += 2) {
      codeUnits.add((bytes[index] << 8) | bytes[index + 1]);
    }

    return String.fromCharCodes(codeUnits);
  }

  String _decodeUniversalString(Uint8List bytes) {
    final codeUnits = <int>[];

    for (var index = 0; index + 3 < bytes.length; index += 4) {
      codeUnits.add(
        (bytes[index] << 24) |
            (bytes[index + 1] << 16) |
            (bytes[index + 2] << 8) |
            bytes[index + 3],
      );
    }

    return String.fromCharCodes(codeUnits);
  }

  int _parseInt(String? value, {int fallback = 0}) {
    return int.tryParse(value ?? '') ?? fallback;
  }

  String _oidLabel(String oid) {
    switch (oid) {
      case '2.5.4.3':
        return 'CN';
      case '2.5.4.4':
        return 'SN';
      case '2.5.4.5':
        return 'Serial';
      case '2.5.4.6':
        return 'C';
      case '2.5.4.7':
        return 'L';
      case '2.5.4.8':
        return 'ST';
      case '2.5.4.10':
        return 'O';
      case '2.5.4.11':
        return 'OU';
      case '1.2.840.113549.1.9.1':
        return 'Email';
      case '0.9.2342.19200300.100.1.25':
        return 'DC';
      default:
        return oid;
    }
  }
}

class _CertificateValidity {
  const _CertificateValidity({this.notBefore, this.notAfter});

  final DateTime? notBefore;
  final DateTime? notAfter;
}

class _Asn1Node {
  const _Asn1Node({required this.tag, required this.content});

  final int tag;
  final Uint8List content;

  int get tagClass => tag & 0xC0;

  int get tagNumber => tag & 0x1F;
}

class _Asn1Reader {
  _Asn1Reader(this.bytes);

  final Uint8List bytes;
  int _offset = 0;

  bool get hasBytes => _offset < bytes.length;

  _Asn1Node readNode() {
    final tag = _readByte();
    final length = _readLength();

    if (_offset + length > bytes.length) {
      throw const FormatException('ASN.1 节点长度超出数据范围。');
    }

    final content = Uint8List.fromList(
      bytes.sublist(_offset, _offset + length),
    );
    _offset += length;

    return _Asn1Node(tag: tag, content: content);
  }

  int _readLength() {
    final first = _readByte();

    if ((first & 0x80) == 0) {
      return first;
    }

    final lengthBytes = first & 0x7F;

    if (lengthBytes == 0) {
      throw const FormatException('不支持 indefinite ASN.1 长度。');
    }

    var length = 0;

    for (var index = 0; index < lengthBytes; index += 1) {
      length = (length << 8) | _readByte();
    }

    return length;
  }

  int _readByte() {
    if (_offset >= bytes.length) {
      throw const FormatException('ASN.1 数据读取越界。');
    }

    final value = bytes[_offset];
    _offset += 1;

    return value;
  }
}

abstract final class _Asn1TagClass {
  static const int contextSpecific = 0x80;
}

abstract final class _Asn1Tags {
  static const int integer = 0x02;
  static const int objectIdentifier = 0x06;
  static const int sequence = 0x30;
  static const int set = 0x31;
  static const int utf8String = 0x0C;
  static const int printableString = 0x13;
  static const int teletexString = 0x14;
  static const int ia5String = 0x16;
  static const int utcTime = 0x17;
  static const int generalizedTime = 0x18;
  static const int universalString = 0x1C;
  static const int bmpString = 0x1E;
}
