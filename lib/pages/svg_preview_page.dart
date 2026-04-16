import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _SvgHistoryRecord {
  const _SvgHistoryRecord({
    required this.id,
    required this.label,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String content;
  final DateTime createdAt;
}

class SvgPreviewPage extends StatefulWidget {
  const SvgPreviewPage({super.key});

  @override
  State<SvgPreviewPage> createState() => _SvgPreviewPageState();
}

class _SvgPreviewPageState extends State<SvgPreviewPage> {
  static const double _minPreviewScale = 0.5;
  static const double _maxPreviewScale = 5;
  static const double _previewScaleStep = 0.25;

  final TextEditingController _svgController = TextEditingController();
  final List<_SvgHistoryRecord> _historyRecords = <_SvgHistoryRecord>[];
  String _renderedSvg = '';
  String? _errorText;
  bool _isDraggingFile = false;
  double _previewScale = 1;
  OverlayEntry? _hudEntry;
  Timer? _hudTimer;

  @override
  void dispose() {
    _hudTimer?.cancel();
    _hudEntry?.remove();
    _svgController.dispose();
    super.dispose();
  }

  void _handleRender() {
    _applySvgSource(
      _svgController.text,
      historyLabel: '手动生成',
      hudMessage: '生成成功',
    );
  }

  void _handleClear() {
    setState(() {
      _svgController.clear();
      _renderedSvg = '';
      _errorText = null;
      _previewScale = 1;
    });
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    if (files.isEmpty) {
      return;
    }

    final file = files.first;
    final fileName = file.name;

    try {
      final svgSource = await file.readAsString();

      if (!mounted) {
        return;
      }

      _applySvgSource(
        svgSource,
        historyLabel: '拖拽导入',
        hudMessage: '导入成功',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '读取拖入文件失败：$fileName';
      });
    }
  }

  Future<void> _handleOpenFile() async {
    const typeGroup = XTypeGroup(
      label: 'text',
      extensions: <String>[
        'txt',
        'svg',
        'xml',
        'json',
        'md',
        'yaml',
        'yml',
        'html',
        'css',
        'js',
        'ts',
      ],
      mimeTypes: <String>[
        'text/plain',
        'image/svg+xml',
        'application/xml',
        'text/xml',
        'application/json',
        'text/markdown',
        'text/html',
        'text/css',
        'application/javascript',
      ],
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

    if (file == null) {
      if (!mounted) {
        return;
      }

      return;
    }

    try {
      final fileContent = await file.readAsString();

      if (!mounted) {
        return;
      }

      _applySvgSource(
        fileContent,
        historyLabel: '文件导入',
        hudMessage: '导入成功',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '读取文件失败：${file.name}';
      });
    }
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text;

    if (clipboardText == null || clipboardText.trim().isEmpty) {
      return;
    }

    _applySvgSource(
      clipboardText,
      historyLabel: '剪切板粘贴',
      hudMessage: '粘贴成功',
    );
  }

  void _handleHistorySelected(_SvgHistoryRecord record) {
    _applySvgSource(
      record.content,
      historyLabel: record.label,
      hudMessage: '已恢复记录',
      addToHistory: false,
    );
  }

  void _applySvgSource(
    String source, {
    required String historyLabel,
    required String hudMessage,
    bool addToHistory = true,
  }) {
    final normalizedSource = source.trim();

    setState(() {
      _svgController.text = source;

      if (normalizedSource.isEmpty) {
        _renderedSvg = '';
        _errorText = '内容为空，无法生成预览。';
        _previewScale = 1;
        return;
      }

      _renderedSvg = normalizedSource;
      _errorText = null;
      _previewScale = 1;

      if (addToHistory) {
        _rememberHistory(label: historyLabel, content: source);
      }
    });

    if (normalizedSource.isNotEmpty) {
      _showHud(hudMessage);
    }
  }

  void _rememberHistory({
    required String label,
    required String content,
  }) {
    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      return;
    }

    _historyRecords.removeWhere(
      (record) => record.content.trim() == normalizedContent,
    );
    _historyRecords.insert(
      0,
      _SvgHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        content: content,
        createdAt: DateTime.now(),
      ),
    );

    if (_historyRecords.length > 6) {
      _historyRecords.removeRange(6, _historyRecords.length);
    }
  }

  void _showHud(String message) {
    _hudTimer?.cancel();
    _hudEntry?.remove();

    final overlay = Overlay.of(context);
    _hudEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xE611212D),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_hudEntry!);

    _hudTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }

      _hudEntry?.remove();
      _hudEntry = null;
      _hudTimer = null;
    });
  }

  String _formatHistoryTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  void _handlePreviewZoomIn() {
    _updatePreviewScale(_previewScale + _previewScaleStep);
  }

  void _handlePreviewZoomOut() {
    _updatePreviewScale(_previewScale - _previewScaleStep);
  }

  void _handlePreviewZoomReset() {
    _updatePreviewScale(1);
  }

  void _handlePreviewPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _renderedSvg.isEmpty) {
      return;
    }

    final nextScale = event.scrollDelta.dy < 0
        ? _previewScale + _previewScaleStep
        : _previewScale - _previewScaleStep;

    _updatePreviewScale(nextScale);
  }

  void _updatePreviewScale(double nextScale) {
    setState(() {
      _previewScale = nextScale.clamp(_minPreviewScale, _maxPreviewScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '将 SVG 源码粘贴到输入框，点击确定后在下方渲染窗口查看效果。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF52606D),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _SvgDropInputPanel(
                        controller: _svgController,
                        isDraggingFile: _isDraggingFile,
                        onDragChanged: (isDraggingFile) {
                          setState(() {
                            _isDraggingFile = isDraggingFile;
                          });
                        },
                        onDropFiles: _handleDropFiles,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '支持将 SVG 文件直接拖入左侧区域，内容会自动填充并立即渲染。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF708190),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: _handleOpenFile,
                          child: const Text('打开文件'),
                        ),
                        OutlinedButton(
                          onPressed: _handlePaste,
                          child: const Text('粘贴'),
                        ),
                        FilledButton(
                          onPressed: _handleRender,
                          child: const Text('确定'),
                        ),
                        OutlinedButton(
                          onPressed: _handleClear,
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    if (_historyRecords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SvgHistoryList(
                        records: _historyRecords,
                        formatTime: _formatHistoryTime,
                        onSelected: _handleHistorySelected,
                      ),
                    ],
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _errorText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _PreviewPanel(
                  renderedSvg: _renderedSvg,
                  previewScale: _previewScale,
                  onZoomIn: _handlePreviewZoomIn,
                  onZoomOut: _handlePreviewZoomOut,
                  onZoomReset: _handlePreviewZoomReset,
                  onPointerSignal: _handlePreviewPointerSignal,
                  onRenderError: (error) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _errorText = 'SVG 渲染失败，请检查源码格式。';
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SvgHistoryList extends StatelessWidget {
  const _SvgHistoryList({
    required this.records,
    required this.formatTime,
    required this.onSelected,
  });

  final List<_SvgHistoryRecord> records;
  final String Function(DateTime value) formatTime;
  final ValueChanged<_SvgHistoryRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近记录',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF31414F),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final record in records)
              ActionChip(
                key: ValueKey<String>(record.id),
                onPressed: () => onSelected(record),
                avatar: const Icon(Icons.history_rounded, size: 16),
                label: Text('${record.label} ${formatTime(record.createdAt)}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _SvgDropInputPanel extends StatelessWidget {
  const _SvgDropInputPanel({
    required this.controller,
    required this.isDraggingFile,
    required this.onDragChanged,
    required this.onDropFiles,
  });

  final TextEditingController controller;
  final bool isDraggingFile;
  final ValueChanged<bool> onDragChanged;
  final Future<void> Function(List<DropItem> files) onDropFiles;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDraggingFile
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return DropTarget(
      onDragEntered: (_) => onDragChanged(true),
      onDragExited: (_) => onDragChanged(false),
      onDragDone: (details) async {
        onDragChanged(false);
        await onDropFiles(details.files);
      },
      child: Stack(
        children: [
          TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: '<svg viewBox="0 0 120 120">...</svg>',
              labelText: 'SVG 源码',
              alignLabelWithHint: true,
              filled: true,
              fillColor: const Color(0xFFF7FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDraggingFile
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF7FB8B3),
                  width: 1.4,
                ),
              ),
            ),
          ),
          if (isDraggingFile)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x140F766E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF0F766E),
                      width: 1.4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '松开鼠标即可导入文件内容',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0F766E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.renderedSvg,
    required this.previewScale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.onPointerSignal,
    required this.onRenderError,
  });

  final String renderedSvg;
  final double previewScale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;
  final ValueChanged<PointerSignalEvent> onPointerSignal;
  final ValueChanged<Object> onRenderError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _PreviewToolbar(
              previewScale: previewScale,
              isEnabled: renderedSvg.isNotEmpty,
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
              onZoomReset: onZoomReset,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Listener(
                onPointerSignal: onPointerSignal,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      border: Border.all(color: const Color(0xFFD8E2E8)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (renderedSvg.isEmpty) {
                          return const Center(child: _PreviewPlaceholder());
                        }

                        final frameWidth = (constraints.maxWidth - 64).clamp(
                          160.0,
                          constraints.maxWidth,
                        );
                        final frameHeight = (constraints.maxHeight - 64).clamp(
                          160.0,
                          constraints.maxHeight,
                        );

                        return _PreviewViewport(
                          contentToken: renderedSvg,
                          frameWidth: frameWidth,
                          frameHeight: frameHeight,
                          previewScale: previewScale,
                          child: _PreviewContentFrame(
                            child: SvgPicture.string(
                              renderedSvg,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                onRenderError(error);
                                return const _PreviewErrorState();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewViewport extends StatefulWidget {
  const _PreviewViewport({
    required this.contentToken,
    required this.frameWidth,
    required this.frameHeight,
    required this.previewScale,
    required this.child,
  });

  final String contentToken;
  final double frameWidth;
  final double frameHeight;
  final double previewScale;
  final Widget child;

  @override
  State<_PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends State<_PreviewViewport> {
  Offset _panOffset = Offset.zero;

  @override
  void didUpdateWidget(covariant _PreviewViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.contentToken != widget.contentToken) {
      setState(() {
        _panOffset = Offset.zero;
      });
      return;
    }

    if (oldWidget.previewScale != widget.previewScale) {
      final nextOffset = _clampOffset(_panOffset);

      if (nextOffset != _panOffset) {
        setState(() {
          _panOffset = nextOffset;
        });
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.previewScale <= 1) {
      return;
    }

    setState(() {
      _panOffset = _clampOffset(_panOffset + details.delta);
    });
  }

  Offset _clampOffset(Offset offset) {
    if (widget.previewScale <= 1) {
      return Offset.zero;
    }

    final horizontalExtent =
        ((widget.frameWidth * widget.previewScale) - widget.frameWidth) / 2;
    final verticalExtent =
        ((widget.frameHeight * widget.previewScale) - widget.frameHeight) / 2;

    return Offset(
      offset.dx.clamp(-horizontalExtent, horizontalExtent),
      offset.dy.clamp(-verticalExtent, verticalExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      child: ClipRect(
        child: Center(
          child: Transform.translate(
            offset: _panOffset,
            child: Transform.scale(
              scale: widget.previewScale,
              child: SizedBox(
                width: widget.frameWidth,
                height: widget.frameHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewContentFrame extends StatelessWidget {
  const _PreviewContentFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7FB8B3),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        Positioned(
          left: 16,
          top: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFB7D8D3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                '图片有效区域',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar({
    required this.previewScale,
    required this.isEnabled,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
  });

  final double previewScale;
  final bool isEnabled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        Text(
          '渲染预览',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF31414F),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PreviewToolbarButton(
              tooltip: '缩小',
              icon: Icons.zoom_out_rounded,
              isEnabled: isEnabled,
              onPressed: onZoomOut,
            ),
            Text(
              '${(previewScale * 100).round()}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF52606D),
                fontWeight: FontWeight.w600,
              ),
            ),
            _PreviewToolbarButton(
              tooltip: '放大',
              icon: Icons.zoom_in_rounded,
              isEnabled: isEnabled,
              onPressed: onZoomIn,
            ),
            TextButton(
              onPressed: isEnabled ? onZoomReset : null,
              child: const Text('重置'),
            ),
          ],
        ),
        Text(
          '支持滚轮缩放，最大可到 500%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF708190),
          ),
        ),
      ],
    );
  }
}

class _PreviewToolbarButton extends StatelessWidget {
  const _PreviewToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.isEnabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFEAF2F6),
        foregroundColor: const Color(0xFF31414F),
        disabledBackgroundColor: const Color(0xFFF0F4F7),
        disabledForegroundColor: const Color(0xFF9AA9B5),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_outlined,
          size: 44,
          color: const Color(0xFF8A9AA8),
        ),
        const SizedBox(height: 12),
        Text(
          '渲染结果将在这里显示',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF31414F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '输入 SVG 源码并点击“确定”后即可预览。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7C8C),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  const _PreviewErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 44,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          'SVG 渲染失败',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF31414F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请检查标签、属性和闭合格式后再重试。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7C8C),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
