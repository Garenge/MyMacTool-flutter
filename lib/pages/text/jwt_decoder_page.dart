import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/time_utils.dart';

class JwtDecoderPage extends StatefulWidget {
  const JwtDecoderPage({super.key});

  @override
  State<JwtDecoderPage> createState() => _JwtDecoderPageState();
}

class _JwtDecoderPageState extends State<JwtDecoderPage> {
  final TextEditingController _inputController = TextEditingController();
  _JwtDecodeResult? _result;
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleDecode() {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _result = null;
        _errorText = '请先粘贴 JWT 文本。';
      });
      return;
    }

    try {
      setState(() {
        _result = _JwtDecodeResult.fromToken(input);
        _errorText = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _errorText = error.message;
      });
    }
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _result = null;
      _errorText = null;
    });
  }

  Future<void> _handleCopy(String value, String statusText) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }

    setState(() {
      final current = _result;

      if (current == null) {
        return;
      }

      _result = current.copyWith(statusText: statusText);
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JWT解析',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持解码 JWT Header / Payload，并将 exp、iat、nbf 转换为本地时间。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8E2E8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _JwtInputPanel(
                    controller: _inputController,
                    onDecode: _handleDecode,
                    onClear: _handleClear,
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null) ...[
                    _JwtMessageBanner(message: _errorText!, isError: true),
                    const SizedBox(height: 16),
                  ] else if (result != null) ...[
                    _JwtMessageBanner(
                      message: result.statusText,
                      isError: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: result == null
                        ? const _JwtEmptyState()
                        : _JwtResultView(result: result, onCopy: _handleCopy),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JwtDecodeResult {
  const _JwtDecodeResult({
    required this.headerJson,
    required this.payloadJson,
    required this.signaturePreview,
    required this.claims,
    required this.statusText,
  });

  factory _JwtDecodeResult.fromToken(String token) {
    final parts = token.split('.');

    if (parts.length != 3) {
      throw const FormatException('JWT 需要包含 Header、Payload、Signature 三段。');
    }

    final header = _decodeBase64Json(parts[0], 'Header');
    final payload = _decodeBase64Json(parts[1], 'Payload');

    return _JwtDecodeResult(
      headerJson: _prettyJson(header),
      payloadJson: _prettyJson(payload),
      signaturePreview: parts[2].isEmpty ? '空签名' : parts[2],
      claims: _JwtClaimSummary.fromPayload(payload),
      statusText: 'JWT 解析完成。注意：当前仅解码内容，不校验签名。',
    );
  }

  final String headerJson;
  final String payloadJson;
  final String signaturePreview;
  final _JwtClaimSummary claims;
  final String statusText;

  _JwtDecodeResult copyWith({required String statusText}) {
    return _JwtDecodeResult(
      headerJson: headerJson,
      payloadJson: payloadJson,
      signaturePreview: signaturePreview,
      claims: claims,
      statusText: statusText,
    );
  }

  static Map<String, Object?> _decodeBase64Json(String text, String label) {
    try {
      final normalized = base64Url.normalize(text);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonValue = jsonDecode(decoded);

      if (jsonValue is Map<String, dynamic>) {
        return jsonValue;
      }

      throw FormatException('$label 不是 JSON Object。');
    } on FormatException catch (error) {
      throw FormatException('$label 解码失败：${error.message}');
    } on ArgumentError {
      throw FormatException('$label Base64URL 格式不正确。');
    }
  }

  static String _prettyJson(Map<String, Object?> value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

class _JwtClaimSummary {
  const _JwtClaimSummary({
    required this.expiresAtText,
    required this.issuedAtText,
    required this.notBeforeText,
    required this.expirationStatus,
  });

  factory _JwtClaimSummary.fromPayload(Map<String, Object?> payload) {
    final expiresAt = _formatUnixSeconds(payload['exp']);

    return _JwtClaimSummary(
      expiresAtText: expiresAt,
      issuedAtText: _formatUnixSeconds(payload['iat']),
      notBeforeText: _formatUnixSeconds(payload['nbf']),
      expirationStatus: _resolveExpirationStatus(payload['exp']),
    );
  }

  final String expiresAtText;
  final String issuedAtText;
  final String notBeforeText;
  final String expirationStatus;

  static String _formatUnixSeconds(Object? value) {
    final seconds = _readUnixSeconds(value);

    if (seconds == null) {
      return '未提供';
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
    ).toLocal();

    return _formatDateTime(dateTime);
  }

  static String _resolveExpirationStatus(Object? value) {
    final seconds = _readUnixSeconds(value);

    if (seconds == null) {
      return '未提供 exp';
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

    if (DateTime.now().isAfter(expiresAt)) {
      return '已过期';
    }

    return '未过期';
  }

  static int? _readUnixSeconds(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is double && value % 1 == 0) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static String _formatDateTime(DateTime value) {
    return formatDateTimeSecond(value);
  }
}

class _JwtInputPanel extends StatelessWidget {
  const _JwtInputPanel({
    required this.controller,
    required this.onDecode,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onDecode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'JWT',
            hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: onDecode,
              icon: const Icon(Icons.data_object_rounded, size: 18),
              label: const Text('解析'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.cleaning_services_rounded, size: 18),
              label: const Text('清空'),
            ),
          ],
        ),
      ],
    );
  }
}

class _JwtMessageBanner extends StatelessWidget {
  const _JwtMessageBanner({required this.message, required this.isError});

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

class _JwtEmptyState extends StatelessWidget {
  const _JwtEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '粘贴 JWT 后点击解析，这里会显示 Header、Payload 和时间类声明。',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
      ),
    );
  }
}

class _JwtResultView extends StatelessWidget {
  const _JwtResultView({required this.result, required this.onCopy});

  final _JwtDecodeResult result;
  final Future<void> Function(String value, String statusText) onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 300, child: _JwtClaimPanel(claims: result.claims)),
        const SizedBox(width: 16),
        Expanded(
          child: ListView(
            children: [
              _JwtJsonPanel(
                title: 'Header',
                value: result.headerJson,
                onCopy: () => onCopy(result.headerJson, '已复制 Header。'),
              ),
              _JwtJsonPanel(
                title: 'Payload',
                value: result.payloadJson,
                onCopy: () => onCopy(result.payloadJson, '已复制 Payload。'),
              ),
              _JwtJsonPanel(
                title: 'Signature',
                value: result.signaturePreview,
                onCopy: () => onCopy(result.signaturePreview, '已复制 Signature。'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JwtClaimPanel extends StatelessWidget {
  const _JwtClaimPanel({required this.claims});

  final _JwtClaimSummary claims;

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
              '时间声明',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _JwtClaimRow(label: '过期状态', value: claims.expirationStatus),
            _JwtClaimRow(label: 'exp', value: claims.expiresAtText),
            _JwtClaimRow(label: 'iat', value: claims.issuedAtText),
            _JwtClaimRow(label: 'nbf', value: claims.notBeforeText),
          ],
        ),
      ),
    );
  }
}

class _JwtClaimRow extends StatelessWidget {
  const _JwtClaimRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF607180),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF23313C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JwtJsonPanel extends StatelessWidget {
  const _JwtJsonPanel({
    required this.title,
    required this.value,
    required this.onCopy,
  });

  final String title;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF23313C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('复制'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                value,
                style: const TextStyle(
                  color: Color(0xFF31414F),
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
