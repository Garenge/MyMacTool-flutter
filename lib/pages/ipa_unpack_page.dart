import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _IpaUnpackRecord {
  const _IpaUnpackRecord({
    required this.id,
    required this.filePath,
    required this.outputDirectoryPath,
    required this.createdAt,
  });

  final String id;
  final String filePath;
  final String outputDirectoryPath;
  final DateTime createdAt;
}

class IpaUnpackPage extends StatefulWidget {
  const IpaUnpackPage({super.key});

  @override
  State<IpaUnpackPage> createState() => _IpaUnpackPageState();
}

class _IpaUnpackPageState extends State<IpaUnpackPage> {
  static const XTypeGroup _ipaTypeGroup = XTypeGroup(
    label: 'ipa',
    extensions: <String>['ipa'],
    mimeTypes: <String>['application/octet-stream', 'application/zip'],
  );

  bool _isDraggingFile = false;
  bool _isUnpacking = false;
  String? _selectedFilePath;
  String? _outputDirectoryPath;
  String? _statusText;
  String? _errorText;
  final List<_IpaUnpackRecord> _records = <_IpaUnpackRecord>[];

  Future<void> _handlePickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_ipaTypeGroup],
    );

    if (file == null) {
      return;
    }

    await _unpackIpa(file.path);
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    final path = files
        .map((DropItem item) => item.path)
        .whereType<String>()
        .cast<String?>()
        .firstWhere(
          (String? value) => value != null && _isIpaPath(value),
          orElse: () => null,
        );

    if (path == null) {
      setState(() {
        _errorText = '请拖入一个 .ipa 文件。';
      });
      return;
    }

    await _unpackIpa(path);
  }

  Future<void> _unpackIpa(String path) async {
    if (_isUnpacking) {
      return;
    }

    if (!_isIpaPath(path)) {
      setState(() {
        _errorText = '当前仅支持解析 .ipa 文件。';
      });
      return;
    }

    final ipaFile = File(path);

    if (!ipaFile.existsSync()) {
      setState(() {
        _errorText = '文件不存在，请重新选择。';
      });
      return;
    }

    setState(() {
      _isUnpacking = true;
      _selectedFilePath = path;
      _statusText = '正在解析并解压 IPA...';
      _errorText = null;
    });

    try {
      final outputDirectory = await _extractToTempDirectory(ipaFile);
      await _openDirectory(outputDirectory.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _outputDirectoryPath = outputDirectory.path;
        _statusText = '解析完成，已自动打开输出目录。';
        _prependRecord(
          _IpaUnpackRecord(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            filePath: path,
            outputDirectoryPath: outputDirectory.path,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'IPA 解析失败，请确认文件有效后重试。';
        _statusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUnpacking = false;
        });
      }
    }
  }

  Future<Directory> _extractToTempDirectory(File ipaFile) async {
    final tempRoot = await Directory.systemTemp.createTemp('mytools_ipa_');
    final baseName = _stripFileExtension(_fileNameOf(ipaFile.path));
    final outputDirectory = Directory('${tempRoot.path}/$baseName');
    await outputDirectory.create(recursive: true);

    final inputStream = InputFileStream(ipaFile.path);

    try {
      final archive = ZipDecoder().decodeStream(inputStream);

      for (final file in archive) {
        final outputPath = '${outputDirectory.path}/${file.name}';

        if (file.isFile) {
          final outputFile = File(outputPath);
          await outputFile.parent.create(recursive: true);
          final outputStream = OutputFileStream(outputFile.path);
          file.writeContent(outputStream);
          await outputStream.close();
          continue;
        }

        await Directory(outputPath).create(recursive: true);
      }
    } finally {
      await inputStream.close();
    }

    return outputDirectory;
  }

  Future<void> _openDirectory(String path) async {
    if (Platform.isMacOS) {
      final result = await Process.run('open', <String>[path]);

      if (result.exitCode != 0) {
        throw ProcessException('open', <String>[path], '${result.stderr}');
      }

      return;
    }

    throw UnsupportedError('当前仅支持在 macOS 上自动打开输出目录。');
  }

  bool _isIpaPath(String path) {
    return path.toLowerCase().endsWith('.ipa');
  }

  void _prependRecord(_IpaUnpackRecord record) {
    _records.removeWhere(
      (_IpaUnpackRecord item) =>
          item.outputDirectoryPath == record.outputDirectoryPath,
    );
    _records.insert(0, record);
  }

  bool _directoryExists(String path) {
    return Directory(path).existsSync();
  }

  Future<void> _handleOpenRecordDirectory(_IpaUnpackRecord record) async {
    if (!_directoryExists(record.outputDirectoryPath)) {
      setState(() {
        _errorText = '记录对应的输出目录已不存在。';
      });
      return;
    }

    try {
      await _openDirectory(record.outputDirectoryPath);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFilePath = record.filePath;
        _outputDirectoryPath = record.outputDirectoryPath;
        _statusText = '已重新打开历史解析目录。';
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '打开历史目录失败，请稍后重试。';
      });
    }
  }

  Future<void> _handleCopyRecordDirectory(_IpaUnpackRecord record) async {
    await Clipboard.setData(ClipboardData(text: record.outputDirectoryPath));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制记录目录路径。';
      _errorText = null;
    });
  }

  Future<void> _handleOpenCurrentFileDirectory() async {
    final filePath = _selectedFilePath;

    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final directory = File(filePath).parent;

    if (!directory.existsSync()) {
      setState(() {
        _errorText = '当前文件所在目录不存在。';
      });
      return;
    }

    try {
      await _openDirectory(directory.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = '已打开当前文件所在目录。';
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '打开当前文件所在目录失败。';
      });
    }
  }

  Future<void> _handleOpenOutputDirectory() async {
    final outputDirectoryPath = _outputDirectoryPath;

    if (outputDirectoryPath == null || outputDirectoryPath.isEmpty) {
      return;
    }

    if (!_directoryExists(outputDirectoryPath)) {
      setState(() {
        _errorText = '输出目录已不存在。';
      });
      return;
    }

    try {
      await _openDirectory(outputDirectoryPath);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = '已打开当前输出目录。';
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '打开当前输出目录失败。';
      });
    }
  }

  String _fileNameOf(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _stripFileExtension(String value) {
    final dotIndex = value.lastIndexOf('.');

    if (dotIndex <= 0) {
      return value;
    }

    return value.substring(0, dotIndex);
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
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
          'IPA解析',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '拖拽或选择一个 .ipa 文件后，工具会自动解压到临时目录，并在完成后打开输出文件夹。',
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
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 36,
                            ),
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
                                    _isUnpacking
                                        ? Icons.hourglass_top_rounded
                                        : Icons.archive_rounded,
                                    size: 48,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _isUnpacking
                                      ? '正在解析 IPA...'
                                      : '拖拽一个 IPA 文件到这里',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF23313C),
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isUnpacking
                                      ? '请稍候，完成后会自动打开输出目录。'
                                      : '也可以点击下方按钮直接选择一个 .ipa 文件。',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF607180),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilledButton.icon(
                                  onPressed: _isUnpacking
                                      ? null
                                      : _handlePickFile,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('选择IPA文件'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 340,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFB),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFD8E2E8)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '当前结果',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF23313C),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _InfoBlock(
                                title: '当前文件',
                                content: _selectedFilePath ?? '尚未选择 IPA 文件',
                                actionLabel: '打开目录',
                                onTap: _selectedFilePath == null
                                    ? null
                                    : _handleOpenCurrentFileDirectory,
                              ),
                              const SizedBox(height: 12),
                              _InfoBlock(
                                title: '输出目录',
                                content: _outputDirectoryPath ?? '解析完成后会显示在这里',
                                actionLabel: '打开目录',
                                onTap: _outputDirectoryPath == null
                                    ? null
                                    : _handleOpenOutputDirectory,
                              ),
                              const SizedBox(height: 12),
                              _InfoBlock(
                                title: '状态',
                                content: _errorText ?? _statusText ?? '等待操作',
                                isError: _errorText != null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 360,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD8E2E8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '解析记录',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF23313C),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _records.isEmpty
                              ? const _RecordEmptyState()
                              : ListView.separated(
                                  itemCount: _records.length,
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          const SizedBox(height: 10),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final record = _records[index];

                                        return _IpaRecordCard(
                                          record: record,
                                          isDirectoryAvailable:
                                              _directoryExists(
                                                record.outputDirectoryPath,
                                              ),
                                          formatTime: _formatTimestamp,
                                          fileNameOf: _fileNameOf,
                                          onCopyDirectory: () {
                                            _handleCopyRecordDirectory(record);
                                          },
                                          onOpenDirectory: () {
                                            _handleOpenRecordDirectory(record);
                                          },
                                        );
                                      },
                                ),
                        ),
                      ],
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

