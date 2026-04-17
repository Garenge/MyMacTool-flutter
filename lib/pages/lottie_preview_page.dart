import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class _LottieFileRecord {
  const _LottieFileRecord({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.sizeInBytes,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  final int sizeInBytes;
}

class LottiePreviewPage extends StatefulWidget {
  const LottiePreviewPage({super.key});

  @override
  State<LottiePreviewPage> createState() => _LottiePreviewPageState();
}

class _LottiePreviewPageState extends State<LottiePreviewPage> {
  static const XTypeGroup _lottieJsonTypeGroup = XTypeGroup(
    label: 'lottie',
    extensions: <String>['json'],
    mimeTypes: <String>['application/json', 'text/json'],
  );

  final List<_LottieFileRecord> _files = <_LottieFileRecord>[];
  final Set<String> _selectedPaths = <String>{};
  bool _isDraggingFiles = false;
  String? _errorText;

  List<_LottieFileRecord> get _selectedFiles {
    return _files
        .where((_LottieFileRecord file) => _selectedPaths.contains(file.path))
        .toList(growable: false);
  }

  Future<void> _handleOpenFolder() async {
    final files = await openFiles(
      acceptedTypeGroups: <XTypeGroup>[_lottieJsonTypeGroup],
    );

    if (files.isEmpty) {
      return;
    }

    final records = await _collectFilesFromPaths(
      files.map((XFile file) => file.path).toList(growable: false),
    );

    if (!mounted) {
      return;
    }

    if (records.isEmpty) {
      setState(() {
        _files.clear();
        _selectedPaths.clear();
        _errorText = '当前文件夹下没有可预览的 Lottie JSON 文件。';
      });
      return;
    }

    setState(() {
      _replaceFiles(records);
      _errorText = null;
    });
  }

  Future<void> _handleDropFiles(List<DropItem> items) async {
    final paths = items
        .map((DropItem item) => item.path)
        .whereType<String>()
        .toList(growable: false);

    if (paths.isEmpty) {
      return;
    }

    final records = await _collectFilesFromPaths(paths);

    if (!mounted) {
      return;
    }

    if (records.isEmpty) {
      setState(() {
        _errorText = '未识别到可预览的 Lottie JSON 文件。';
      });
      return;
    }

    setState(() {
      _mergeFiles(records);
      _errorText = null;
    });
  }

  Future<List<_LottieFileRecord>> _collectFilesFromPaths(
    List<String> paths,
  ) async {
    final records = <_LottieFileRecord>[];

    for (final path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final entityType = FileSystemEntity.typeSync(path);

      if (entityType == FileSystemEntityType.directory) {
        records.addAll(await _collectFilesFromDirectory(path));
        continue;
      }

      if (_isSupportedLottiePath(path)) {
        final record = await _createRecord(path);

        if (record != null) {
          records.add(record);
        }
      }
    }

    records.sort(
      (_LottieFileRecord left, _LottieFileRecord right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

    return records;
  }

  Future<List<_LottieFileRecord>> _collectFilesFromDirectory(
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      return <_LottieFileRecord>[];
    }

    final entities = directory
        .listSync()
        .whereType<File>()
        .where((File file) => _isSupportedLottiePath(file.path))
        .toList(growable: false);
    final records = <_LottieFileRecord>[];

    for (final file in entities) {
      final record = await _createRecord(file.path);

      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  Future<_LottieFileRecord?> _createRecord(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    final stat = await file.stat();

    return _LottieFileRecord(
      path: path,
      name: _extractName(path),
      modifiedAt: stat.modified,
      sizeInBytes: stat.size,
    );
  }

  bool _isSupportedLottiePath(String path) {
    return path.toLowerCase().endsWith('.json');
  }

  String _extractName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  void _replaceFiles(List<_LottieFileRecord> records) {
    _files
      ..clear()
      ..addAll(records);
    _selectedPaths
      ..clear()
      ..addAll(records.map((_LottieFileRecord item) => item.path));
  }

  void _mergeFiles(List<_LottieFileRecord> records) {
    final nextMap = <String, _LottieFileRecord>{
      for (final file in _files) file.path: file,
    };

    for (final record in records) {
      nextMap[record.path] = record;
      _selectedPaths.add(record.path);
    }

    _files
      ..clear()
      ..addAll(nextMap.values);
    _files.sort(
      (_LottieFileRecord left, _LottieFileRecord right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
  }

  void _handleFileSelectionChanged(String path, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPaths.add(path);
      } else {
        _selectedPaths.remove(path);
      }

      _errorText = null;
    });
  }

  void _handleClear() {
    setState(() {
      _files.clear();
      _selectedPaths.clear();
      _errorText = null;
    });
  }

  void _handleSelectAll() {
    setState(() {
      _selectedPaths
        ..clear()
        ..addAll(_files.map((_LottieFileRecord file) => file.path));
      _errorText = null;
    });
  }

  bool get _areAllFilesSelected {
    return _files.isNotEmpty && _selectedPaths.length == _files.length;
  }

  void _handleInvertSelection() {
    setState(() {
      final nextSelection = _files
          .where(
            (_LottieFileRecord file) => !_selectedPaths.contains(file.path),
          )
          .map((_LottieFileRecord file) => file.path)
          .toSet();
      _selectedPaths
        ..clear()
        ..addAll(nextSelection);
      _errorText = null;
    });
  }

  void _handleReorderFiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final record = _files.removeAt(oldIndex);
      _files.insert(newIndex, record);
      _errorText = null;
    });
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '${sizeInBytes}B';
    }

    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
    }

    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final selectedFiles = _selectedFiles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: _LottiePreviewPane(
            files: selectedFiles,
            errorText: _errorText,
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 340,
          child: _LottieFileListPane(
            files: _files,
            selectedPaths: _selectedPaths,
            isDraggingFiles: _isDraggingFiles,
            onDragChanged: (bool value) {
              setState(() {
                _isDraggingFiles = value;
              });
            },
            onDropFiles: _handleDropFiles,
            onSelectionChanged: _handleFileSelectionChanged,
            onReorder: _handleReorderFiles,
            onOpenFiles: _handleOpenFolder,
            onToggleSelection: _areAllFilesSelected
                ? _handleInvertSelection
                : _handleSelectAll,
            selectionActionLabel: _areAllFilesSelected ? '反选' : '全选',
            selectionActionIcon: _areAllFilesSelected
                ? Icons.flip_rounded
                : Icons.done_all_rounded,
            onClear: _handleClear,
            formatTimestamp: _formatTimestamp,
            formatFileSize: _formatFileSize,
          ),
        ),
      ],
    );
  }
}

