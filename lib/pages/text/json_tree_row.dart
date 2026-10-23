import 'package:flutter/material.dart';

import 'json_tree_node.dart';

class JsonTreeRow extends StatelessWidget {
  const JsonTreeRow({
    super.key,
    required this.node,
    required this.expanded,
    required this.onToggle,
    required this.onCopy,
    required this.onExpandChildren,
    required this.onCollapseChildren,
  });

  final JsonTreeNode node;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<JsonNodeCopyAction> onCopy;
  final VoidCallback onExpandChildren;
  final VoidCallback onCollapseChildren;

  Color get _valueColor => switch (node.value) {
    String() => const Color(0xFF16745D),
    num() => const Color(0xFF2455A4),
    bool() => const Color(0xFF8C419D),
    _ => const Color(0xFF607180),
  };

  @override
  Widget build(BuildContext context) {
    final canExpand = node.childCount > 0;
    return Padding(
      padding: EdgeInsets.only(left: node.depth.clamp(0, 12) * 16.0),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: node.path,
              child: InkWell(
                onTap: canExpand ? onToggle : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _buildIndicator(canExpand),
                      Expanded(child: _buildLabel()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (node.value is List) _buildChildActions(),
          _buildMenu(),
        ],
      ),
    );
  }

  Widget _buildChildActions() {
    final enabled = node.hasExpandableChildren;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '展开子级 ${node.path}',
          icon: const Icon(Icons.unfold_more, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? onExpandChildren : null,
        ),
        IconButton(
          tooltip: '收起子级 ${node.path}',
          icon: const Icon(Icons.unfold_less, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? onCollapseChildren : null,
        ),
      ],
    );
  }

  Widget _buildIndicator(bool canExpand) {
    return SizedBox(
      width: 28,
      child: Icon(
        canExpand
            ? (expanded ? Icons.expand_more : Icons.chevron_right)
            : (node.isContainer ? Icons.data_object : Icons.circle),
        size: node.isContainer ? 18 : 6,
        color: const Color(0xFF607180),
      ),
    );
  }

  Widget _buildLabel() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${node.label}: ',
            style: const TextStyle(color: Color(0xFF31414F)),
          ),
          TextSpan(
            text: node.summary,
            style: TextStyle(color: _valueColor),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFamily: 'Menlo', fontSize: 13),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<JsonNodeCopyAction>(
      tooltip: '节点操作 ${node.path}',
      onSelected: onCopy,
      itemBuilder: (_) => const [
        PopupMenuItem(value: JsonNodeCopyAction.value, child: Text('复制值')),
        PopupMenuItem(value: JsonNodeCopyAction.json, child: Text('复制子 JSON')),
        PopupMenuItem(value: JsonNodeCopyAction.path, child: Text('复制路径')),
      ],
      icon: const Icon(Icons.more_horiz, size: 18),
    );
  }
}
