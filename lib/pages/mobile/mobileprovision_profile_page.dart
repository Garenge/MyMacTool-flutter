import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/path_utils.dart';
import '../../utils/time_utils.dart';
import 'mobileprovision_profile_diagnostics.dart';
import 'mobileprovision_profile_info.dart';

class MobileProvisionProfilePage extends StatefulWidget {
  const MobileProvisionProfilePage({
    super.key,
    this.initialPath,
    this.initialInfo,
  });

  final String? initialPath;
  final MobileProvisionProfileInfo? initialInfo;

  @override
  State<MobileProvisionProfilePage> createState() =>
      _MobileProvisionProfilePageState();
}

class _MobileProvisionProfilePageState
    extends State<MobileProvisionProfilePage> {
  static const XTypeGroup _provisionTypeGroup = XTypeGroup(
    label: 'provisioning profiles',
    extensions: <String>['mobileprovision', 'provisionprofile'],
    mimeTypes: <String>['application/octet-stream', 'text/xml'],
  );

  final MobileProvisionProfileParser _parser =
      const MobileProvisionProfileParser();
  bool _isDraggingFile = false;
  bool _isLoading = false;
  MobileProvisionProfileInfo? _info;
  String? _statusText;
  String? _errorText;
  final List<MobileProvisionProfileInfo> _records =
      <MobileProvisionProfileInfo>[];

  @override
  void initState() {
    super.initState();
    _applyInitialInfo(widget.initialInfo);
    _scheduleInitialLoad(widget.initialPath);
  }

  @override
  void didUpdateWidget(covariant MobileProvisionProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialInfo != oldWidget.initialInfo) {
      _applyInitialInfo(widget.initialInfo);
    }

    if (widget.initialPath != oldWidget.initialPath) {
      _scheduleInitialLoad(widget.initialPath);
    }
  }

  void _applyInitialInfo(MobileProvisionProfileInfo? info) {
    if (info == null) {
      return;
    }

    _info = info;
    _prependRecord(info);
    _statusText = info.isExpired
        ? '已从 IPA 载入，Profile 已过期。'
        : '已从 IPA 载入 Profile。';
    _errorText = null;
  }

  void _scheduleInitialLoad(String? path) {
    if (path == null || path.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _loadProfile(path);
    });
  }

  Future<void> _handlePickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_provisionTypeGroup],
    );

    if (file == null || !mounted) {
      return;
    }

    await _loadProfile(file.path);
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    final path = files
        .map((DropItem item) => item.path)
        .whereType<String>()
        .cast<String?>()
        .firstWhere(
          (String? value) => value != null && _isProvisionPath(value),
          orElse: () => null,
        );

    if (path == null) {
      setState(() {
        _errorText = '请拖入 .mobileprovision 或 .provisionprofile 文件。';
        _statusText = null;
      });
      return;
    }

    await _loadProfile(path);
  }

  Future<void> _loadProfile(String path) async {
    if (_isLoading) {
      return;
    }

    if (!_isProvisionPath(path)) {
      setState(() {
        _errorText = '当前仅支持 .mobileprovision 或 .provisionprofile 文件。';
        _statusText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '正在解析 Provisioning Profile...';
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
        _statusText = info.isExpired ? '解析完成，Profile 已过期。' : '解析完成。';
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
        _errorText = '解析失败，请确认文件有效后重试。';
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
      _statusText = '已复制 Profile 摘要。';
      _errorText = null;
    });
  }

  Future<void> _handleCopyBundleId() async {
    final bundleIdentifier = _info?.bundleIdentifier;

    if (bundleIdentifier == null || bundleIdentifier.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: bundleIdentifier));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制 Bundle ID。';
      _errorText = null;
    });
  }

  void _handleSelectRecord(MobileProvisionProfileInfo info) {
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

  void _prependRecord(MobileProvisionProfileInfo info) {
    _records.removeWhere(
      (MobileProvisionProfileInfo record) => record.filePath == info.filePath,
    );
    _records.insert(0, info);

    if (_records.length > 8) {
      _records.removeRange(8, _records.length);
    }
  }

  bool _isProvisionPath(String path) {
    return hasFileExtension(path, <String>[
      '.mobileprovision',
      '.provisionprofile',
    ]);
  }

  String _buildSummaryText(MobileProvisionProfileInfo info) {
    final lines = <String>[
      'Name: ${info.name}',
      'UUID: ${info.uuid}',
      'Type: ${info.profileKindLabel}',
      'Team: ${info.teamName ?? '-'}',
      'Team ID: ${_joinOrDash(info.teamIdentifiers)}',
      'Bundle ID: ${info.bundleIdentifier ?? '-'}',
      'Application Identifier: ${info.applicationIdentifier ?? '-'}',
      'Created At: ${_formatDateTime(info.creationDate)}',
      'Expires At: ${_formatDateTime(info.expirationDate)}',
      'Platforms: ${_joinOrDash(info.platforms)}',
      'Devices: ${info.provisionedDevices.length}',
      'Certificates: ${info.certificates.length}',
      '',
      'Signature Diagnostics:',
      ..._diagnosticLines(info),
      '',
      'Entitlements:',
      ..._entitlementLines(info.entitlements),
      '',
      'Certificates:',
      ..._certificateLines(info),
    ];

    return lines.join('\n');
  }

  List<String> _certificateLines(MobileProvisionProfileInfo info) {
    if (info.certificates.isEmpty) {
      return const <String>['- 未读取到 DeveloperCertificates'];
    }

    return info.certificates
        .expand(
          (MobileProvisionCertificateInfo certificate) => <String>[
            '- Certificate ${certificate.index}',
            '  Subject: ${certificate.x509?.subject ?? '-'}',
            '  Issuer: ${certificate.x509?.issuer ?? '-'}',
            '  Serial: ${certificate.x509?.serialNumber ?? '-'}',
            '  Not Before: ${_formatDateTime(certificate.notBefore)}',
            '  Not After: ${_formatDateTime(certificate.notAfter)}',
            '  SHA-1: ${certificate.sha1}',
            '  SHA-256: ${certificate.sha256}',
          ],
        )
        .toList();
  }

  List<String> _diagnosticLines(MobileProvisionProfileInfo info) {
    final diagnostics = MobileProvisionProfileDiagnostics.evaluate(info);

    return diagnostics.items
        .map(
          (ProfileDiagnosticItem item) =>
              '- [${item.severity.label}] ${item.title}: ${item.message}',
        )
        .toList();
  }

  List<String> _entitlementLines(Map<String, Object?> entitlements) {
    final keys = entitlements.keys.toList()..sort();

    return keys
        .map((String key) => '- $key: ${_formatValue(entitlements[key])}')
        .toList();
  }

  String _joinOrDash(List<String> values) {
    if (values.isEmpty) {
      return '-';
    }

    return values.join(', ');
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final localValue = value.toLocal();
    return formatDateTimeSecond(localValue);
  }

  String _formatValue(Object? value) {
    if (value == null) {
      return '-';
    }

    if (value is List<Object?>) {
      return value.map(_formatValue).join(', ');
    }

    if (value is Map<String, Object?>) {
      return '{${_entitlementLines(value).join('; ')}}';
    }

    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provisioning Profile解析',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持选择或拖拽 .mobileprovision，查看签名配置、Entitlements、证书摘要和设备列表。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MobileProvisionDropPanel(
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
                child: _MobileProvisionResultPanel(
                  info: _info,
                  records: _records,
                  onCopySummary: _handleCopySummary,
                  onCopyBundleId: _handleCopyBundleId,
                  onSelectRecord: _handleSelectRecord,
                  formatDateTime: _formatDateTime,
                  formatValue: _formatValue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileProvisionDropPanel extends StatelessWidget {
  const _MobileProvisionDropPanel({
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
                        : Icons.verified_user_rounded,
                    size: 46,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isLoading ? '正在解析...' : '拖拽 Profile 到这里',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF23313C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '支持 .mobileprovision 和 .provisionprofile 文件。',
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

class _MobileProvisionResultPanel extends StatelessWidget {
  const _MobileProvisionResultPanel({
    required this.info,
    required this.records,
    required this.onCopySummary,
    required this.onCopyBundleId,
    required this.onSelectRecord,
    required this.formatDateTime,
    required this.formatValue,
  });

  final MobileProvisionProfileInfo? info;
  final List<MobileProvisionProfileInfo> records;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyBundleId;
  final ValueChanged<MobileProvisionProfileInfo> onSelectRecord;
  final String Function(DateTime? value) formatDateTime;
  final String Function(Object? value) formatValue;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (info == null)
                    const SizedBox(height: 240, child: _EmptyResultPanel())
                  else ...[
                    _ResultHeader(
                      info: info,
                      onCopySummary: onCopySummary,
                      onCopyBundleId: onCopyBundleId,
                    ),
                    const SizedBox(height: 16),
                    _InfoSection(
                      title: '基础信息',
                      rows: [
                        _InfoRow('名称', info.name),
                        _InfoRow('UUID', info.uuid),
                        _InfoRow('类型', info.profileKindLabel),
                        _InfoRow('App ID 名称', info.appIdName ?? '-'),
                        _InfoRow('Team', info.teamName ?? '-'),
                        _InfoRow('Team ID', _joinValues(info.teamIdentifiers)),
                        _InfoRow(
                          'App ID Prefix',
                          _joinValues(info.appIdentifierPrefixes),
                        ),
                        _InfoRow('Bundle ID', info.bundleIdentifier ?? '-'),
                        _InfoRow(
                          'Application ID',
                          info.applicationIdentifier ?? '-',
                        ),
                        _InfoRow('平台', _joinValues(info.platforms)),
                        _InfoRow('创建时间', formatDateTime(info.creationDate)),
                        _InfoRow('过期时间', formatDateTime(info.expirationDate)),
                        _InfoRow('有效天数', info.timeToLive?.toString() ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DiagnosticsSection(
                      profile: info,
                      diagnostics: MobileProvisionProfileDiagnostics.evaluate(
                        info,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _EntitlementsSection(
                      entitlements: info.entitlements,
                      formatValue: formatValue,
                    ),
                    const SizedBox(height: 14),
                    _CertificatesSection(
                      certificates: info.certificates,
                      formatDateTime: formatDateTime,
                    ),
                    const SizedBox(height: 14),
                    _DevicesSection(devices: info.provisionedDevices),
                  ],
                  if (records.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ProfileRecordSection(
                      records: records,
                      onSelectRecord: onSelectRecord,
                      formatDateTime: formatDateTime,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _joinValues(List<String> values) {
    if (values.isEmpty) {
      return '-';
    }

    return values.join(', ');
  }
}

class _ProfileRecordSection extends StatelessWidget {
  const _ProfileRecordSection({
    required this.records,
    required this.onSelectRecord,
    required this.formatDateTime,
  });

  final List<MobileProvisionProfileInfo> records;
  final ValueChanged<MobileProvisionProfileInfo> onSelectRecord;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: '最近记录',
      child: Column(
        children: records
            .map(
              (MobileProvisionProfileInfo record) => _ProfileRecordTile(
                info: record,
                onTap: () => onSelectRecord(record),
                formatDateTime: formatDateTime,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileRecordTile extends StatelessWidget {
  const _ProfileRecordTile({
    required this.info,
    required this.onTap,
    required this.formatDateTime,
  });

  final MobileProvisionProfileInfo info;
  final VoidCallback onTap;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final statusColor = info.isExpired
        ? const Color(0xFFB42318)
        : const Color(0xFF0F766E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.verified_user_rounded, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF23313C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${info.bundleIdentifier ?? '-'} · ${formatDateTime(info.expirationDate)}',
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
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF607180)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.info,
    required this.onCopySummary,
    required this.onCopyBundleId,
  });

  final MobileProvisionProfileInfo info;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyBundleId;

  @override
  Widget build(BuildContext context) {
    final statusColor = info.isExpired
        ? const Color(0xFFB42318)
        : const Color(0xFF0F766E);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            info.isExpired
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                info.isExpired ? 'Profile 已过期' : info.profileKindLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: info.bundleIdentifier == null ? null : onCopyBundleId,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Bundle ID'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onCopySummary,
          icon: const Icon(Icons.copy_all_rounded, size: 18),
          label: const Text('复制摘要'),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      child: Column(
        children: rows
            .map(
              (_InfoRow row) =>
                  _KeyValueRow(label: row.label, value: row.value),
            )
            .toList(),
      ),
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({required this.profile, required this.diagnostics});

  final MobileProvisionProfileInfo profile;
  final MobileProvisionProfileDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: '签名诊断',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KeyValueRow(
            label: 'Profile Bundle ID',
            value: profile.bundleIdentifier ?? '-',
          ),
          _KeyValueRow(label: '诊断摘要', value: diagnostics.summaryText),
          const SizedBox(height: 4),
          ...diagnostics.items.map(
            (ProfileDiagnosticItem item) => _DiagnosticRow(item: item),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.item});

  final ProfileDiagnosticItem item;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(item.severity);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_severityIcon(item.severity), color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.title} · ${item.severity.label}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  item.message,
                  style: const TextStyle(
                    color: Color(0xFF31414F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(ProfileDiagnosticSeverity severity) {
    switch (severity) {
      case ProfileDiagnosticSeverity.ok:
        return const Color(0xFF0F766E);
      case ProfileDiagnosticSeverity.info:
        return const Color(0xFF2563EB);
      case ProfileDiagnosticSeverity.warning:
        return const Color(0xFFB45309);
      case ProfileDiagnosticSeverity.error:
        return const Color(0xFFB42318);
    }
  }

  IconData _severityIcon(ProfileDiagnosticSeverity severity) {
    switch (severity) {
      case ProfileDiagnosticSeverity.ok:
        return Icons.check_circle_rounded;
      case ProfileDiagnosticSeverity.info:
        return Icons.info_rounded;
      case ProfileDiagnosticSeverity.warning:
        return Icons.warning_amber_rounded;
      case ProfileDiagnosticSeverity.error:
        return Icons.error_outline_rounded;
    }
  }
}

class _EntitlementsSection extends StatelessWidget {
  const _EntitlementsSection({
    required this.entitlements,
    required this.formatValue,
  });

  final Map<String, Object?> entitlements;
  final String Function(Object? value) formatValue;

  @override
  Widget build(BuildContext context) {
    final keys = entitlements.keys.toList()..sort();

    return _SectionFrame(
      title: 'Entitlements',
      child: keys.isEmpty
          ? const _MutedText('未读取到 Entitlements。')
          : Column(
              children: keys
                  .map(
                    (String key) => _KeyValueRow(
                      label: key,
                      value: formatValue(entitlements[key]),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _CertificatesSection extends StatelessWidget {
  const _CertificatesSection({
    required this.certificates,
    required this.formatDateTime,
  });

  final List<MobileProvisionCertificateInfo> certificates;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: '证书摘要',
      child: certificates.isEmpty
          ? const _MutedText('未读取到 DeveloperCertificates。')
          : Column(
              children: certificates
                  .map(
                    (MobileProvisionCertificateInfo certificate) =>
                        _CertificateTile(
                          certificate: certificate,
                          formatDateTime: formatDateTime,
                        ),
                  )
                  .toList(),
            ),
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection({required this.devices});

  final List<String> devices;

  @override
  Widget build(BuildContext context) {
    final displayDevices = devices.take(80).toList();

    return _SectionFrame(
      title: '设备 UDID',
      child: devices.isEmpty
          ? const _MutedText('未限制设备，通常用于 App Store 或 Enterprise Profile。')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayDevices
                      .map((String device) => _DeviceChip(device: device))
                      .toList(),
                ),
                if (devices.length > displayDevices.length) ...[
                  const SizedBox(height: 10),
                  _MutedText(
                    '还有 ${devices.length - displayDevices.length} 个设备未展开显示。',
                  ),
                ],
              ],
            ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.title, required this.child});

  final String title;
  final Widget child;

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
            child,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

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
            width: 150,
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
              value,
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

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({
    required this.certificate,
    required this.formatDateTime,
  });

  final MobileProvisionCertificateInfo certificate;
  final String Function(DateTime? value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '证书 ${certificate.index} · ${certificate.byteLength} bytes',
                style: const TextStyle(
                  color: Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (certificate.hasX509Info) ...[
                _KeyValueRow(
                  label: 'Subject',
                  value: certificate.x509?.subject ?? '-',
                ),
                _KeyValueRow(
                  label: 'Issuer',
                  value: certificate.x509?.issuer ?? '-',
                ),
                _KeyValueRow(
                  label: 'Serial',
                  value: certificate.x509?.serialNumber ?? '-',
                ),
                _KeyValueRow(
                  label: 'Not Before',
                  value: formatDateTime(certificate.notBefore),
                ),
                _KeyValueRow(
                  label: 'Not After',
                  value: formatDateTime(certificate.notAfter),
                ),
              ] else
                const _MutedText('未解析到 X.509 主体和有效期，仅展示摘要。'),
              const SizedBox(height: 8),
              _KeyValueRow(label: 'SHA-1', value: certificate.sha1),
              _KeyValueRow(label: 'SHA-256', value: certificate.sha256),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({required this.device});

  final String device;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1E8E4)),
      ),
      child: Text(
        device,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF0F766E),
          fontWeight: FontWeight.w700,
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
    return Center(
      child: Text(
        '选择 Profile 后会显示 Bundle ID、Entitlements、证书和设备信息。',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
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

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
