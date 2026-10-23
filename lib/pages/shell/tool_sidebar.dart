import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tool_catalog.dart';
import 'tool_sidebar_item.dart';

class ToolSidebar extends StatefulWidget {
  const ToolSidebar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
  });

  final ToolItem selectedTool;
  final ValueChanged<ToolItem> onToolSelected;

  @override
  State<ToolSidebar> createState() => ToolSidebarState();
}

class ToolSidebarState extends State<ToolSidebar> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  final _collapsed = <ToolCategory>{};
  final _itemKeys = {for (final tool in ToolItem.values) tool: GlobalKey()};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _revealSelection();
  }

  @override
  void didUpdateWidget(covariant ToolSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTool != widget.selectedTool) {
      _collapsed.remove(definitionFor(widget.selectedTool).category);
      _searchController.clear();
      _query = '';
      _revealSelection();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void focusSearch() {
    _searchFocus.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _itemKeys[widget.selectedTool]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        Scrollable.ensureVisible(
          context,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _updateSearch(String value) {
    setState(() => _query = value);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF11212D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSearch(),
          const SizedBox(height: 12),
          Expanded(child: _buildTools()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _clearSearch();
          _searchFocus.unfocus();
        },
      },
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _updateSearch,
        style: const TextStyle(color: Color(0xFFE5EDF3), fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索工具  ⌘K',
          hintStyle: const TextStyle(color: Color(0xFF9AAEBC)),
          prefixIcon: const Icon(Icons.search, size: 18),
          prefixIconColor: const Color(0xFF9AAEBC),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: '清除搜索',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close, size: 16),
                  color: const Color(0xFF9AAEBC),
                ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF1A2E3B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTools() {
    final groups = {
      for (final category in ToolCategory.values)
        category: matchingTools(category, _query),
    }..removeWhere((_, tools) => tools.isEmpty);
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: groups.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '未找到匹配的工具',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9AAEBC)),
                  ),
                ),
              ]
            : [
                for (final entry in groups.entries)
                  _buildGroup(entry.key, entry.value),
              ],
      ),
    );
  }

  Widget _buildGroup(ToolCategory category, List<ToolDefinition> tools) {
    final expanded = _query.trim().isNotEmpty || !_collapsed.contains(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGroupHeader(category, expanded),
          if (expanded)
            for (final tool in tools)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: ToolSidebarItem(
                  key: _itemKeys[tool.tool],
                  definition: tool,
                  selected: tool.tool == widget.selectedTool,
                  onTap: () => widget.onToolSelected(tool.tool),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(ToolCategory category, bool expanded) {
    return Semantics(
      expanded: expanded,
      child: TextButton(
        onPressed: _query.trim().isNotEmpty
            ? null
            : () => setState(() {
                if (!_collapsed.remove(category)) _collapsed.add(category);
              }),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9AAEBC),
          disabledForegroundColor: const Color(0xFF9AAEBC),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(category.title, style: const TextStyle(fontSize: 12)),
            ),
            Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}
