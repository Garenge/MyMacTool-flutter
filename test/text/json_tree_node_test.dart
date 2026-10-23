import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/text/json_tree_node.dart';

void main() {
  test('node paths escape object keys and retain array indexes', () {
    final root = JsonTreeNode(
      label: r'$',
      value: {
        'a.b["x"]\\\n': [
          {'id': 7},
        ],
      },
    );
    final field = root.children.single;
    final item = field.children.single;
    final id = item.children.single;

    expect(field.path, '\$[${jsonEncode('a.b["x"]\\\n')}]');
    expect(item.path, '${field.path}[0]');
    expect(id.path, '${item.path}["id"]');
    expect(id.copyText(JsonNodeCopyAction.path, 2), id.path);
  });

  test('copy value preserves raw strings while copy JSON quotes them', () {
    const node = JsonTreeNode(label: 'message', value: 'hello\n"world"');

    expect(node.copyText(JsonNodeCopyAction.value, 2), 'hello\n"world"');
    expect(
      jsonDecode(node.copyText(JsonNodeCopyAction.json, 4)),
      'hello\n"world"',
    );
    const object = JsonTreeNode(label: 'object', value: {'id': 1});
    expect(object.copyText(JsonNodeCopyAction.value, 2), '{"id":1}');
    expect(object.copyText(JsonNodeCopyAction.json, 4), '{\n    "id": 1\n}');
  });

  test('null and empty containers have valid summaries and no children', () {
    for (final value in [null, <String, Object?>{}, <Object?>[]]) {
      final node = JsonTreeNode(label: r'$', value: value);
      expect(node.children, isEmpty);
      expect(node.childCount, 0);
    }
    expect(const JsonTreeNode(label: r'$', value: null).summary, 'null');
  });
}
