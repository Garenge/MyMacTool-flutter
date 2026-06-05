import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ipa_app_info.dart';

class _IpaUnpackRecord {
  const _IpaUnpackRecord({
    required this.id,
    required this.filePath,
    required this.outputDirectoryPath,
    required this.createdAt,
    this.appInfo,
  });

  final String id;
  final String filePath;
  final String outputDirectoryPath;
  final DateTime createdAt;
  final IpaAppInfo? appInfo;
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
  IpaAppInfo? _appInfo;
  final List<_IpaUnpackRecord> _records = <_IpaUnpackRecord>[];
  final IpaAppInfoParser _appInfoParser = const IpaAppInfoParser();

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
      final appInfo = await _appInfoParser.parseFromExtractedDirectory(
        outputDirectory,
      );
      await _openDirectory(outputDirectory.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _outputDirectoryPath = outputDirectory.path;
        _appInfo = appInfo;
        _statusText = _buildParseStatusText(appInfo);
        _prependRecord(
          _IpaUnpackRecord(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            filePath: path,
            outputDirectoryPath: outputDirectory.path,
            createdAt: DateTime.now(),
            appInfo: appInfo,
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

  Future<void> _revealFileInFinder(String path) async {
    if (Platform.isMacOS) {
      final result = await Process.run('open', <String>['-R', path]);

      if (result.exitCode != 0) {
        throw ProcessException('open', <String>[
          '-R',
          path,
        ], '${result.stderr}');
      }

      return;
    }

    throw UnsupportedError('当前仅支持在 macOS 上定位文件。');
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
        _appInfo = record.appInfo;
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

  Future<void> _handleRevealInfoPlist() async {
    final infoPlistPath = _appInfo?.infoPlistPath;

    if (infoPlistPath == null || infoPlistPath.isEmpty) {
      return;
    }

    try {
      await _revealFileInFinder(infoPlistPath);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = '已定位 Info.plist。';
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '定位 Info.plist 失败。';
      });
    }
  }

  Future<void> _handleRevealEmbeddedProfile() async {
    final embeddedProfilePath = _appInfo?.embeddedProfilePath;

    if (embeddedProfilePath == null || embeddedProfilePath.isEmpty) {
      return;
    }

    try {
      await _revealFileInFinder(embeddedProfilePath);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = '已定位 embedded.mobileprovision。';
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '定位 embedded.mobileprovision 失败。';
      });
    }
  }

