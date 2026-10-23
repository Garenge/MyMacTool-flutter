import 'dart:convert';

enum JsonNodeCopyAction { value, json, path }

class JsonTreeNode {
  const JsonTreeNode({
    required this.label,
    required this.value,
    this.path = r'$',
    this.depth = 0,
  });

  final String label;
  final Object? value;
  final String path;
  final int depth;

  bool get isContainer => value is Map || value is List;

  bool get hasExpandableChildren {
    final source = value;
    return source is List &&
        source.any(
          (child) =>
              (child is Map && child.isNotEmpty) ||
              (child is List && child.isNotEmpty),
        );
  }

  int get childCount => switch (value) {
    Map value => value.length,
    List value => value.length,
    _ => 0,
  };

  String get summary => switch (value) {
    Map value => 'Object · ${value.length} 项',
    List value => 'Array · ${value.length} 项',
    _ => jsonEncode(value),
  };

  Iterable<JsonTreeNode> get children sync* {
    final source = value;
    if (source is Map) {
      for (final entry in source.entries) {
        final key = jsonEncode(entry.key);
        yield JsonTreeNode(
          label: key,
          value: entry.value,
          path: '$path[$key]',
          depth: depth + 1,
        );
      }
    } else if (source is List) {
      for (var index = 0; index < source.length; index++) {
        yield JsonTreeNode(
          label: '[$index]',
          value: source[index],
          path: '$path[$index]',
          depth: depth + 1,
        );
      }
    }
  }

  String copyText(JsonNodeCopyAction action, int indentSpaces) {
    return switch (action) {
      JsonNodeCopyAction.value =>
        value is String ? value as String : jsonEncode(value),
      JsonNodeCopyAction.json => JsonEncoder.withIndent(
        ' ' * indentSpaces,
      ).convert(value),
      JsonNodeCopyAction.path => path,
    };
  }
}
