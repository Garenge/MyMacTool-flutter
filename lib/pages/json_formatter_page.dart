import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _JsonAction { format, minify, validate }

class JsonFormatterPage extends StatefulWidget {
  const JsonFormatterPage({super.key});

  @override
  State<JsonFormatterPage> createState() => _JsonFormatterPageState();
}

class _JsonFormatterPageState extends State<JsonFormatterPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  int _indentSpaces = 2;
  bool _sortKeys = false;
  String? _statusText;
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _handleFormat() {
    _runJsonAction(_JsonAction.format);
  }

  void _handleMinify() {
    _runJsonAction(_JsonAction.minify);
  }

  void _handleValidate() {
    _runJsonAction(_JsonAction.validate);
  }

  void _runJsonAction(_JsonAction action) {
    final rawText = _inputController.text.trim();

    if (rawText.isEmpty) {
      setState(() {
        _errorText = '请先输入需要处理的 JSON 内容。';
        _statusText = null;
      });
      return;
    }

    try {
      final parsedJson = jsonDecode(rawText);
      final normalizedJson = _sortKeys
          ? _sortJsonValue(parsedJson)
          : parsedJson;
      final result = _buildActionResult(action, normalizedJson);

      setState(() {
        _outputController.text = result.outputText;
        _statusText = result.statusText;
        _errorText = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _errorText = _formatJsonError(error);
        _statusText = null;
      });
    }
  }

  _JsonActionResult _buildActionResult(_JsonAction action, Object? value) {
    switch (action) {
      case _JsonAction.format:
        return _JsonActionResult(
          outputText: _formatJson(value),
          statusText: '格式化完成。',
        );
      case _JsonAction.minify:
        return _JsonActionResult(
          outputText: jsonEncode(value),
          statusText: '压缩完成。',
        );
      case _JsonAction.validate:
        return const _JsonActionResult(
          outputText: 'JSON 校验通过。',
          statusText: 'JSON 校验通过。',
        );
    }
  }

  String _formatJson(Object? value) {
    return JsonEncoder.withIndent(' ' * _indentSpaces).convert(value);
  }

  Object? _sortJsonValue(Object? value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((key) => '$key').toList(growable: false)
        ..sort();
      return <String, Object?>{
        for (final key in sortedKeys) key: _sortJsonValue(value[key]),
      };
    }

    if (value is List) {
      return value.map(_sortJsonValue).toList(growable: false);
    }

    return value;
  }

  String _formatJsonError(FormatException error) {
    final offset = error.offset;

    if (offset == null) {
      return 'JSON 解析失败：${error.message}';
    }

    final position = _resolveLineColumn(_inputController.text, offset);
    return 'JSON 解析失败：${error.message}（第 ${position.line} 行，第 ${position.column} 列）';
  }

  _TextPosition _resolveLineColumn(String text, int offset) {
    var line = 1;
    var column = 1;
    final safeOffset = offset.clamp(0, text.length);

    for (var index = 0; index < safeOffset; index += 1) {
      if (text.codeUnitAt(index) == 10) {
        line += 1;
        column = 1;
      } else {
        column += 1;
      }
    }

    return _TextPosition(line: line, column: column);
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _statusText = null;
      _errorText = null;
    });
  }

  void _handleUseOutputAsInput() {
    if (_outputController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _inputController.text = _outputController.text;
      _outputController.clear();
      _statusText = '已将结果移入输入区。';
      _errorText = null;
    });
  }

  Future<void> _handleCopyOutput() async {
    final outputText = _outputController.text;

    if (outputText.trim().isEmpty) {
      setState(() {
        _errorText = '当前没有可复制的输出结果。';
        _statusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: outputText));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制输出结果。';
      _errorText = null;
    });
  }

  void _handleIndentChanged(int indentSpaces) {
    setState(() {
      _indentSpaces = indentSpaces;
      _statusText = null;
      _errorText = null;
    });
  }

  void _handleSortKeysChanged(bool value) {
    setState(() {
      _sortKeys = value;
      _statusText = null;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JSON格式化',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持 JSON 格式化、压缩、校验和 key 排序，解析错误会提示大致行列位置。',
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
                children: [
                  _JsonControlBar(
                    indentSpaces: _indentSpaces,
                    sortKeys: _sortKeys,
                    onIndentChanged: _handleIndentChanged,
                    onSortKeysChanged: _handleSortKeysChanged,
                    onFormat: _handleFormat,
                    onMinify: _handleMinify,
                    onValidate: _handleValidate,
                    onClear: _handleClear,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _JsonTextPanel(
                            title: '输入',
                            controller: _inputController,
                            hintText: '{"name":"MyTools","items":[1,2,3]}',
                            readOnly: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _JsonTextPanel(
                            title: '输出',
                            controller: _outputController,
                            hintText: '处理结果会显示在这里',
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _JsonResultBar(
                    statusText: _statusText,
                    errorText: _errorText,
                    onCopyOutput: _handleCopyOutput,
                    onUseOutputAsInput: _handleUseOutputAsInput,
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

class _JsonActionResult {
  const _JsonActionResult({required this.outputText, required this.statusText});

  final String outputText;
  final String statusText;
}

class _TextPosition {
  const _TextPosition({required this.line, required this.column});

  final int line;
  final int column;
}

class _JsonControlBar extends StatelessWidget {
  const _JsonControlBar({
    required this.indentSpaces,
    required this.sortKeys,
    required this.onIndentChanged,
    required this.onSortKeysChanged,
    required this.onFormat,
    required this.onMinify,
    required this.onValidate,
    required this.onClear,
  });

  final int indentSpaces;
  final bool sortKeys;
  final ValueChanged<int> onIndentChanged;
  final ValueChanged<bool> onSortKeysChanged;
  final VoidCallback onFormat;
  final VoidCallback onMinify;
  final VoidCallback onValidate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<int>(
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 2, label: Text('2空格')),
            ButtonSegment<int>(value: 4, label: Text('4空格')),
          ],
          selected: <int>{indentSpaces},
          onSelectionChanged: (Set<int> selection) {
            onIndentChanged(selection.first);
          },
          showSelectedIcon: false,
        ),
        FilterChip(
          selected: sortKeys,
          onSelected: onSortKeysChanged,
          avatar: const Icon(Icons.sort_by_alpha_rounded, size: 18),
          label: const Text('排序Key'),
        ),
        FilledButton.icon(
          onPressed: onFormat,
          icon: const Icon(Icons.format_align_left_rounded),
          label: const Text('格式化'),
        ),
        OutlinedButton.icon(
          onPressed: onMinify,
          icon: const Icon(Icons.compress_rounded),
          label: const Text('压缩'),
        ),
        OutlinedButton.icon(
          onPressed: onValidate,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('校验'),
        ),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear_rounded),
          label: const Text('清空'),
        ),
      ],
    );
  }
}

class _JsonTextPanel extends StatelessWidget {
  const _JsonTextPanel({
    required this.title,
    required this.controller,
    required this.hintText,
    required this.readOnly,
  });

  final String title;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF31414F),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: const Color(0xFFF7FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD8E2E8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD8E2E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF7FB8B3),
                      width: 1.4,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonResultBar extends StatelessWidget {
  const _JsonResultBar({
    required this.statusText,
    required this.errorText,
    required this.onCopyOutput,
    required this.onUseOutputAsInput,
  });

  final String? statusText;
  final String? errorText;
  final VoidCallback onCopyOutput;
  final VoidCallback onUseOutputAsInput;

  @override
  Widget build(BuildContext context) {
    final message = errorText ?? statusText ?? '等待处理 JSON 内容。';
    final isError = errorText != null;
    final borderColor = isError
        ? const Color(0xFFF0B6B2)
        : const Color(0xFFB7D8D3);
    final backgroundColor = isError
        ? const Color(0xFFFFF3F2)
        : const Color(0xFFEAF7F6);
    final foregroundColor = isError
        ? const Color(0xFF8D2A24)
        : const Color(0xFF0F766E);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onUseOutputAsInput,
              icon: const Icon(Icons.input_rounded, size: 18),
              label: const Text('结果转输入'),
            ),
            TextButton.icon(
              onPressed: onCopyOutput,
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: const Text('复制结果'),
            ),
          ],
        ),
      ),
    );
  }
}
