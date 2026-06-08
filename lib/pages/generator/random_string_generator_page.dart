import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RandomStringGeneratorPage extends StatefulWidget {
  const RandomStringGeneratorPage({super.key});

  @override
  State<RandomStringGeneratorPage> createState() =>
      _RandomStringGeneratorPageState();
}

class _RandomStringGeneratorPageState extends State<RandomStringGeneratorPage> {
  static const String _lowerChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digitChars = '0123456789';
  static const String _symbolChars = r'!@#$%^&*_-+=';

  final Random _random = Random.secure();
  int _uuidCount = 5;
  int _randomCount = 5;
  int _randomLength = 16;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeDigits = true;
  bool _includeSymbols = false;
  List<String> _results = const <String>[];
  String? _statusText;
  String? _errorText;

  void _generateUuids() {
    setState(() {
      _results = List<String>.generate(_uuidCount, (_) => _buildUuidV4());
      _statusText = '已生成 $_uuidCount 个 UUID v4。';
      _errorText = null;
    });
  }

  void _generateRandomStrings() {
    final pool = _buildCharacterPool();

    if (pool.isEmpty) {
      setState(() {
        _errorText = '请至少选择一种字符类型。';
        _statusText = null;
      });
      return;
    }

    setState(() {
      _results = List<String>.generate(
        _randomCount,
        (_) => _buildRandomString(pool),
      );
      _statusText = '已生成 $_randomCount 个随机字符串。';
      _errorText = null;
    });
  }

