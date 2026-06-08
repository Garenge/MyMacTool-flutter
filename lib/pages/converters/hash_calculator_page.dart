import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HashCalculatorPage extends StatefulWidget {
  const HashCalculatorPage({super.key});

  @override
  State<HashCalculatorPage> createState() => _HashCalculatorPageState();
}

class _HashCalculatorPageState extends State<HashCalculatorPage> {
  final TextEditingController _inputController = TextEditingController();
  _HashResult? _result;
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleCalculate() {
    final input = _inputController.text;

    if (input.isEmpty) {
      setState(() {
        _result = null;
        _errorText = '请先输入需要计算 Hash 的文本。';
      });
      return;
    }

    setState(() {
      _result = _HashResult.fromText(input, statusText: 'Hash 计算完成。');
      _errorText = null;
    });
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _result = null;
      _errorText = null;
    });
  }

  Future<void> _handleCopyValue(String value, String statusText) async {
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
          'Hash计算',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持对文本计算 MD5、SHA-1、SHA-256、SHA-512 摘要，适合接口调试和数据校验。',
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
                  _HashInputPanel(
                    controller: _inputController,
                    onCalculate: _handleCalculate,
                    onClear: _handleClear,
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null) ...[
                    _HashMessageBanner(message: _errorText!, isError: true),
                    const SizedBox(height: 16),
                  ] else if (result != null) ...[
                    _HashMessageBanner(
                      message: result.statusText,
                      isError: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: result == null
                        ? const _HashEmptyState()
                        : _HashResultList(
                            result: result,
                            onCopyValue: _handleCopyValue,
                          ),
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

class _HashResult {
  const _HashResult({
    required this.md5Text,
    required this.sha1Text,
    required this.sha256Text,
    required this.sha512Text,
    required this.statusText,
  });

  factory _HashResult.fromText(String text, {required String statusText}) {
    final bytes = utf8.encode(text);

    return _HashResult(
      md5Text: md5.convert(bytes).toString(),
      sha1Text: sha1.convert(bytes).toString(),
      sha256Text: sha256.convert(bytes).toString(),
      sha512Text: sha512.convert(bytes).toString(),
      statusText: statusText,
    );
  }

  final String md5Text;
  final String sha1Text;
  final String sha256Text;
  final String sha512Text;
  final String statusText;

  _HashResult copyWith({required String statusText}) {
    return _HashResult(
      md5Text: md5Text,
      sha1Text: sha1Text,
      sha256Text: sha256Text,
      sha512Text: sha512Text,
      statusText: statusText,
    );
  }
}

class _HashInputPanel extends StatelessWidget {
  const _HashInputPanel({
    required this.controller,
    required this.onCalculate,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onCalculate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: '输入文本',
            hintText: 'Hello MyTools',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.tag_rounded, size: 18),
              label: const Text('计算'),
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

class _HashMessageBanner extends StatelessWidget {
  const _HashMessageBanner({required this.message, required this.isError});

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

class _HashEmptyState extends StatelessWidget {
  const _HashEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '输入文本后点击计算，这里会显示多种摘要算法结果。',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
      ),
    );
  }
}

class _HashResultList extends StatelessWidget {
  const _HashResultList({required this.result, required this.onCopyValue});

  final _HashResult result;
  final Future<void> Function(String value, String statusText) onCopyValue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _HashResultTile(
          label: 'MD5',
          value: result.md5Text,
          onCopy: () => onCopyValue(result.md5Text, '已复制 MD5。'),
        ),
        _HashResultTile(
          label: 'SHA-1',
          value: result.sha1Text,
          onCopy: () => onCopyValue(result.sha1Text, '已复制 SHA-1。'),
        ),
        _HashResultTile(
          label: 'SHA-256',
          value: result.sha256Text,
          onCopy: () => onCopyValue(result.sha256Text, '已复制 SHA-256。'),
        ),
        _HashResultTile(
          label: 'SHA-512',
          value: result.sha512Text,
          onCopy: () => onCopyValue(result.sha512Text, '已复制 SHA-512。'),
        ),
      ],
    );
  }
}

class _HashResultTile extends StatelessWidget {
  const _HashResultTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

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
          child: Row(
            children: [
              SizedBox(
                width: 88,
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
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: '复制 $label',
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
