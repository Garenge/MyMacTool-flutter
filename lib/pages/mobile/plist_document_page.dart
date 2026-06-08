import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/path_utils.dart';
import 'plist_document_info.dart';

class PlistDocumentPage extends StatefulWidget {
  const PlistDocumentPage({
    super.key,
    this.initialPath,
    this.parser = const PlistDocumentParser(),
  });

  final String? initialPath;
  final PlistDocumentParsing parser;

  @override
  State<PlistDocumentPage> createState() => _PlistDocumentPageState();
}

class _PlistDocumentPageState extends State<PlistDocumentPage> {
  static const XTypeGroup _plistTypeGroup = XTypeGroup(
    label: 'plist',
    extensions: <String>['plist'],
    mimeTypes: <String>[
      'application/xml',
      'text/xml',
      'application/octet-stream',
    ],
  );

  final TextEditingController _searchController = TextEditingController();
  bool _isDraggingFile = false;
  bool _isLoading = false;
  PlistDocumentInfo? _info;
  String _searchText = '';
  String? _statusText;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _scheduleInitialLoad(widget.initialPath);
  }

  @override
  void didUpdateWidget(covariant PlistDocumentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialPath != oldWidget.initialPath) {
      _scheduleInitialLoad(widget.initialPath);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleInitialLoad(String? path) {
    if (path == null || path.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _loadPlist(path);
    });
  }

  Future<void> _handlePickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_plistTypeGroup],
    );

    if (file == null || !mounted) {
      return;
    }

    await _loadPlist(file.path);
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    final path = files
        .map((DropItem item) => item.path)
        .whereType<String>()
        .cast<String?>()
        .firstWhere(
          (String? value) => value != null && _isPlistPath(value),
          orElse: () => null,
        );

    if (path == null) {
      setState(() {
        _errorText = '请拖入一个 .plist 文件。';
        _statusText = null;
      });
      return;
    }

    await _loadPlist(path);
  }

  Future<void> _loadPlist(String path) async {
    if (_isLoading) {
      return;
    }

    if (!_isPlistPath(path)) {
      setState(() {
        _errorText = '当前仅支持 .plist 文件。';
        _statusText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '正在读取 plist...';
      _errorText = null;
    });

    try {
      final info = await widget.parser.parse(path);

      if (!mounted) {
        return;
      }

      setState(() {
        _info = info;
        _searchController.clear();
        _searchText = '';
        _statusText = '读取完成，共 ${info.itemCount} 个节点。';
        _errorText = null;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _info = null;
        _errorText = error.message;
        _statusText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _info = null;
        _errorText = '读取 plist 失败，请确认文件有效后重试。';
        _statusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCopyXml() async {
    final info = _info;

    if (info == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: info.xmlText));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制 XML plist。';
      _errorText = null;
    });
  }

  Future<void> _handleCopySummary() async {
    final info = _info;

    if (info == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _buildSummaryText(info)));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制 plist 摘要。';
      _errorText = null;
    });
  }

  Future<void> _handleCopyPath() async {
    final path = _info?.filePath;

    if (path == null || path.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: path));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制 plist 路径。';
      _errorText = null;
    });
  }

  String _buildSummaryText(PlistDocumentInfo info) {
    return [
      'Path: ${info.filePath}',
      'Root Type: ${info.root.type.label}',
      'Root Value: ${info.root.valueText}',
      'Nodes: ${info.itemCount}',
      'Top Level Keys: ${_topLevelTitles(info.root)}',
    ].join('\n');
  }

  String _topLevelTitles(PlistNode root) {
    if (root.children.isEmpty) {
      return '-';
    }

    return root.children
        .take(12)
        .map((PlistNode node) => node.title)
        .join(', ');
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  void _handleClear() {
    setState(() {
      _info = null;
      _searchController.clear();
      _searchText = '';
      _statusText = null;
      _errorText = null;
    });
  }

  bool _isPlistPath(String path) {
    return hasFileExtension(path, <String>['.plist']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plist查看器',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持选择或拖拽 XML / Binary plist，格式化为树形结构并搜索 key、path 或 value。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlistDropPanel(
                isDraggingFile: _isDraggingFile,
                isLoading: _isLoading,
                statusText: _statusText,
                errorText: _errorText,
                selectedPath: _info?.filePath,
                onDragEntered: () {
                  setState(() {
                    _isDraggingFile = true;
                  });
                },
                onDragExited: () {
                  setState(() {
                    _isDraggingFile = false;
                  });
                },
                onDropFiles: (List<DropItem> files) async {
                  setState(() {
                    _isDraggingFile = false;
                  });
                  await _handleDropFiles(files);
                },
                onPickFile: _handlePickFile,
                onClear: _handleClear,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _PlistResultPanel(
                  info: _info,
                  searchController: _searchController,
                  searchText: _searchText,
                  onSearchChanged: _handleSearchChanged,
                  onCopySummary: _handleCopySummary,
                  onCopyXml: _handleCopyXml,
                  onCopyPath: _handleCopyPath,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlistDropPanel extends StatelessWidget {
  const _PlistDropPanel({
    required this.isDraggingFile,
    required this.isLoading,
    required this.statusText,
    required this.errorText,
    required this.selectedPath,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDropFiles,
    required this.onPickFile,
    required this.onClear,
  });

  final bool isDraggingFile;
  final bool isLoading;
  final String? statusText;
  final String? errorText;
  final String? selectedPath;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final Future<void> Function(List<DropItem> files) onDropFiles;
  final VoidCallback onPickFile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDraggingFile
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return SizedBox(
      width: 350,
      child: DropTarget(
        onDragEntered: (_) => onDragEntered(),
        onDragExited: (_) => onDragExited(),
        onDragDone: (DropDoneDetails details) async {
          await onDropFiles(details.files);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: isDraggingFile ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F6),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.account_tree_rounded,
                    size: 46,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isLoading ? '正在读取...' : '拖拽 Plist 到这里',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF23313C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '支持 XML plist 和 binary plist 文件。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF607180),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: isLoading ? null : onPickFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onClear,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: const Text('清空'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: _DropPanelStatusList(
                    selectedPath: selectedPath,
                    statusText: statusText,
                    errorText: errorText,
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

class _DropPanelStatusList extends StatelessWidget {
  const _DropPanelStatusList({
    required this.selectedPath,
    required this.statusText,
    required this.errorText,
  });

  final String? selectedPath;
  final String? statusText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (selectedPath != null)
        _StatusBanner(
          message: selectedPath!,
          icon: Icons.description_rounded,
          isError: false,
        ),
      if (statusText != null) ...[
        if (selectedPath != null) const SizedBox(height: 10),
        _StatusBanner(
          message: statusText!,
          icon: Icons.check_circle_rounded,
          isError: false,
        ),
      ],
      if (errorText != null) ...[
        if (selectedPath != null || statusText != null)
          const SizedBox(height: 10),
        _StatusBanner(
          message: errorText!,
          icon: Icons.error_outline_rounded,
          isError: true,
        ),
      ],
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(child: Column(children: children));
  }
}

class _PlistResultPanel extends StatelessWidget {
  const _PlistResultPanel({
    required this.info,
    required this.searchController,
    required this.searchText,
    required this.onSearchChanged,
    required this.onCopySummary,
    required this.onCopyXml,
    required this.onCopyPath,
  });

  final PlistDocumentInfo? info;
  final TextEditingController searchController;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyXml;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    final info = this.info;

    if (info == null) {
      return const _EmptyResultPanel();
    }

    final visibleNodes = _collectVisibleNodes(info.root, searchText);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultHeader(
              itemCount: info.itemCount,
              visibleCount: visibleNodes.length,
              onCopySummary: onCopySummary,
              onCopyXml: onCopyXml,
              onCopyPath: onCopyPath,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: '搜索 key / path / value',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: visibleNodes.isEmpty
                  ? const Center(child: _MutedText('没有匹配的 plist 节点。'))
                  : ListView.separated(
                      itemCount: visibleNodes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final entry = visibleNodes[index];

                        return _PlistNodeTile(entry: entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_VisiblePlistNode> _collectVisibleNodes(
    PlistNode root,
    String searchText,
  ) {
    final entries = <_VisiblePlistNode>[];

    void visit(PlistNode node, int depth) {
      if (node.matches(searchText)) {
        entries.add(_VisiblePlistNode(node: node, depth: depth));
      }

      for (final child in node.children) {
        visit(child, depth + 1);
      }
    }

    visit(root, 0);
    return entries;
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.itemCount,
    required this.visibleCount,
    required this.onCopySummary,
    required this.onCopyXml,
    required this.onCopyPath,
  });

  final int itemCount;
  final int visibleCount;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyXml;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plist 节点',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF23313C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '显示 $visibleCount / $itemCount 个节点',
                  style: const TextStyle(
                    color: Color(0xFF607180),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onCopyPath,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('路径'),
            ),
            OutlinedButton.icon(
              onPressed: onCopySummary,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('复制摘要'),
            ),
            FilledButton.icon(
              onPressed: onCopyXml,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('复制 XML'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlistNodeTile extends StatelessWidget {
  const _PlistNodeTile({required this.entry});

  final _VisiblePlistNode entry;

  @override
  Widget build(BuildContext context) {
    final node = entry.node;
    final leftPadding = (entry.depth * 18).clamp(0, 96).toDouble();

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeBadge(type: node.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      node.title,
                      style: const TextStyle(
                        color: Color(0xFF23313C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      node.path,
                      style: const TextStyle(
                        color: Color(0xFF607180),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (node.valueText.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      SelectableText(
                        node.valueText,
                        style: const TextStyle(
                          color: Color(0xFF23313C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final PlistNodeType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1E8E4)),
      ),
      child: Text(
        type.label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF0F766E),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.isError,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final foreground = isError
        ? const Color(0xFF9F1239)
        : const Color(0xFF0F766E);
    final background = isError
        ? const Color(0xFFFFEEF2)
        : const Color(0xFFEAF7F6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResultPanel extends StatelessWidget {
  const _EmptyResultPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Center(
        child: Text(
          '选择 plist 后会显示 key、path、类型和值，并支持搜索。',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
    );
  }
}

class _VisiblePlistNode {
  const _VisiblePlistNode({required this.node, required this.depth});

  final PlistNode node;
  final int depth;
}