  Future<void> _copyAll() async {
    if (_results.isEmpty) {
      setState(() {
        _errorText = '当前没有可复制的结果。';
        _statusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: _results.join('\n')));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制全部结果。';
      _errorText = null;
    });
  }

  Future<void> _copyOne(String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制单项结果。';
      _errorText = null;
    });
  }

  void _clearResults() {
    setState(() {
      _results = const <String>[];
      _statusText = null;
      _errorText = null;
    });
  }

  String _buildCharacterPool() {
    return [
      if (_includeLowercase) _lowerChars,
      if (_includeUppercase) _upperChars,
      if (_includeDigits) _digitChars,
      if (_includeSymbols) _symbolChars,
    ].join();
  }

  String _buildRandomString(String pool) {
    return List<String>.generate(
      _randomLength,
      (_) => pool[_random.nextInt(pool.length)],
    ).join();
  }

  String _buildUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  void _setUuidCount(double value) {
    setState(() {
      _uuidCount = value.round();
    });
  }

  void _setRandomCount(double value) {
    setState(() {
      _randomCount = value.round();
    });
  }

  void _setRandomLength(double value) {
    setState(() {
      _randomLength = value.round();
    });
  }

  void _setIncludeLowercase(bool value) {
    setState(() {
      _includeLowercase = value;
    });
  }

  void _setIncludeUppercase(bool value) {
    setState(() {
      _includeUppercase = value;
    });
  }

  void _setIncludeDigits(bool value) {
    setState(() {
      _includeDigits = value;
    });
  }

  void _setIncludeSymbols(bool value) {
    setState(() {
      _includeSymbols = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '随机生成',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持批量生成 UUID v4 和指定长度随机字符串，适合调试、占位和临时密钥场景。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 390,
                child: _GeneratorSettingsPanel(
                  uuidCount: _uuidCount,
                  randomCount: _randomCount,
                  randomLength: _randomLength,
                  includeLowercase: _includeLowercase,
                  includeUppercase: _includeUppercase,
                  includeDigits: _includeDigits,
                  includeSymbols: _includeSymbols,
                  statusText: _errorText ?? _statusText,
                  isError: _errorText != null,
                  onUuidCountChanged: _setUuidCount,
                  onRandomCountChanged: _setRandomCount,
                  onRandomLengthChanged: _setRandomLength,
                  onIncludeLowercaseChanged: _setIncludeLowercase,
                  onIncludeUppercaseChanged: _setIncludeUppercase,
                  onIncludeDigitsChanged: _setIncludeDigits,
                  onIncludeSymbolsChanged: _setIncludeSymbols,
                  onGenerateUuids: _generateUuids,
                  onGenerateRandomStrings: _generateRandomStrings,
                  onCopyAll: _copyAll,
                  onClear: _clearResults,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _GeneratedResultsPanel(
                  results: _results,
                  onCopyOne: _copyOne,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneratorSettingsPanel extends StatelessWidget {
  const _GeneratorSettingsPanel({
    required this.uuidCount,
    required this.randomCount,
    required this.randomLength,
    required this.includeLowercase,
    required this.includeUppercase,
    required this.includeDigits,
    required this.includeSymbols,
    required this.statusText,
    required this.isError,
    required this.onUuidCountChanged,
    required this.onRandomCountChanged,
    required this.onRandomLengthChanged,
    required this.onIncludeLowercaseChanged,
    required this.onIncludeUppercaseChanged,
    required this.onIncludeDigitsChanged,
    required this.onIncludeSymbolsChanged,
    required this.onGenerateUuids,
    required this.onGenerateRandomStrings,
    required this.onCopyAll,
    required this.onClear,
  });

  final int uuidCount;
  final int randomCount;
  final int randomLength;
  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeDigits;
  final bool includeSymbols;
  final String? statusText;
  final bool isError;
  final ValueChanged<double> onUuidCountChanged;
  final ValueChanged<double> onRandomCountChanged;
  final ValueChanged<double> onRandomLengthChanged;
  final ValueChanged<bool> onIncludeLowercaseChanged;
  final ValueChanged<bool> onIncludeUppercaseChanged;
  final ValueChanged<bool> onIncludeDigitsChanged;
  final ValueChanged<bool> onIncludeSymbolsChanged;
  final VoidCallback onGenerateUuids;
  final VoidCallback onGenerateRandomStrings;
  final VoidCallback onCopyAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsSection(
                      title: 'UUID v4',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LabeledSlider(
                            label: '数量',
                            value: uuidCount,
                            min: 1,
                            max: 50,
                            onChanged: onUuidCountChanged,
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateUuids,
                            icon: const Icon(Icons.tag_rounded),
                            label: const Text('生成 UUID'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsSection(
                      title: '随机字符串',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LabeledSlider(
                            label: '数量',
                            value: randomCount,
                            min: 1,
                            max: 50,
                            onChanged: onRandomCountChanged,
                          ),
                          _LabeledSlider(
                            label: '长度',
                            value: randomLength,
                            min: 4,
                            max: 128,
                            onChanged: onRandomLengthChanged,
                          ),
                          _CharacterOptions(
                            includeLowercase: includeLowercase,
                            includeUppercase: includeUppercase,
                            includeDigits: includeDigits,
                            includeSymbols: includeSymbols,
                            onIncludeLowercaseChanged:
                                onIncludeLowercaseChanged,
                            onIncludeUppercaseChanged:
                                onIncludeUppercaseChanged,
                            onIncludeDigitsChanged: onIncludeDigitsChanged,
                            onIncludeSymbolsChanged: onIncludeSymbolsChanged,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: onGenerateRandomStrings,
                            icon: const Icon(Icons.password_rounded),
                            label: const Text('生成随机字符串'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (statusText != null) ...[
                      _StatusBanner(message: statusText!, isError: isError),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCopyAll,
                            icon: const Icon(Icons.copy_all_rounded),
                            label: const Text('复制全部'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.cleaning_services_rounded),
                          label: const Text('清空'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

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

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF607180),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CharacterOptions extends StatelessWidget {
  const _CharacterOptions({
    required this.includeLowercase,
    required this.includeUppercase,
    required this.includeDigits,
    required this.includeSymbols,
    required this.onIncludeLowercaseChanged,
    required this.onIncludeUppercaseChanged,
    required this.onIncludeDigitsChanged,
    required this.onIncludeSymbolsChanged,
  });

  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeDigits;
  final bool includeSymbols;
  final ValueChanged<bool> onIncludeLowercaseChanged;
  final ValueChanged<bool> onIncludeUppercaseChanged;
  final ValueChanged<bool> onIncludeDigitsChanged;
  final ValueChanged<bool> onIncludeSymbolsChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _OptionChip(
          label: '小写',
          selected: includeLowercase,
          onChanged: onIncludeLowercaseChanged,
        ),
        _OptionChip(
          label: '大写',
          selected: includeUppercase,
          onChanged: onIncludeUppercaseChanged,
        ),
        _OptionChip(
          label: '数字',
          selected: includeDigits,
          onChanged: onIncludeDigitsChanged,
        ),
        _OptionChip(
          label: '符号',
          selected: includeSymbols,
          onChanged: onIncludeSymbolsChanged,
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: const Color(0xFFEAF7F6),
      checkmarkColor: const Color(0xFF0F766E),
    );
  }
}

class _GeneratedResultsPanel extends StatelessWidget {
  const _GeneratedResultsPanel({
    required this.results,
    required this.onCopyOne,
  });

  final List<String> results;
  final Future<void> Function(String value) onCopyOne;

  @override
  Widget build(BuildContext context) {
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
            Text(
              '生成结果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: _MutedText('生成后的内容会显示在这里。'))
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final value = results[index];

                        return _GeneratedResultTile(
                          index: index + 1,
                          value: value,
                          onCopy: () => onCopyOne(value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedResultTile extends StatelessWidget {
  const _GeneratedResultTile({
    required this.index,
    required this.value,
    required this.onCopy,
  });

  final int index;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF607180),
                  fontWeight: FontWeight.w800,
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
            IconButton(
              onPressed: onCopy,
              tooltip: '复制',
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          message,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
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
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
    );
  }
}
