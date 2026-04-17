import 'package:flutter/material.dart';

enum _RadixFormat { hex, unsignedDecimal, signedDecimal, binary }

enum _ConverterSide { left, right }

class _ParsedRadixValue {
  const _ParsedRadixValue({
    required this.unsignedValue,
    required this.signedValue,
    required this.bitWidth,
  });

  final BigInt unsignedValue;
  final BigInt signedValue;
  final int bitWidth;
}

class RadixConverterPage extends StatefulWidget {
  const RadixConverterPage({super.key});

  @override
  State<RadixConverterPage> createState() => _RadixConverterPageState();
}

class _RadixConverterPageState extends State<RadixConverterPage> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  final FocusNode _leftFocusNode = FocusNode();
  final FocusNode _rightFocusNode = FocusNode();

  _RadixFormat _leftFormat = _RadixFormat.hex;
  _RadixFormat _rightFormat = _RadixFormat.unsignedDecimal;
  _ConverterSide _lastEditedSide = _ConverterSide.left;
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
      _lastEditedSide = _ConverterSide.left;
      _errorText = null;
    });
  }

  void _handleRightChanged(String _) {
    setState(() {
      _lastEditedSide = _ConverterSide.right;
      _errorText = null;
    });
  }

  void _handleConvert() {
    _convertFromSide(_resolveSourceSide());
  }

  void _handleFormatChanged(_ConverterSide side, _RadixFormat value) {
    setState(() {
      if (side == _ConverterSide.left) {
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

  void _convertFromSide(_ConverterSide sourceSide) {
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
      final parsedValue = _parseValue(rawText, sourceFormat);
      final formattedSource = _formatValue(sourceFormat, parsedValue);
      final formattedTarget = _formatValue(targetFormat, parsedValue);

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
      _lastEditedSide = _ConverterSide.left;
    });
  }

  void _updateControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  _ConverterSide _resolveSourceSide() {
    if (_leftFocusNode.hasFocus) {
      return _ConverterSide.left;
    }

    if (_rightFocusNode.hasFocus) {
      return _ConverterSide.right;
    }

    final leftHasValue = _leftController.text.trim().isNotEmpty;
    final rightHasValue = _rightController.text.trim().isNotEmpty;

    if (leftHasValue && !rightHasValue) {
      return _ConverterSide.left;
    }

    if (rightHasValue && !leftHasValue) {
      return _ConverterSide.right;
    }

    return _lastEditedSide;
  }

  TextEditingController _controllerFor(_ConverterSide side) {
    return side == _ConverterSide.left ? _leftController : _rightController;
  }

  _RadixFormat _formatFor(_ConverterSide side) {
    return side == _ConverterSide.left ? _leftFormat : _rightFormat;
  }

  _ConverterSide _otherSide(_ConverterSide side) {
    return side == _ConverterSide.left
        ? _ConverterSide.right
        : _ConverterSide.left;
  }

  _ParsedRadixValue _parseValue(String input, _RadixFormat format) {
    switch (format) {
      case _RadixFormat.hex:
        return _parseHexValue(input);
      case _RadixFormat.unsignedDecimal:
        return _parseUnsignedDecimalValue(input);
      case _RadixFormat.signedDecimal:
        return _parseSignedDecimalValue(input);
      case _RadixFormat.binary:
        return _parseBinaryValue(input);
    }
  }

  _ParsedRadixValue _parseHexValue(String input) {
    final digits = _collectMatches(
      input.replaceAll(RegExp(r'0[xX]'), ''),
      RegExp(r'[0-9a-fA-F]'),
    );

    if (digits.isEmpty) {
      throw const FormatException('十六进制输入为空，或没有有效字符。');
    }

    final normalizedDigits = (digits.length.isOdd ? '0$digits' : digits)
        .toUpperCase();
    final unsignedValue = BigInt.parse(normalizedDigits, radix: 16);
    final bitWidth = normalizedDigits.length * 4;

    return _ParsedRadixValue(
      unsignedValue: unsignedValue,
      signedValue: _toSigned(unsignedValue, bitWidth),
      bitWidth: bitWidth,
    );
  }

  _ParsedRadixValue _parseUnsignedDecimalValue(String input) {
    final digits = _collectMatches(input, RegExp(r'\d'));

    if (digits.isEmpty) {
      throw const FormatException('十进制无符号输入为空，或没有有效数字。');
    }

    final unsignedValue = BigInt.parse(digits);

    return _ParsedRadixValue(
      unsignedValue: unsignedValue,
      signedValue: unsignedValue,
      bitWidth: _unsignedBitWidth(unsignedValue),
    );
  }

  _ParsedRadixValue _parseSignedDecimalValue(String input) {
    final digits = _collectMatches(input, RegExp(r'\d'));

    if (digits.isEmpty) {
      throw const FormatException('十进制有符号输入为空，或没有有效数字。');
    }

    final isNegative = RegExp(r'^\s*-').hasMatch(input);
    final signedValue = BigInt.parse('${isNegative ? '-' : ''}$digits');
    final bitWidth = _signedBitWidth(signedValue);
    final unsignedValue = signedValue.isNegative
        ? _toUnsigned(signedValue, bitWidth)
        : signedValue;

    return _ParsedRadixValue(
      unsignedValue: unsignedValue,
      signedValue: signedValue,
      bitWidth: bitWidth,
    );
  }

  _ParsedRadixValue _parseBinaryValue(String input) {
    final bits = _collectMatches(
      input.replaceAll(RegExp(r'0[bB]'), ''),
      RegExp(r'[01]'),
    );

    if (bits.isEmpty) {
      throw const FormatException('二进制输入为空，或没有有效的 0/1 字符。');
    }

    final unsignedValue = BigInt.parse(bits, radix: 2);
    final bitWidth = bits.length <= 4 ? 4 : bits.length;

    return _ParsedRadixValue(
      unsignedValue: unsignedValue,
      signedValue: _toSigned(unsignedValue, bitWidth),
      bitWidth: bitWidth,
    );
  }

  String _formatValue(_RadixFormat format, _ParsedRadixValue value) {
    switch (format) {
      case _RadixFormat.hex:
        return _formatHex(value.unsignedValue, value.bitWidth);
      case _RadixFormat.unsignedDecimal:
        return _formatDecimal(value.unsignedValue);
      case _RadixFormat.signedDecimal:
        return _formatDecimal(value.signedValue);
      case _RadixFormat.binary:
        return _formatBinary(value.unsignedValue, value.bitWidth);
    }
  }

  String _formatHex(BigInt value, int bitWidth) {
    final digitWidth = ((bitWidth <= 8 ? 8 : _alignToByte(bitWidth)) / 4)
        .ceil();
    final raw = value.toRadixString(16).toUpperCase().padLeft(digitWidth, '0');

    return _groupFromLeft(raw, 2);
  }

  String _formatBinary(BigInt value, int bitWidth) {
    final targetWidth = bitWidth <= 4 ? 4 : _alignToByte(bitWidth);
    final raw = value.toRadixString(2).padLeft(targetWidth, '0');
    final groupSize = raw.length <= 16 ? 4 : 8;

    return _groupFromLeft(raw, groupSize);
  }

  String _formatDecimal(BigInt value) {
    final raw = value.toString();
    final isNegative = raw.startsWith('-');
    final digits = isNegative ? raw.substring(1) : raw;
    final grouped = _groupFromRight(digits, 3);

    return isNegative ? '-$grouped' : grouped;
  }

  int _unsignedBitWidth(BigInt value) {
    if (value == BigInt.zero) {
      return 1;
    }

    return value.bitLength;
  }

  int _signedBitWidth(BigInt value) {
    if (value >= BigInt.zero) {
      return _alignSignedWidth(value.bitLength + 1);
    }

    var width = 1;

    while (value < -(BigInt.one << (width - 1))) {
      width += 1;
    }

    return _alignSignedWidth(width);
  }

  int _alignSignedWidth(int width) {
    final normalizedWidth = width <= 0 ? 1 : width;
    return normalizedWidth <= 8 ? 8 : _alignToByte(normalizedWidth);
  }

  int _alignToByte(int width) {
    final remainder = width % 8;

    if (remainder == 0) {
      return width;
    }

    return width + 8 - remainder;
  }

  BigInt _toSigned(BigInt unsignedValue, int bitWidth) {
    if (bitWidth <= 0) {
      return unsignedValue;
    }

    final signBit = BigInt.one << (bitWidth - 1);

    if ((unsignedValue & signBit) == BigInt.zero) {
      return unsignedValue;
    }

    return unsignedValue - (BigInt.one << bitWidth);
  }

  BigInt _toUnsigned(BigInt signedValue, int bitWidth) {
    return signedValue + (BigInt.one << bitWidth);
  }

  String _collectMatches(String input, RegExp expression) {
    return expression
        .allMatches(input)
        .map((match) => match.group(0) ?? '')
        .join();
  }

  String _groupFromLeft(String text, int groupSize) {
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index += groupSize) {
      if (index > 0) {
        buffer.write(' ');
      }

      final nextIndex = (index + groupSize).clamp(0, text.length);
      buffer.write(text.substring(index, nextIndex));
    }

    return buffer.toString();
  }

  String _groupFromRight(String text, int groupSize) {
    final characters = text.split('').reversed.toList(growable: false);
    final buffer = StringBuffer();

    for (var index = 0; index < characters.length; index += groupSize) {
      if (index > 0) {
        buffer.write(',');
      }

      final nextIndex = (index + groupSize).clamp(0, characters.length);
      buffer.writeAll(characters.sublist(index, nextIndex));
    }

    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSide = _resolveSourceSide();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '进制换算',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持十六进制、十进制无符号、十进制有符号和二进制互转，转换时会自动忽略空格、逗号、下划线等分隔符。',
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
                    child: _ConverterInputPanel(
                      isActive: activeSide == _ConverterSide.left,
                      controller: _leftController,
                      focusNode: _leftFocusNode,
                      selectedFormat: _leftFormat,
                      onChanged: _handleLeftChanged,
                      onFormatSelected: (_RadixFormat value) {
                        _handleFormatChanged(_ConverterSide.left, value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ConverterActionPanel(
                    onConvert: _handleConvert,
                    onClear: _handleClear,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ConverterInputPanel(
                      isActive: activeSide == _ConverterSide.right,
                      controller: _rightController,
                      focusNode: _rightFocusNode,
                      selectedFormat: _rightFormat,
                      onChanged: _handleRightChanged,
                      onFormatSelected: (_RadixFormat value) {
                        _handleFormatChanged(_ConverterSide.right, value);
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
            _InfoChip(
              label: activeSide == _ConverterSide.left
                  ? '当前来源：左侧输入框'
                  : '当前来源：右侧输入框',
            ),
            const _InfoChip(label: '十六进制输出按字节补齐并空格分组'),
            const _InfoChip(label: '二进制输出按 4 位或 8 位自动分组'),
            const _InfoChip(label: '十进制输出自动加千分位逗号'),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _errorText!),
        ],
      ],
    );
  }
}

class _ConverterInputPanel extends StatelessWidget {
  const _ConverterInputPanel({
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
  final _RadixFormat selectedFormat;
  final ValueChanged<String> onChanged;
  final ValueChanged<_RadixFormat> onFormatSelected;

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
            SegmentedButton<_RadixFormat>(
              segments: _RadixFormat.values
                  .map(
                    (_RadixFormat value) => ButtonSegment<_RadixFormat>(
                      value: value,
                      label: Text(value.label),
                    ),
                  )
                  .toList(growable: false),
              selected: <_RadixFormat>{selectedFormat},
              onSelectionChanged: (Set<_RadixFormat> selection) {
                onFormatSelected(selection.first);
              },
              showSelectedIcon: false,
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

class _ConverterActionPanel extends StatelessWidget {
  const _ConverterActionPanel({required this.onConvert, required this.onClear});

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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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

extension on _RadixFormat {
  String get label {
    switch (this) {
      case _RadixFormat.hex:
        return '十六进制';
      case _RadixFormat.unsignedDecimal:
        return '十进制无符号';
      case _RadixFormat.signedDecimal:
        return '十进制有符号';
      case _RadixFormat.binary:
        return '二进制';
    }
  }

  String get hintText {
    switch (this) {
      case _RadixFormat.hex:
        return '例如 7F FF、0x7fff、ff_ff';
      case _RadixFormat.unsignedDecimal:
        return '例如 4294967295、4_294_967_295';
      case _RadixFormat.signedDecimal:
        return '例如 -128、-2,147,483,648';
      case _RadixFormat.binary:
        return '例如 1010 1100、0b10101100';
    }
  }
}