class _LottiePreviewPane extends StatelessWidget {
  const _LottiePreviewPane({required this.files, required this.errorText});

  final List<_LottieFileRecord> files;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lottie 预览',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF23313C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              files.isEmpty
                  ? '从右侧拖入文件或打开文件夹后，可在这里同时预览多个 Lottie 动画。'
                  : '当前已选中 ${files.length} 个文件，左侧会在同一画布中叠加播放预览。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607180),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 14),
              _LottieHintBanner(message: errorText!),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: files.isEmpty
                  ? const _LottieEmptyState()
                  : _LottieCompositePreview(files: files),
            ),
          ],
        ),
      ),
    );
  }
}

class _LottieCompositePreview extends StatelessWidget {
  const _LottieCompositePreview({required this.files});

  final List<_LottieFileRecord> files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E2E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LottieCompositeStage(
                files: files,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '当前为叠加渲染结果。图层顺序与右侧列表顺序一致，越靠后的文件越显示在上层。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF708190),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LottieCompositeStage extends StatelessWidget {
  const _LottieCompositeStage({
    required this.files,
    required this.borderRadius,
  });

  final List<_LottieFileRecord> files;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF5FBFA), Color(0xFFEAF2F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _PreviewGridBackground(),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 520,
                          height: 520,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              for (final file in files)
                                RepaintBoundary(
                                  child: Lottie.file(
                                    File(file.path),
                                    repeat: true,
                                    animate: true,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewGridBackground extends StatelessWidget {
  const _PreviewGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PreviewGridPainter());
  }
}

class _PreviewGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 24.0;
    final lightPaint = Paint()..color = const Color(0xFFF7FBFC);
    final darkPaint = Paint()..color = const Color(0xFFEAF2F5);

    for (var row = 0; row * cellSize < size.height; row += 1) {
      for (var column = 0; column * cellSize < size.width; column += 1) {
        final paint = (row + column).isEven ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(column * cellSize, row * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _LottieFileListPane extends StatelessWidget {
  const _LottieFileListPane({
    required this.files,
    required this.selectedPaths,
    required this.isDraggingFiles,
    required this.onDragChanged,
    required this.onDropFiles,
    required this.onSelectionChanged,
    required this.onReorder,
    required this.onOpenFiles,
    required this.onToggleSelection,
    required this.selectionActionLabel,
    required this.selectionActionIcon,
    required this.onClear,
    required this.formatTimestamp,
    required this.formatFileSize,
  });

  final List<_LottieFileRecord> files;
  final Set<String> selectedPaths;
  final bool isDraggingFiles;
  final ValueChanged<bool> onDragChanged;
  final Future<void> Function(List<DropItem> files) onDropFiles;
  final void Function(String path, bool isSelected) onSelectionChanged;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function() onOpenFiles;
  final VoidCallback onToggleSelection;
  final String selectionActionLabel;
  final IconData selectionActionIcon;
  final VoidCallback onClear;
  final String Function(DateTime value) formatTimestamp;
  final String Function(int value) formatFileSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDraggingFiles
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isDraggingFiles ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '文件列表',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF23313C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持多选 JSON 文件、拖拽导入和拖拽排序。列表越靠前越在底层，越靠后越在顶层。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF607180),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: DropTarget(
                onDragEntered: (_) => onDragChanged(true),
                onDragExited: (_) => onDragChanged(false),
                onDragDone: (DropDoneDetails details) async {
                  onDragChanged(false);
                  await onDropFiles(details.files);
                },
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: files.isEmpty
                          ? const _LottieListEmptyState()
                          : Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(canvasColor: Colors.transparent),
                              child: ReorderableListView.builder(
                                padding: const EdgeInsets.all(10),
                                buildDefaultDragHandles: false,
                                itemCount: files.length,
                                onReorder: onReorder,
                                proxyDecorator:
                                    (
                                      Widget child,
                                      int index,
                                      Animation<double> animation,
                                    ) {
                                      return Material(
                                        color: Colors.transparent,
                                        child: child,
                                      );
                                    },
                                itemBuilder: (BuildContext context, int index) {
                                  final file = files[index];
                                  final isSelected = selectedPaths.contains(
                                    file.path,
                                  );

                                  return Padding(
                                    key: ValueKey<String>(file.path),
                                    padding: EdgeInsets.only(
                                      bottom: index == files.length - 1 ? 0 : 8,
                                    ),
                                    child: _LottieFileListItem(
                                      file: file,
                                      index: index,
                                      isSelected: isSelected,
                                      subtitle:
                                          '${formatFileSize(file.sizeInBytes)}  ·  ${formatTimestamp(file.modifiedAt)}',
                                      onChanged: (bool? value) {
                                        onSelectionChanged(
                                          file.path,
                                          value ?? false,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    if (isDraggingFiles)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0x160F766E),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF0F766E),
                                width: 1.4,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '松开鼠标即可导入 Lottie 文件',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF0F766E),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 140,
                  child: OutlinedButton.icon(
                    onPressed: onToggleSelection,
                    icon: Icon(selectionActionIcon),
                    label: Text(selectionActionLabel),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('清空'),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: FilledButton.icon(
                    onPressed: onOpenFiles,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('选择文件'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LottieFileListItem extends StatelessWidget {
  const _LottieFileListItem({
    required this.file,
    required this.index,
    required this.isSelected,
    required this.subtitle,
    required this.onChanged,
  });

  final _LottieFileRecord file;
  final int index;
  final bool isSelected;
  final String subtitle;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFEAF7F6) : const Color(0xFFF7FAFB),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              value: isSelected,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              onChanged: onChanged,
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF31414F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '#${index + 1}  ·  $subtitle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: isSelected
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF7B8A97),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LottieHintBanner extends StatelessWidget {
  const _LottieHintBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0B6B2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFC63C34)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8D2A24),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LottieEmptyState extends StatelessWidget {
  const _LottieEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 48,
            color: const Color(0xFF8A9AA8),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无预览内容',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF31414F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '从右侧拖入多个 Lottie JSON 文件，或点击“打开文件夹”批量加载。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF708190),
            ),
          ),
        ],
      ),
    );
  }
}

class _LottieListEmptyState extends StatelessWidget {
  const _LottieListEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_present_rounded,
              size: 42,
              color: const Color(0xFF8A9AA8),
            ),
            const SizedBox(height: 12),
            Text(
              '拖拽文件到这里',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF31414F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持拖入多个 JSON 文件，也可以直接拖入一个文件夹。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF708190),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