  String _buildParseStatusText(IpaAppInfo? appInfo) {
    if (appInfo == null) {
      return '解析完成，未读取到 Info.plist，已自动打开输出目录。';
    }

    if (appInfo.hasEmbeddedProfileInfo) {
      return '解析完成，已读取应用信息和 embedded.mobileprovision，并打开输出目录。';
    }

    if (appInfo.hasEmbeddedProfile) {
      return '解析完成，已读取应用信息；embedded.mobileprovision 暂未解析成功。';
    }

    return '解析完成，已读取应用信息并打开输出目录。';
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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final contentWidth = constraints.maxWidth < 1120
                  ? 1120.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF7F6),
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
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
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: const Color(0xFF607180),
                                              ),
                                        ),
                                        const SizedBox(height: 22),
                                        FilledButton.icon(
                                          onPressed: _isUnpacking
                                              ? null
                                              : _handlePickFile,
                                          icon: const Icon(
                                            Icons.upload_file_rounded,
                                          ),
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
                                  border: Border.all(
                                    color: const Color(0xFFD8E2E8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '当前结果',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF23313C),
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      _InfoBlock(
                                        title: '当前文件',
                                        content:
                                            _selectedFilePath ?? '尚未选择 IPA 文件',
                                        actionLabel: '打开目录',
                                        onTap: _selectedFilePath == null
                                            ? null
                                            : _handleOpenCurrentFileDirectory,
                                      ),
                                      const SizedBox(height: 12),
                                      _InfoBlock(
                                        title: '输出目录',
                                        content:
                                            _outputDirectoryPath ??
                                            '解析完成后会显示在这里',
                                        actionLabel: '打开目录',
                                        onTap: _outputDirectoryPath == null
                                            ? null
                                            : _handleOpenOutputDirectory,
                                      ),
                                      const SizedBox(height: 12),
                                      _InfoBlock(
                                        title: '状态',
                                        content:
                                            _errorText ?? _statusText ?? '等待操作',
                                        isError: _errorText != null,
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: _AppInfoBlock(
                                          appInfo: _appInfo,
                                          onRevealInfoPlist:
                                              _handleRevealInfoPlist,
                                          onRevealEmbeddedProfile:
                                              _handleRevealEmbeddedProfile,
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
                                              (
                                                BuildContext context,
                                                int index,
                                              ) => const SizedBox(height: 10),
                                          itemBuilder:
                                              (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                final record = _records[index];

                                                return _IpaRecordCard(
                                                  record: record,
                                                  isDirectoryAvailable:
                                                      _directoryExists(
                                                        record
                                                            .outputDirectoryPath,
                                                      ),
                                                  formatTime: _formatTimestamp,
                                                  fileNameOf: _fileNameOf,
                                                  onCopyDirectory: () {
                                                    _handleCopyRecordDirectory(
                                                      record,
                                                    );
                                                  },
                                                  onOpenDirectory: () {
                                                    _handleOpenRecordDirectory(
                                                      record,
                                                    );
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
              );
            },
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
            if (record.appInfo?.hasAnyValue ?? false) ...[
              const SizedBox(height: 8),
              Text(
                '${record.appInfo!.valueOrPlaceholder(record.appInfo!.appName)} / ${record.appInfo!.valueOrPlaceholder(record.appInfo!.bundleIdentifier)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF31414F),
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
            if (record.appInfo?.hasEmbeddedProfileInfo ?? false) ...[
              const SizedBox(height: 6),
              Text(
                'Profile: ${record.appInfo!.embeddedProfileInfo!.profileKindLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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

class _AppInfoBlock extends StatelessWidget {
  const _AppInfoBlock({
    required this.appInfo,
    required this.onRevealInfoPlist,
    required this.onRevealEmbeddedProfile,
  });

  final IpaAppInfo? appInfo;
  final VoidCallback onRevealInfoPlist;
  final VoidCallback onRevealEmbeddedProfile;

  @override
  Widget build(BuildContext context) {
    final info = appInfo;

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
              '应用信息',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF31414F),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: info == null
                  ? const _AppInfoEmptyState()
                  : ListView(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: info.infoPlistPath.isEmpty
                                  ? null
                                  : onRevealInfoPlist,
                              icon: const Icon(Icons.account_tree_rounded),
                              label: const Text('定位 Info.plist'),
                            ),
                            OutlinedButton.icon(
                              onPressed: info.embeddedProfilePath.isEmpty
                                  ? null
                                  : onRevealEmbeddedProfile,
                              icon: const Icon(Icons.verified_user_rounded),
                              label: const Text('定位 Profile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AppInfoRow(
                          label: '名称',
                          value: info.valueOrPlaceholder(info.appName),
                        ),
                        _AppInfoRow(
                          label: 'Bundle ID',
                          value: info.valueOrPlaceholder(info.bundleIdentifier),
                        ),
                        _AppInfoRow(
                          label: '版本',
                          value: info.valueOrPlaceholder(info.shortVersion),
                        ),
                        _AppInfoRow(
                          label: 'Build',
                          value: info.valueOrPlaceholder(info.buildNumber),
                        ),
                        _AppInfoRow(
                          label: '最低系统',
                          value: info.valueOrPlaceholder(info.minimumOsVersion),
                        ),
                        _AppInfoRow(
                          label: '可执行文件',
                          value: info.valueOrPlaceholder(info.executableName),
                        ),
                        _AppInfoRow(
                          label: 'Info.plist',
                          value: info.valueOrPlaceholder(info.infoPlistPath),
                        ),
                        _AppInfoRow(
                          label: 'embedded.mobileprovision',
                          value: info.valueOrPlaceholder(
                            info.embeddedProfilePath,
                          ),
                        ),
                        _EmbeddedProfileInfoRows(info: info),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoEmptyState extends StatelessWidget {
  const _AppInfoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '解析 IPA 后会显示 App 名称、Bundle ID、版本号等信息。',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF708190),
          height: 1.6,
        ),
      ),
    );
  }
}

class _EmbeddedProfileInfoRows extends StatelessWidget {
  const _EmbeddedProfileInfoRows({required this.info});

  final IpaAppInfo info;

  @override
  Widget build(BuildContext context) {
    final profile = info.embeddedProfileInfo;

    if (profile == null) {
      if (info.embeddedProfileError.isEmpty) {
        return const _AppInfoRow(label: 'Profile 状态', value: '未读取到');
      }

      return _AppInfoRow(label: 'Profile 状态', value: info.embeddedProfileError);
    }

    final teamIds = profile.teamIdentifiers.isEmpty
        ? '未读取到'
        : profile.teamIdentifiers.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppInfoRow(label: 'Profile 名称', value: profile.name),
        _AppInfoRow(label: 'Profile 类型', value: profile.profileKindLabel),
        _AppInfoRow(label: 'Profile Team ID', value: teamIds),
        _AppInfoRow(
          label: 'Profile Bundle ID',
          value: profile.bundleIdentifier ?? '未读取到',
        ),
        _AppInfoRow(
          label: 'Bundle ID 匹配',
          value: info.isBundleIdentifierMatched ? '匹配' : '未匹配',
        ),
        _AppInfoRow(
          label: '设备数量',
          value: '${profile.provisionedDevices.length}',
        ),
        _AppInfoRow(label: '证书数量', value: '${profile.certificates.length}'),
      ],
    );
  }
}

class _AppInfoRow extends StatelessWidget {
  const _AppInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF708190),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF31414F),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
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
