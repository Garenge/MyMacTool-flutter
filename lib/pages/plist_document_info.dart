import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

class PlistDocumentInfo {
  const PlistDocumentInfo({
    required this.filePath,
    required this.xmlText,
    required this.root,
    required this.itemCount,
  });

  final String filePath;
  final String xmlText;
  final PlistNode root;
  final int itemCount;
}

class PlistNode {
  const PlistNode({
    required this.key,
    required this.path,
    required this.type,
    required this.valueText,
    required this.children,
  });

  final String? key;
  final String path;
  final PlistNodeType type;
  final String valueText;
  final List<PlistNode> children;

  bool get hasChildren => children.isNotEmpty;

  String get title {
    if (key == null || key!.isEmpty) {
      return path;
    }

    return key!;
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return true;
    }

    return title.toLowerCase().contains(normalized) ||
        path.toLowerCase().contains(normalized) ||
        valueText.toLowerCase().contains(normalized) ||
        type.label.toLowerCase().contains(normalized);
  }
}

enum PlistNodeType {
  dict('Dict'),
  array('Array'),
  string('String'),
  integer('Integer'),
  real('Real'),
  boolean('Boolean'),
  date('Date'),
  data('Data');

  const PlistNodeType(this.label);

  final String label;
}

abstract class PlistDocumentParsing {
  Future<PlistDocumentInfo> parse(String path);
}

class PlistDocumentParser implements PlistDocumentParsing {
  const PlistDocumentParser();

  @override
  Future<PlistDocumentInfo> parse(String path) async {
    if (!path.toLowerCase().endsWith('.plist')) {
      throw const FormatException('当前仅支持 .plist 文件。');
    }

    final file = File(path);

    if (!file.existsSync()) {
      throw const FormatException('文件不存在，请重新选择。');
    }

    final bytes = await file.readAsBytes();
    final directXmlText = _decodeXmlText(bytes);

    if (directXmlText != null) {
      try {
        return parseXml(directXmlText, filePath: path);
      } on FormatException {
        // Fall back to plutil below; malformed XML plist files get the same
        // user-facing error as binary plist conversion failures.
      }
    }

    if (!Platform.isMacOS) {
      throw const FormatException('plist 查看当前仅支持 macOS。');
    }

    final result = await Process.run('/usr/bin/plutil', <String>[
      '-convert',
      'xml1',
      '-o',
      '-',
      path,
    ]);

    if (result.exitCode != 0) {
      throw const FormatException('读取 plist 失败，请确认文件有效。');
    }

    return parseXml(result.stdout.toString(), filePath: path);
  }

  String? _decodeXmlText(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }

    if (bytes.length >= 6) {
      final header = String.fromCharCodes(bytes.take(6));

      if (header == 'bplist') {
        return null;
      }
    }

    final text = utf8.decode(bytes, allowMalformed: true).trimLeft();

    if (!text.startsWith('<?xml') && !text.startsWith('<plist')) {
      return null;
    }

    return text;
  }

  PlistDocumentInfo parseXml(String xmlText, {String filePath = ''}) {
    final document = XmlDocument.parse(xmlText);
    final plist = document.findElements('plist').firstOrNull;
    final rootElement = plist?.children.whereType<XmlElement>().firstOrNull;

    if (rootElement == null) {
      throw const FormatException('未读取到有效的 plist 内容。');
    }

    final root = _parseValue(rootElement, key: null, path: r'$');

    return PlistDocumentInfo(
      filePath: filePath,
      xmlText: xmlText,
      root: root,
      itemCount: _countNodes(root),
    );
  }

  PlistNode _parseValue(
    XmlElement element, {
    String? key,
    required String path,
  }) {
    switch (element.name.local) {
      case 'dict':
        return PlistNode(
          key: key,
          path: path,
          type: PlistNodeType.dict,
          valueText: '${_dictEntryCount(element)} keys',
          children: _parseDict(element, path),
        );
      case 'array':
        return PlistNode(
          key: key,
          path: path,
          type: PlistNodeType.array,
          valueText: '${_arrayItemCount(element)} items',
          children: _parseArray(element, path),
        );
      case 'true':
        return PlistNode(
          key: key,
          path: path,
          type: PlistNodeType.boolean,
          valueText: 'true',
          children: const <PlistNode>[],
        );
      case 'false':
        return PlistNode(
          key: key,
          path: path,
          type: PlistNodeType.boolean,
          valueText: 'false',
          children: const <PlistNode>[],
        );
      case 'integer':
        return _leafNode(key, path, PlistNodeType.integer, element.innerText);
      case 'real':
        return _leafNode(key, path, PlistNodeType.real, element.innerText);
      case 'date':
        return _leafNode(key, path, PlistNodeType.date, element.innerText);
      case 'data':
        return _leafNode(
          key,
          path,
          PlistNodeType.data,
          element.innerText.replaceAll(RegExp(r'\s+'), ''),
        );
      case 'string':
        return _leafNode(key, path, PlistNodeType.string, element.innerText);
      default:
        throw FormatException('暂不支持的 plist 节点类型：${element.name.local}');
    }
  }

  PlistNode _leafNode(
    String? key,
    String path,
    PlistNodeType type,
    String value,
  ) {
    return PlistNode(
      key: key,
      path: path,
      type: type,
      valueText: value.trim(),
      children: const <PlistNode>[],
    );
  }

  List<PlistNode> _parseDict(XmlElement dict, String parentPath) {
    final children = dict.children.whereType<XmlElement>().toList();
    final nodes = <PlistNode>[];

    for (var index = 0; index < children.length; index += 1) {
      final keyElement = children[index];

      if (keyElement.name.local != 'key') {
        continue;
      }

      if (index + 1 >= children.length) {
        break;
      }

      final key = keyElement.innerText;
      final valueElement = children[index + 1];
      nodes.add(_parseValue(valueElement, key: key, path: '$parentPath.$key'));
      index += 1;
    }

    return nodes;
  }

  List<PlistNode> _parseArray(XmlElement array, String parentPath) {
    final children = array.children.whereType<XmlElement>().toList();

    return children.indexed
        .map(
          ((int, XmlElement) entry) => _parseValue(
            entry.$2,
            key: '[${entry.$1}]',
            path: '$parentPath[${entry.$1}]',
          ),
        )
        .toList();
  }

  int _dictEntryCount(XmlElement dict) {
    return dict.children
        .whereType<XmlElement>()
        .where((XmlElement child) => child.name.local == 'key')
        .length;
  }

  int _arrayItemCount(XmlElement array) {
    return array.children.whereType<XmlElement>().length;
  }

  int _countNodes(PlistNode node) {
    return 1 +
        node.children.fold<int>(
          0,
          (int total, PlistNode child) => total + _countNodes(child),
        );
  }
}
