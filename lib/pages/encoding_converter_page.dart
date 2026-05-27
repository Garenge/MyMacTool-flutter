import 'dart:convert';

import 'package:flutter/material.dart';

enum _EncodingFormat { plainText, urlEncoded, unicodeEscaped, utf8Hex, base64 }

enum _EncodingSide { left, right }

class EncodingConverterPage extends StatefulWidget {
  const EncodingConverterPage({super.key});

  @override
  State<EncodingConverterPage> createState() => _EncodingConverterPageState();
}

class _EncodingConverterPageState extends State<EncodingConverterPage> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  final FocusNode _leftFocusNode = FocusNode();
  final FocusNode _rightFocusNode = FocusNode();

  _EncodingFormat _leftFormat = _EncodingFormat.plainText;
  _EncodingFormat _rightFormat = _EncodingFormat.urlEncoded;
  _EncodingSide _lastEditedSide = _EncodingSide.left;
  String? _errorText;

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _leftFocusNode.dispose();
    _rightFocusNode.dispose();
    super.dispose();
  }

  void _handleLeftChanged(String _) {
    setState(() {
      _lastEditedSide = _EncodingSide.left;
      _errorText = null;
    });
  }

  void _handleRightChanged(String _) {
    setState(() {
      _lastEditedSide = _EncodingSide.right;
      _errorText = null;
    });
  }

  void _handleConvert() {
    _convertFromSide(_resolveSourceSide());
  }

  void _handleFormatChanged(_EncodingSide side, _EncodingFormat value) {
    setState(() {
      if (side == _EncodingSide.left) {
        _leftFormat = value;
      } else {
        _rightFormat = value;
      }
      _errorText = null;
    });

    final currentController = _controllerFor(side);
    final otherSide = _otherSide(side);
    final otherController = _controllerFor(otherSide);

    if (otherController.text.trim().isNotEmpty) {
      _convertFromSide(otherSide);
      return;
    }

    if (currentController.text.trim().isNotEmpty) {
      _convertFromSide(side);
    }
  }

  void _convertFromSide(_EncodingSide sourceSide) {
    final sourceController = _controllerFor(sourceSide);
    final targetController = _controllerFor(_otherSide(sourceSide));
    final sourceFormat = _formatFor(sourceSide);
    final targetFormat = _formatFor(_otherSide(sourceSide));
    final rawText = sourceController.text;

    if (rawText.trim().isEmpty) {
      setState(() {
        _errorText = '请先在要转换的输入框中填写内容。';
      });
      return;
    }

    try {
      final plainText = _decodeToPlainText(rawText, sourceFormat);
      final formattedSource = _encodeFromPlainText(plainText, sourceFormat);
      final formattedTarget = _encodeFromPlainText(plainText, targetFormat);

      setState(() {
        _updateControllerText(sourceController, formattedSource);
        _updateControllerText(targetController, formattedTarget);
        _lastEditedSide = sourceSide;
        _errorText = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    }
  }

  void _handleClear() {
    setState(() {
      _updateControllerText(_leftController, '');
      _updateControllerText(_rightController, '');
      _errorText = null;
      _lastEditedSide = _EncodingSide.left;
    });
  }

  void _updateControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  _EncodingSide _resolveSourceSide() {
    if (_leftFocusNode.hasFocus) {
      return _EncodingSide.left;
    }

    if (_rightFocusNode.hasFocus) {
      return _EncodingSide.right;
    }

    final leftHasValue = _leftController.text.trim().isNotEmpty;
    final rightHasValue = _rightController.text.trim().isNotEmpty;

    if (leftHasValue && !rightHasValue) {
      return _EncodingSide.left;
    }

    if (rightHasValue && !leftHasValue) {
      return _EncodingSide.right;
    }

    return _lastEditedSide;
  }

  TextEditingController _controllerFor(_EncodingSide side) {
    return side == _EncodingSide.left ? _leftController : _rightController;
  }

  _EncodingFormat _formatFor(_EncodingSide side) {
    return side == _EncodingSide.left ? _leftFormat : _rightFormat;
  }

  _EncodingSide _otherSide(_EncodingSide side) {
    return side == _EncodingSide.left
        ? _EncodingSide.right
        : _EncodingSide.left;
  }

  String _decodeToPlainText(String input, _EncodingFormat format) {
    switch (format) {
      case _EncodingFormat.plainText:
        return input;
      case _EncodingFormat.urlEncoded:
        return _decodeUrl(input);
      case _EncodingFormat.unicodeEscaped:
        return _decodeUnicodeEscapes(input);
      case _EncodingFormat.utf8Hex:
        return _decodeUtf8Hex(input);
      case _EncodingFormat.base64:
        return _decodeBase64(input);
    }
  }

  String _encodeFromPlainText(String input, _EncodingFormat format) {
    switch (format) {
      case _EncodingFormat.plainText:
        return input;
      case _EncodingFormat.urlEncoded:
        return Uri.encodeComponent(input);
      case _EncodingFormat.unicodeEscaped:
        return _encodeUnicodeEscapes(input);
      case _EncodingFormat.utf8Hex:
        return _encodeUtf8Hex(input);
      case _EncodingFormat.base64:
        return base64.encode(utf8.encode(input));
    }
  }

  String _decodeUrl(String input) {
    try {
      return Uri.decodeComponent(input.replaceAll('+', ' '));
    } on ArgumentError {
      throw const FormatException('URL 编码内容格式不正确，请检查 % 后是否为两位十六进制。');
    }
  }

  String _decodeUnicodeEscapes(String input) {
    final buffer = StringBuffer();

    for (var index = 0; index < input.length; index += 1) {
      final codeUnit = input.codeUnitAt(index);
      final hasUnicodePrefix =
          codeUnit == 0x5C &&
          index + 1 < input.length &&
          input.codeUnitAt(index + 1) == 0x75;

      if (!hasUnicodePrefix) {
        buffer.writeCharCode(codeUnit);
        continue;
      }

      final parsed = _readUnicodeEscape(input, index + 2);
      buffer.writeCharCode(parsed.codePoint);
      index = parsed.endIndex;
    }

    return buffer.toString();
  }

  _UnicodeEscapeParseResult _readUnicodeEscape(String input, int startIndex) {
    if (startIndex >= input.length) {
      throw const FormatException('Unicode 转义不完整，请使用 \\u4E2D 或 \\u{1F600} 格式。');
    }

    if (input.codeUnitAt(startIndex) == 0x7B) {
      return _readBraceUnicodeEscape(input, startIndex);
    }

    final endIndex = startIndex + 4;

    if (endIndex > input.length) {
      throw const FormatException('Unicode 转义不完整，请使用 4 位十六进制。');
    }

    final hex = input.substring(startIndex, endIndex);

    if (!_isHexText(hex)) {
      throw const FormatException('Unicode 转义只能包含十六进制字符。');
    }

    return _UnicodeEscapeParseResult(
      codePoint: int.parse(hex, radix: 16),
      endIndex: endIndex - 1,
    );
  }

  _UnicodeEscapeParseResult _readBraceUnicodeEscape(
    String input,
    int startIndex,
  ) {
    final closeIndex = input.indexOf('}', startIndex + 1);

    if (closeIndex == -1) {
      throw const FormatException('Unicode 大括号转义缺少结束的 }。');
    }

    final hex = input.substring(startIndex + 1, closeIndex);

    if (hex.isEmpty || !_isHexText(hex)) {
      throw const FormatException('Unicode 大括号转义只能包含十六进制字符。');
    }

    final codePoint = int.parse(hex, radix: 16);

    if (codePoint > 0x10FFFF) {
      throw const FormatException('Unicode 码点不能超过 U+10FFFF。');
    }

    return _UnicodeEscapeParseResult(
      codePoint: codePoint,
      endIndex: closeIndex,
    );
  }

  String _encodeUnicodeEscapes(String input) {
    final buffer = StringBuffer();

    for (final codeUnit in input.codeUnits) {
      if (_shouldKeepReadableAscii(codeUnit)) {
        buffer.writeCharCode(codeUnit);
        continue;
      }

      buffer.write(r'\u');
      buffer.write(codeUnit.toRadixString(16).toUpperCase().padLeft(4, '0'));
    }

    return buffer.toString();
  }

  bool _shouldKeepReadableAscii(int codeUnit) {
    return codeUnit >= 0x20 && codeUnit <= 0x7E && codeUnit != 0x5C;
  }

  String _decodeUtf8Hex(String input) {
    final hexText = _collectHexDigits(input);

    if (hexText.isEmpty) {
      throw const FormatException('UTF-8 十六进制输入为空，或没有有效字符。');
    }

    if (hexText.length.isOdd) {
      throw const FormatException('UTF-8 十六进制需要按完整字节输入，请补齐两位。');
    }

    final bytes = <int>[];

    for (var index = 0; index < hexText.length; index += 2) {
      bytes.add(int.parse(hexText.substring(index, index + 2), radix: 16));
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('十六进制字节不是有效的 UTF-8 文本。');
    }
  }

  String _encodeUtf8Hex(String input) {
    final bytes = utf8.encode(input);

    return bytes
        .map((byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
  }

  String _decodeBase64(String input) {
    final normalizedInput = input.replaceAll(RegExp(r'\s+'), '');

    if (normalizedInput.isEmpty) {
      throw const FormatException('Base64 输入为空。');
    }

    try {
      final normalizedBase64 = base64.normalize(normalizedInput);
      return utf8.decode(base64.decode(normalizedBase64));
    } on FormatException {
      throw const FormatException('Base64 内容格式不正确，或解码后不是有效的 UTF-8 文本。');
    }
  }

  String _collectHexDigits(String input) {
    return input
        .replaceAll(RegExp(r'0[xX]|\\x|%'), '')
        .split('')
        .where((character) => RegExp(r'[0-9a-fA-F]').hasMatch(character))
        .join();
  }

  bool _isHexText(String value) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSide = _resolveSourceSide();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '编码转换',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持普通文本、URL 编码、Unicode 转义、UTF-8 十六进制和 Base64 互转。',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _EncodingInputPanel(
                      isActive: activeSide == _EncodingSide.left,
                      controller: _leftController,
                      focusNode: _leftFocusNode,
                      selectedFormat: _leftFormat,
                      onChanged: _handleLeftChanged,
                      onFormatSelected: (_EncodingFormat value) {
                        _handleFormatChanged(_EncodingSide.left, value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _EncodingActionPanel(
                    onConvert: _handleConvert,
                    onClear: _handleClear,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _EncodingInputPanel(
                      isActive: activeSide == _EncodingSide.right,
                      controller: _rightController,
                      focusNode: _rightFocusNode,
                      selectedFormat: _rightFormat,
                      onChanged: _handleRightChanged,
                      onFormatSelected: (_EncodingFormat value) {
                        _handleFormatChanged(_EncodingSide.right, value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _EncodingInfoChip(
              label: activeSide == _EncodingSide.left
                  ? '当前来源：左侧输入框'
                  : '当前来源：右侧输入框',
            ),
            const _EncodingInfoChip(label: 'URL 编码按组件规则处理'),
            const _EncodingInfoChip(label: 'Unicode 支持 \\u4E2D 与 \\u{1F600}'),
            const _EncodingInfoChip(label: 'Hex 按 UTF-8 字节分组'),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 16),
          _EncodingErrorBanner(message: _errorText!),
        ],
      ],
    );
  }
}

class _UnicodeEscapeParseResult {
  const _UnicodeEscapeParseResult({
    required this.codePoint,
    required this.endIndex,
  });

  final int codePoint;
  final int endIndex;
}

class _EncodingInputPanel extends StatelessWidget {
  const _EncodingInputPanel({
    required this.isActive,
    required this.controller,
    required this.focusNode,
    required this.selectedFormat,
    required this.onChanged,
    required this.onFormatSelected,
  });

  final bool isActive;
  final TextEditingController controller;
  final FocusNode focusNode;
  final _EncodingFormat selectedFormat;
  final ValueChanged<String> onChanged;
  final ValueChanged<_EncodingFormat> onFormatSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFF0F766E) : const Color(0xFFD8E2E8),
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_EncodingFormat>(
                segments: _EncodingFormat.values
                    .map(
                      (_EncodingFormat value) => ButtonSegment<_EncodingFormat>(
                        value: value,
                        label: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                selected: <_EncodingFormat>{selectedFormat},
                onSelectionChanged: (Set<_EncodingFormat> selection) {
                  onFormatSelected(selection.first);
                },
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                expands: true,
                maxLines: null,
                minLines: null,
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: selectedFormat.hintText,
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

class _EncodingActionPanel extends StatelessWidget {
  const _EncodingActionPanel({required this.onConvert, required this.onClear});

  final VoidCallback onConvert;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: onConvert,
            icon: const Icon(Icons.sync_alt_rounded),
            label: const Text('转换'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded),
            label: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _EncodingInfoChip extends StatelessWidget {
  const _EncodingInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7D8D3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF0F766E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EncodingErrorBanner extends StatelessWidget {
  const _EncodingErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0B6B2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFC63C34)),
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

extension on _EncodingFormat {
  String get label {
    switch (this) {
      case _EncodingFormat.plainText:
        return '文本';
      case _EncodingFormat.urlEncoded:
        return 'URL';
      case _EncodingFormat.unicodeEscaped:
        return 'Unicode';
      case _EncodingFormat.utf8Hex:
        return 'Hex';
      case _EncodingFormat.base64:
        return 'Base64';
    }
  }

  String get hintText {
    switch (this) {
      case _EncodingFormat.plainText:
        return '例如 Hello 世界 / a=b&name=张三';
      case _EncodingFormat.urlEncoded:
        return '例如 Hello%20%E4%B8%96%E7%95%8C';
      case _EncodingFormat.unicodeEscaped:
        return r'例如 Hello \u4E16\u754C 或 \u{1F600}';
      case _EncodingFormat.utf8Hex:
        return '例如 48 65 6C 6C 6F E4 B8 96 E7 95 8C';
      case _EncodingFormat.base64:
        return '例如 SGVsbG8g5LiW55WM';
    }
  }
}
