import 'package:flutter/material.dart';

import 'json_tree_node.dart';
import 'json_tree_row.dart';

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    super.key,
    required this.value,
    required this.indentSpaces,
    required this.onCopy,
  });

  final Object? value;
  final int indentSpaces;
  final void Function(String text, String message) onCopy;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  final Set<String> _expandedPaths = {r'$'};
  late List<JsonTreeNode> _visibleNodes;

  @override
  void initState() {
    super.initState();
    _rebuildNodes();
  }

  @override
  void didUpdateWidget(covariant JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.value, widget.value)) {
      _expandedPaths
        ..clear()
        ..add(r'$');
      _rebuildNodes();
    }
  }

  void _rebuildNodes() {
    final pending = <Iterator<JsonTreeNode>>[
      [JsonTreeNode(label: r'$', value: widget.value)].iterator,
    ];
    _visibleNodes = [];
    while (pending.isNotEmpty) {
      if (!pending.last.moveNext()) {
        pending.removeLast();
        continue;
      }
      final node = pending.last.current;
      _visibleNodes.add(node);
      if (_expandedPaths.contains(node.path) && node.childCount > 0) {
        pending.add(node.children.iterator);
      }
    }
  }

  void _toggleNode(JsonTreeNode node) {
    setState(() {
      if (!_expandedPaths.remove(node.path)) {
        _expandedPaths.add(node.path);
      }
      _rebuildNodes();
    });
  }

  void _copyNode(JsonTreeNode node, JsonNodeCopyAction action) {
    final message = switch (action) {
      JsonNodeCopyAction.value => '已复制节点值。',
      JsonNodeCopyAction.json => '已复制子 JSON。',
      JsonNodeCopyAction.path => '已复制节点路径。',
    };
    widget.onCopy(node.copyText(action, widget.indentSpaces), message);
  }

  void _setChildrenExpanded(JsonTreeNode node, bool expanded) {
    setState(() {
      _expandedPaths.add(node.path);
      for (final child in node.children) {
        if (child.childCount == 0) continue;
        if (expanded) {
          _expandedPaths.add(child.path);
        } else {
          _expandedPaths.remove(child.path);
        }
      }
      _rebuildNodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _visibleNodes.length,
      itemBuilder: (context, index) {
        final node = _visibleNodes[index];
        return JsonTreeRow(
          key: ValueKey(node.path),
          node: node,
          expanded: _expandedPaths.contains(node.path),
          onToggle: () => _toggleNode(node),
          onCopy: (action) => _copyNode(node, action),
          onExpandChildren: () => _setChildrenExpanded(node, true),
          onCollapseChildren: () => _setChildrenExpanded(node, false),
        );
      },
    );
  }
}