class _IpaRecordCard extends StatelessWidget {
  const _IpaRecordCard({
    required this.record,
    required this.isDirectoryAvailable,
    required this.formatTime,
    required this.fileNameOf,
    required this.onCopyDirectory,
    required this.onOpenDirectory,
  });

  final _IpaUnpackRecord record;
  final bool isDirectoryAvailable;
  final String Function(DateTime value) formatTime;
  final String Function(String path) fileNameOf;
  final VoidCallback onCopyDirectory;
  final VoidCallback onOpenDirectory;

  @override
  Widget build(BuildContext context) {
    final statusColor = isDirectoryAvailable
        ? const Color(0xFF0F766E)
        : const Color(0xFF8D2A24);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileNameOf(record.filePath),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF31414F),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatTime(record.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF708190)),
            ),
            const SizedBox(height: 8),
            Text(
              record.outputDirectoryPath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF52606D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDirectoryAvailable ? '目录可用' : '目录已失效',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopyDirectory,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('复制路径'),
                ),
                TextButton.icon(
                  onPressed: isDirectoryAvailable ? onOpenDirectory : null,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('打开目录'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordEmptyState extends StatelessWidget {
  const _RecordEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '还没有解析记录。\n解析过的 IPA 会显示在这里，并支持重新打开目录。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF708190),
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.content,
    this.isError = false,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String content;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isError
        ? const Color(0xFFF0B6B2)
        : const Color(0xFFD8E2E8);
    final backgroundColor = isError ? const Color(0xFFFFF3F2) : Colors.white;
    final contentColor = isError
        ? const Color(0xFF8D2A24)
        : const Color(0xFF52606D);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF31414F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: contentColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
