import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'image_file_info.dart';

class ImageInfoPage extends StatefulWidget {
  const ImageInfoPage({super.key});

  @override
  State<ImageInfoPage> createState() => _ImageInfoPageState();
}

class _ImageInfoPageState extends State<ImageInfoPage> {
  static const XTypeGroup _imageTypeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>[
      'png',
      'jpg',
      'jpeg',
      'webp',
      'gif',
      'bmp',
      'tiff',
      'tif',
    ],
    mimeTypes: <String>['image/*'],
  );

  final ImageFileInfoParser _parser = const ImageFileInfoParser();
  bool _isDraggingFile = false;
  bool _isLoading = false;
  ImageFileInfo? _info;
  String? _statusText;
  String? _errorText;
  final List<ImageFileInfo> _records = <ImageFileInfo>[];

  Future<void> _handlePickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_imageTypeGroup],
    );

    if (file == null) {
      return;
    }

    await _loadImageInfo(file.path);
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    final path = files
        .map((DropItem item) => item.path)
        .whereType<String>()
        .cast<String?>()
        .firstWhere(
          (String? value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );

    if (path == null) {
      setState(() {
        _errorText = '请拖入一个图片文件。';
        _statusText = null;
      });
      return;
    }

    await _loadImageInfo(path);
  }

  Future<void> _loadImageInfo(String path) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '正在读取图片信息...';
      _errorText = null;
    });

    try {
      final info = await _parser.parse(path);

      if (!mounted) {
        return;
      }

      setState(() {
        _info = info;
        _prependRecord(info);
        _statusText = '图片信息读取完成。';
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCopyPath() async {
    final info = _info;

    if (info == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: info.filePath));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制图片路径。';
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
      _statusText = '已复制图片摘要。';
      _errorText = null;
    });
  }

  void _handleSelectRecord(ImageFileInfo info) {
    setState(() {
      _info = info;
      _statusText = '已恢复最近记录。';
      _errorText = null;
    });
  }

  void _handleClear() {
    setState(() {
      _info = null;
      _statusText = null;
      _errorText = null;
    });
  }

  void _prependRecord(ImageFileInfo info) {
    _records.removeWhere(
      (ImageFileInfo record) => record.filePath == info.filePath,
    );
    _records.insert(0, info);

    if (_records.length > 8) {
      _records.removeRange(8, _records.length);
    }
  }

  String _buildSummaryText(ImageFileInfo info) {
    return [
      'File: ${info.fileName}',
      'Format: ${info.format}',
      'Dimensions: ${info.dimensionsText}',
      'Size: ${info.fileSizeText}',
      'Alpha: ${info.alphaText}',
      'Frames: ${info.frameCountText}',
      'Path: ${info.filePath}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _isDraggingFile
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '图片信息',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持选择或拖拽图片，快速查看尺寸、格式、文件大小和透明通道信息。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DropTarget(
                  onDragEntered: (_) {
                    setState(() {
                      _isDraggingFile = true;
                    });
                  },
                  onDragExited: (_) {
                    setState(() {
                      _isDraggingFile = false;
                    });
                  },
                  onDragDone: (DropDoneDetails details) async {
                    setState(() {
                      _isDraggingFile = false;
                    });
                    await _handleDropFiles(details.files);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                        width: _isDraggingFile ? 1.4 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7F6),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              _isLoading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.image_search_rounded,
                              size: 48,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isLoading ? '正在读取图片...' : '拖拽图片到这里',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF23313C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '支持 PNG、JPG、WebP、GIF、BMP、TIFF 等常见图片格式。',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF607180),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _handlePickFile,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: const Text('选择图片'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleClear,
                                icon: const Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 18,
                                ),
                                label: const Text('清空'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 420,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD8E2E8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _ImageInfoPanel(
                      info: _info,
                      records: _records,
                      statusText: _errorText ?? _statusText ?? '等待选择图片',
                      isError: _errorText != null,
                      onCopyPath: _info == null ? null : _handleCopyPath,
                      onCopySummary: _info == null ? null : _handleCopySummary,
                      onSelectRecord: _handleSelectRecord,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageInfoPanel extends StatelessWidget {
  const _ImageInfoPanel({
    required this.info,
    required this.records,
    required this.statusText,
    required this.isError,
    required this.onCopyPath,
    required this.onCopySummary,
    required this.onSelectRecord,
  });

  final ImageFileInfo? info;
  final List<ImageFileInfo> records;
  final String statusText;
  final bool isError;
  final VoidCallback? onCopyPath;
  final VoidCallback? onCopySummary;
  final ValueChanged<ImageFileInfo> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    final currentInfo = info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前图片',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 14),
        _StatusBanner(message: statusText, isError: isError),
        const SizedBox(height: 14),
        if (currentInfo != null) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopySummary,
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('复制摘要'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyPath,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('复制路径'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: ListView(
            children: [
              if (currentInfo == null)
                const SizedBox(height: 220, child: _ImageInfoEmptyState())
              else ...[
                _ImageInfoTile(label: '文件名', value: currentInfo.fileName),
                _ImageInfoTile(label: '尺寸', value: currentInfo.dimensionsText),
                _ImageInfoTile(label: '格式', value: currentInfo.format),
                _ImageInfoTile(label: '文件大小', value: currentInfo.fileSizeText),
                _ImageInfoTile(label: '透明信息', value: currentInfo.alphaText),
                _ImageInfoTile(label: '帧数', value: currentInfo.frameCountText),
                _ImageInfoTile(label: '路径', value: currentInfo.filePath),
              ],
              if (records.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ImageRecordSection(
                  records: records,
                  onSelectRecord: onSelectRecord,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageRecordSection extends StatelessWidget {
  const _ImageRecordSection({
    required this.records,
    required this.onSelectRecord,
  });

  final List<ImageFileInfo> records;
  final ValueChanged<ImageFileInfo> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近记录',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...records.map(
              (ImageFileInfo record) => _ImageRecordTile(
                info: record,
                onTap: () => onSelectRecord(record),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageRecordTile extends StatelessWidget {
  const _ImageRecordTile({required this.info, required this.onTap});

  final ImageFileInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              const Icon(
                Icons.image_search_rounded,
                color: Color(0xFF0F766E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${info.fileName} · ${info.dimensionsText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF23313C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ImageInfoEmptyState extends StatelessWidget {
  const _ImageInfoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '选择图片后会显示尺寸、格式、大小和透明通道信息。',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF708190),
          height: 1.6,
        ),
      ),
    );
  }
}

class _ImageInfoTile extends StatelessWidget {
  const _ImageInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF607180),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                value,
                style: const TextStyle(
                  color: Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
