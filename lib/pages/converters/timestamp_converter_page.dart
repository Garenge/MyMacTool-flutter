import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/time_utils.dart';

class TimestampConverterPage extends StatefulWidget {
  const TimestampConverterPage({super.key});

  @override
  State<TimestampConverterPage> createState() => _TimestampConverterPageState();
}

class _TimestampConverterPageState extends State<TimestampConverterPage> {
  static final BigInt _maxSupportedMilliseconds = BigInt.from(8640000000000000);

  final TextEditingController _inputController = TextEditingController();
  _TimestampResult? _result;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _applyDateTime(DateTime.now(), statusText: '已填入当前时间。');
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleUseNow() {
    _applyDateTime(DateTime.now(), statusText: '已刷新为当前时间。');
  }

  void _handleConvert() {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _errorText = '请先输入秒 / 毫秒时间戳，或 ISO 时间文本。';
      });
      return;
    }

    try {
      final dateTime = _parseInput(input);
      _applyDateTime(dateTime, statusText: '转换完成。');
    } on FormatException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    }
  }

  DateTime _parseInput(String input) {
    final numericText = input.replaceAll(RegExp(r'[,_\s]'), '');

    if (RegExp(r'^-?\d+$').hasMatch(numericText)) {
      return _parseTimestamp(numericText);
    }

    final parsedDateTime = DateTime.tryParse(input);

    if (parsedDateTime == null) {
      throw const FormatException('无法识别输入，请使用时间戳或 ISO 时间格式。');
    }

    return parsedDateTime;
  }

  DateTime _parseTimestamp(String numericText) {
    final value = BigInt.parse(numericText);
    final absoluteLength = numericText.startsWith('-')
        ? numericText.length - 1
        : numericText.length;
    final milliseconds = absoluteLength <= 10
        ? value * BigInt.from(1000)
        : value;

    if (milliseconds > _maxSupportedMilliseconds ||
        milliseconds < -_maxSupportedMilliseconds) {
      throw const FormatException('时间戳超出可转换范围。');
    }

    try {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
    } on ArgumentError {
      throw const FormatException('时间戳超出可转换范围。');
    }
  }

  void _applyDateTime(DateTime dateTime, {required String statusText}) {
    final result = _TimestampResult.fromDateTime(dateTime, statusText);

    setState(() {
      _inputController.text = result.millisecondsSinceEpoch;
      _result = result;
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
          '时间戳转换',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持秒 / 毫秒时间戳、本地时间和 UTC 时间互转，也支持粘贴 ISO 时间文本。',
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
                  _TimestampInputBar(
                    controller: _inputController,
                    onUseNow: _handleUseNow,
                    onConvert: _handleConvert,
                    onClear: _handleClear,
                  ),
                  const SizedBox(height: 18),
                  if (_errorText != null) ...[
                    _TimestampMessageBanner(
                      message: _errorText!,
                      isError: true,
                    ),
                    const SizedBox(height: 18),
                  ] else if (result != null) ...[
                    _TimestampMessageBanner(
                      message: result.statusText,
                      isError: false,
                    ),
                    const SizedBox(height: 18),
                  ],
                  Expanded(
                    child: result == null
                        ? const _TimestampEmptyState()
                        : _TimestampResultGrid(
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

class _TimestampResult {
  const _TimestampResult({
    required this.secondsSinceEpoch,
    required this.millisecondsSinceEpoch,
    required this.localDateTime,
    required this.utcDateTime,
    required this.isoDateTime,
    required this.statusText,
  });

  factory _TimestampResult.fromDateTime(DateTime value, String statusText) {
    final localValue = value.toLocal();
    final utcValue = value.toUtc();
    final milliseconds = utcValue.millisecondsSinceEpoch;

    return _TimestampResult(
      secondsSinceEpoch: (milliseconds ~/ 1000).toString(),
      millisecondsSinceEpoch: milliseconds.toString(),
      localDateTime: _formatDateTime(localValue),
      utcDateTime: '${_formatDateTime(utcValue)} UTC',
      isoDateTime: utcValue.toIso8601String(),
      statusText: statusText,
    );
  }

  final String secondsSinceEpoch;
  final String millisecondsSinceEpoch;
  final String localDateTime;
  final String utcDateTime;
  final String isoDateTime;
  final String statusText;

  _TimestampResult copyWith({required String statusText}) {
    return _TimestampResult(
      secondsSinceEpoch: secondsSinceEpoch,
      millisecondsSinceEpoch: millisecondsSinceEpoch,
      localDateTime: localDateTime,
      utcDateTime: utcDateTime,
      isoDateTime: isoDateTime,
      statusText: statusText,
    );
  }

  static String _formatDateTime(DateTime value) {
    return formatDateTimeMillisecond(value);
  }
}

class _TimestampInputBar extends StatelessWidget {
  const _TimestampInputBar({
    required this.controller,
    required this.onUseNow,
    required this.onConvert,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onUseNow;
  final VoidCallback onConvert;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '输入时间',
              hintText: '例如 1716780000、1716780000000、2026-05-26T10:00:00Z',
              filled: true,
              fillColor: Colors.white,
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
            style: const TextStyle(fontFamily: 'Menlo', fontSize: 14),
            onSubmitted: (_) => onConvert(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onConvert,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('转换'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onUseNow,
          icon: const Icon(Icons.access_time_rounded),
          label: const Text('当前时间'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear_rounded),
          label: const Text('清空'),
        ),
      ],
    );
  }
}

class _TimestampMessageBanner extends StatelessWidget {
  const _TimestampMessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          ],
        ),
      ),
    );
  }
}

class _TimestampResultGrid extends StatelessWidget {
  const _TimestampResultGrid({required this.result, required this.onCopyValue});

  final _TimestampResult result;
  final void Function(String value, String statusText) onCopyValue;

  @override
  Widget build(BuildContext context) {
    final items = <_TimestampResultItem>[
      _TimestampResultItem(
        label: '秒时间戳',
        value: result.secondsSinceEpoch,
        copyMessage: '已复制秒时间戳。',
      ),
      _TimestampResultItem(
        label: '毫秒时间戳',
        value: result.millisecondsSinceEpoch,
        copyMessage: '已复制毫秒时间戳。',
      ),
      _TimestampResultItem(
        label: '本地时间',
        value: result.localDateTime,
        copyMessage: '已复制本地时间。',
      ),
      _TimestampResultItem(
        label: 'UTC时间',
        value: result.utcDateTime,
        copyMessage: '已复制 UTC 时间。',
      ),
      _TimestampResultItem(
        label: 'ISO时间',
        value: result.isoDateTime,
        copyMessage: '已复制 ISO 时间。',
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 132,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (BuildContext context, int index) {
        final item = items[index];

        return _TimestampResultCard(
          item: item,
          onCopy: () => onCopyValue(item.value, item.copyMessage),
        );
      },
    );
  }
}

class _TimestampResultItem {
  const _TimestampResultItem({
    required this.label,
    required this.value,
    required this.copyMessage,
  });

  final String label;
  final String value;
  final String copyMessage;
}

class _TimestampResultCard extends StatelessWidget {
  const _TimestampResultCard({required this.item, required this.onCopy});

  final _TimestampResultItem item;
  final VoidCallback onCopy;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF31414F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  tooltip: '复制',
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SelectableText(
                item.value,
                style: const TextStyle(
                  color: Color(0xFF52606D),
                  fontFamily: 'Menlo',
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimestampEmptyState extends StatelessWidget {
  const _TimestampEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Center(
        child: Text(
          '输入时间后点击转换，结果会显示在这里。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF708190)),
        ),
      ),
    );
  }
}
