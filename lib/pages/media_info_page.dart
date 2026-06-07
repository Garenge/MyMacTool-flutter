import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ffprobe_runtime.dart';
import 'media_file_info.dart';

class MediaInfoPage extends StatefulWidget {
  const MediaInfoPage({super.key});

  @override
  State<MediaInfoPage> createState() => _MediaInfoPageState();
}

class _MediaInfoPageState extends State<MediaInfoPage> {
  static const XTypeGroup _mediaTypeGroup = XTypeGroup(
    label: 'media',
    extensions: <String>[
      'mp4',
      'mov',
      'm4v',
      'mkv',
      'webm',
      'avi',
      'flv',
      'mp3',
      'm4a',
      'aac',
      'wav',
      'flac',
      'ogg',
      'opus',
    ],
    mimeTypes: <String>['audio/*', 'video/*'],
  );
  static const XTypeGroup _ffprobeTypeGroup = XTypeGroup(
    label: 'ffprobe',
    mimeTypes: <String>['application/octet-stream'],
  );

  final FfprobeRuntime _runtime = const FfprobeRuntime();
  final MediaFileInfoParser _parser = const MediaFileInfoParser();
  bool _isDraggingFile = false;
  bool _isLoading = false;
  bool _isInstallingRuntime = false;
  MediaFileInfo? _info;
  String? _statusText;
  String? _errorText;
  FfprobeRuntimeStatus? _runtimeStatus;
  final List<MediaFileInfo> _records = <MediaFileInfo>[];

  @override
  void initState() {
    super.initState();
    _refreshRuntimeStatus();
  }

  Future<void> _refreshRuntimeStatus() async {
    final status = await _runtime.resolve();

    if (!mounted) {
      return;
    }

    setState(() {
      _runtimeStatus = status;
    });
  }

