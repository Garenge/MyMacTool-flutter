import 'package:flutter/material.dart';

import 'tool_catalog.dart';

class ToolSidebarItem extends StatelessWidget {
  const ToolSidebarItem({
    super.key,
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final ToolDefinition definition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF11212D)
        : const Color(0xFFE5EDF3);
    return Material(
      color: selected ? const Color(0xFFEAF7F6) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0x227DA9BC),
        child: SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(definition.icon, color: foreground, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    definition.title,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