  Future<void> _handlePickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_mediaTypeGroup],
    );

    if (file == null) {
      return;
    }

    await _loadMediaInfo(file.path);
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
        _errorText = '请拖入一个音频或视频文件。';
        _statusText = null;
      });
      return;
    }

    await _loadMediaInfo(path);
  }

  Future<void> _loadMediaInfo(String path) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '正在调用 ffprobe 读取媒体信息...';
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
        _statusText = '媒体信息读取完成。';
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
        _errorText = '媒体信息读取失败，请确认文件有效后重试。';
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

  Future<void> _handleImportFfprobe() async {
    if (_isInstallingRuntime) {
      return;
    }

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_ffprobeTypeGroup],
    );

    if (file == null) {
      return;
    }

    setState(() {
      _isInstallingRuntime = true;
      _statusText = '正在导入 ffprobe 运行时...';
      _errorText = null;
    });

    try {
      final installedPath = await _runtime.installFrom(file.path);
      final status = await _runtime.resolve();

      if (!mounted) {
        return;
      }

      setState(() {
        _runtimeStatus = status;
        _statusText = 'ffprobe 已导入：$installedPath';
        _errorText = null;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.message;
        _statusText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '导入 ffprobe 失败，请确认文件有效后重试。';
        _statusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInstallingRuntime = false;
        });
      }
    }
  }

  Future<void> _handleInstallRequiredEnvironment() async {
    if (_isInstallingRuntime) {
      return;
    }

    setState(() {
      _isInstallingRuntime = true;
      _statusText = '正在启用内置 ffprobe 组件...';
      _errorText = null;
    });

    try {
      final result = await _runtime.installRequiredEnvironment();
      final status = await _runtime.resolve();

      if (!mounted) {
        return;
      }

      setState(() {
        _runtimeStatus = status;
        _statusText = '${result.message} 路径：${result.path}';
        _errorText = null;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.message;
        _statusText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '启用内置 ffprobe 失败，请更新 App 或使用“导入ffprobe”。';
        _statusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInstallingRuntime = false;
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
      _statusText = '已复制媒体文件路径。';
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
      _statusText = '已复制媒体摘要。';
      _errorText = null;
    });
  }

  void _handleSelectRecord(MediaFileInfo info) {
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

  void _prependRecord(MediaFileInfo info) {
    _records.removeWhere(
      (MediaFileInfo record) => record.filePath == info.filePath,
    );
    _records.insert(0, info);

    if (_records.length > 8) {
      _records.removeRange(8, _records.length);
    }
  }

  String _buildSummaryText(MediaFileInfo info) {
    return [
      'File: ${info.fileName}',
      'Format: ${info.displayFormat}',
      'Duration: ${info.durationText}',
      'Size: ${info.fileSizeText}',
      'Bitrate: ${info.bitRateText}',
      'Video Streams: ${info.videoStreams.length}',
      'Audio Streams: ${info.audioStreams.length}',
      ...info.videoStreams.map(
        (MediaStreamInfo stream) =>
            'Video #${stream.index}: ${stream.codecName} ${stream.resolutionText} ${stream.frameRateText}',
      ),
      ...info.audioStreams.map(
        (MediaStreamInfo stream) =>
            'Audio #${stream.index}: ${stream.codecName} ${stream.sampleRateText} ${stream.channelsText}',
      ),
      'Path: ${info.filePath}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '音视频信息',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '基于 ffprobe 解析音频和视频文件，查看容器、编码、码率、分辨率、帧率和音频参数。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MediaDropPanel(
                isDraggingFile: _isDraggingFile,
                isLoading: _isLoading,
                isInstallingRuntime: _isInstallingRuntime,
                runtimeStatus: _runtimeStatus,
                statusText: _errorText ?? _statusText,
                isError: _errorText != null,
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
                onInstallRequiredEnvironment: _handleInstallRequiredEnvironment,
                onImportFfprobe: _handleImportFfprobe,
                onClear: _handleClear,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _MediaResultPanel(
                  info: _info,
                  records: _records,
                  onCopySummary: _info == null ? null : _handleCopySummary,
                  onCopyPath: _info == null ? null : _handleCopyPath,
                  onSelectRecord: _handleSelectRecord,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaDropPanel extends StatelessWidget {
  const _MediaDropPanel({
    required this.isDraggingFile,
    required this.isLoading,
    required this.isInstallingRuntime,
    required this.runtimeStatus,
    required this.statusText,
    required this.isError,
    required this.selectedPath,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDropFiles,
    required this.onPickFile,
    required this.onInstallRequiredEnvironment,
    required this.onImportFfprobe,
    required this.onClear,
  });

  final bool isDraggingFile;
  final bool isLoading;
  final bool isInstallingRuntime;
  final FfprobeRuntimeStatus? runtimeStatus;
  final String? statusText;
  final bool isError;
  final String? selectedPath;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final Future<void> Function(List<DropItem> files) onDropFiles;
  final VoidCallback onPickFile;
  final VoidCallback onInstallRequiredEnvironment;
  final VoidCallback onImportFfprobe;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDraggingFile
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return SizedBox(
      width: 360,
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
            child: ListView(
              children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F6),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.perm_media_rounded,
                      size: 46,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isLoading ? '正在解析...' : '拖拽音视频到这里',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF23313C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '支持 MP4、MOV、MKV、WebM、MP3、M4A、WAV、FLAC 等常见格式。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF607180),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: isLoading ? null : onPickFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('选择文件'),
                    ),
                    FilledButton.icon(
                      onPressed: isInstallingRuntime
                          ? null
                          : onInstallRequiredEnvironment,
                      icon: const Icon(Icons.download_for_offline_rounded),
                      label: const Text('启用内置组件'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isInstallingRuntime ? null : onImportFfprobe,
                      icon: const Icon(Icons.install_desktop_rounded),
                      label: const Text('导入ffprobe'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onClear,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: const Text('清空'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _RuntimeStatusBanner(status: runtimeStatus),
                const SizedBox(height: 10),
                if (selectedPath != null)
                  _MediaStatusBanner(
                    message: selectedPath!,
                    icon: Icons.description_rounded,
                    isError: false,
                  ),
                if (statusText != null) ...[
                  if (selectedPath != null) const SizedBox(height: 10),
                  _MediaStatusBanner(
                    message: statusText!,
                    icon: isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_rounded,
                    isError: isError,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaResultPanel extends StatelessWidget {
  const _MediaResultPanel({
    required this.info,
    required this.records,
    required this.onCopySummary,
    required this.onCopyPath,
    required this.onSelectRecord,
  });

  final MediaFileInfo? info;
  final List<MediaFileInfo> records;
  final VoidCallback? onCopySummary;
  final VoidCallback? onCopyPath;
  final ValueChanged<MediaFileInfo> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    final info = this.info;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (info == null)
              const SizedBox(height: 240, child: _MediaEmptyState())
            else ...[
              _MediaResultHeader(
                info: info,
                onCopySummary: onCopySummary,
                onCopyPath: onCopyPath,
              ),
              const SizedBox(height: 14),
              _MediaInfoSection(
                title: '容器信息',
                rows: [
                  _MediaInfoRow('文件名', info.fileName),
                  _MediaInfoRow('格式', info.displayFormat),
                  _MediaInfoRow('时长', info.durationText),
                  _MediaInfoRow('文件大小', info.fileSizeText),
                  _MediaInfoRow('总码率', info.bitRateText),
                  _MediaInfoRow('路径', info.filePath),
                ],
              ),
              if (info.videoStreams.isNotEmpty) ...[
                const SizedBox(height: 14),
                _StreamSection(title: '视频流', streams: info.videoStreams),
              ],
              if (info.audioStreams.isNotEmpty) ...[
                const SizedBox(height: 14),
                _StreamSection(title: '音频流', streams: info.audioStreams),
              ],
              if (info.otherStreams.isNotEmpty) ...[
                const SizedBox(height: 14),
                _StreamSection(title: '其他流', streams: info.otherStreams),
              ],
              if (info.metadata.isNotEmpty) ...[
                const SizedBox(height: 14),
                _MetadataSection(metadata: info.metadata),
              ],
            ],
            if (records.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MediaRecordSection(
                records: records,
                onSelectRecord: onSelectRecord,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaResultHeader extends StatelessWidget {
  const _MediaResultHeader({
    required this.info,
    required this.onCopySummary,
    required this.onCopyPath,
  });

  final MediaFileInfo info;
  final VoidCallback? onCopySummary;
  final VoidCallback? onCopyPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.analytics_rounded, color: Color(0xFF0F766E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${info.durationText} · ${info.videoStreams.length} 视频 / ${info.audioStreams.length} 音频',
                style: const TextStyle(
                  color: Color(0xFF607180),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onCopyPath,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('复制路径'),
            ),
            FilledButton.icon(
              onPressed: onCopySummary,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('复制摘要'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreamSection extends StatelessWidget {
  const _StreamSection({required this.title, required this.streams});

  final String title;
  final List<MediaStreamInfo> streams;

  @override
  Widget build(BuildContext context) {
    return _MediaInfoSection(
      title: title,
      rows: streams.expand(_rowsForStream).toList(),
    );
  }

  Iterable<_MediaInfoRow> _rowsForStream(MediaStreamInfo stream) {
    final prefix = '#${stream.index}';
    final baseRows = <_MediaInfoRow>[
      _MediaInfoRow('$prefix 类型', stream.type),
      _MediaInfoRow('$prefix 编码', stream.codecText),
      _MediaInfoRow('$prefix 时长', stream.durationText),
      _MediaInfoRow('$prefix 码率', stream.bitRateText),
      _MediaInfoRow('$prefix 语言', stream.languageText),
    ];

    if (stream.isVideo) {
      return <_MediaInfoRow>[
        ...baseRows,
        _MediaInfoRow('$prefix 分辨率', stream.resolutionText),
        _MediaInfoRow('$prefix 帧率', stream.frameRateText),
        _MediaInfoRow(
          '$prefix 像素格式',
          stream.pixelFormat.isEmpty ? '-' : stream.pixelFormat,
        ),
        _MediaInfoRow(
          '$prefix Profile',
          stream.profile.isEmpty ? '-' : stream.profile,
        ),
      ];
    }

    if (stream.isAudio) {
      return <_MediaInfoRow>[
        ...baseRows,
        _MediaInfoRow('$prefix 采样率', stream.sampleRateText),
        _MediaInfoRow('$prefix 声道', stream.channelsText),
        _MediaInfoRow(
          '$prefix Profile',
          stream.profile.isEmpty ? '-' : stream.profile,
        ),
      ];
    }

    return baseRows;
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});

  final Map<String, String> metadata;

  @override
  Widget build(BuildContext context) {
    final rows = metadata.entries
        .map(
          (MapEntry<String, String> entry) =>
              _MediaInfoRow(entry.key, entry.value),
        )
        .toList();

    return _MediaInfoSection(title: '元数据', rows: rows);
  }
}

class _MediaInfoSection extends StatelessWidget {
  const _MediaInfoSection({required this.title, required this.rows});

  final String title;
  final List<_MediaInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (_MediaInfoRow row) =>
                  _MediaKeyValueRow(label: row.label, value: row.value),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaKeyValueRow extends StatelessWidget {
  const _MediaKeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF607180),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xFF23313C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaRecordSection extends StatelessWidget {
  const _MediaRecordSection({
    required this.records,
    required this.onSelectRecord,
  });

  final List<MediaFileInfo> records;
  final ValueChanged<MediaFileInfo> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '最近记录',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF23313C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: records
                      .map(
                        (MediaFileInfo record) => _MediaRecordTile(
                          info: record,
                          onTap: () => onSelectRecord(record),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MediaRecordTile extends StatelessWidget {
  const _MediaRecordTile({required this.info, required this.onTap});

  final MediaFileInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.perm_media_rounded,
                color: Color(0xFF0F766E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF23313C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${info.durationText} · ${info.displayFormat}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF607180),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF607180)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuntimeStatusBanner extends StatelessWidget {
  const _RuntimeStatusBanner({required this.status});

  final FfprobeRuntimeStatus? status;

  @override
  Widget build(BuildContext context) {
    final currentStatus = status;

    if (currentStatus == null) {
      return const _MediaStatusBanner(
        message: '正在检测 ffprobe 运行时...',
        icon: Icons.hourglass_top_rounded,
        isError: false,
      );
    }

    if (currentStatus.isAvailable) {
      return _MediaStatusBanner(
        message: 'ffprobe 可用：${currentStatus.path}',
        icon: Icons.check_circle_rounded,
        isError: false,
      );
    }

    return _MediaStatusBanner(
      message:
          '${FfprobeRuntime.missingMessage}\n托管路径：${currentStatus.managedPath}',
      icon: Icons.error_outline_rounded,
      isError: true,
    );
  }
}

class _MediaStatusBanner extends StatelessWidget {
  const _MediaStatusBanner({
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

class _MediaEmptyState extends StatelessWidget {
  const _MediaEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '选择音频或视频文件后会显示容器、编码、时长、码率和流信息。',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
      ),
    );
  }
}

class _MediaInfoRow {
  const _MediaInfoRow(this.label, this.value);

  final String label;
  final String value;
}
