import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegexTesterPage extends StatefulWidget {
  const RegexTesterPage({super.key});

  @override
  State<RegexTesterPage> createState() => _RegexTesterPageState();
}

class _RegexTesterPageState extends State<RegexTesterPage> {
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _replacementController = TextEditingController();
  bool _caseSensitive = true;
  bool _multiLine = false;
  bool _dotAll = false;
  bool _unicode = false;
  List<_RegexMatchInfo> _matches = const <_RegexMatchInfo>[];
  String _replacementPreview = '';
  String? _statusText;
  String? _errorText;

  @override
  void dispose() {
    _patternController.dispose();
    _textController.dispose();
    _replacementController.dispose();
    super.dispose();
  }

  void _runRegex() {
    final pattern = _patternController.text;
    final input = _textController.text;

    if (pattern.isEmpty) {
      setState(() {
        _matches = const <_RegexMatchInfo>[];
        _replacementPreview = '';
        _errorText = '请先输入正则表达式。';
        _statusText = null;
      });
      return;
    }

    try {
      final regex = _buildRegExp(pattern);
      final matches = regex
          .allMatches(input)
          .take(200)
          .indexed
          .map(
            ((int, RegExpMatch) entry) =>
                _RegexMatchInfo.fromMatch(entry.$1 + 1, entry.$2),
          )
          .toList();
      final replacement = _replacementController.text;

      setState(() {
        _matches = matches;
        _replacementPreview = replacement.isEmpty
            ? ''
            : input.replaceAll(regex, replacement);
        _statusText = matches.isEmpty
            ? '未匹配到结果。'
            : '匹配到 ${matches.length} 处结果。';
        _errorText = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _matches = const <_RegexMatchInfo>[];
        _replacementPreview = '';
        _errorText = error.message;
        _statusText = null;
      });
    }
  }

  Future<void> _copyMatches() async {
    if (_matches.isEmpty) {
      setState(() {
        _errorText = '当前没有可复制的匹配结果。';
        _statusText = null;
      });
      return;
    }

    final lines = _matches.map((match) => match.toSummaryText()).join('\n\n');
    await Clipboard.setData(ClipboardData(text: lines));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制匹配结果。';
      _errorText = null;
    });
  }

  Future<void> _copyReplacementPreview() async {
    if (_replacementPreview.isEmpty) {
      setState(() {
        _errorText = '当前没有可复制的替换预览。';
        _statusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: _replacementPreview));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制替换预览。';
      _errorText = null;
    });
  }

  void _clearAll() {
    setState(() {
      _patternController.clear();
      _textController.clear();
      _replacementController.clear();
      _matches = const <_RegexMatchInfo>[];
      _replacementPreview = '';
      _statusText = null;
      _errorText = null;
    });
  }

  RegExp _buildRegExp(String pattern) {
    return RegExp(
      pattern,
      caseSensitive: _caseSensitive,
      multiLine: _multiLine,
      dotAll: _dotAll,
      unicode: _unicode,
    );
  }

  void _setCaseSensitive(bool value) {
    setState(() {
      _caseSensitive = value;
    });
  }

  void _setMultiLine(bool value) {
    setState(() {
      _multiLine = value;
    });
  }

  void _setDotAll(bool value) {
    setState(() {
      _dotAll = value;
    });
  }

  void _setUnicode(bool value) {
    setState(() {
      _unicode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '正则测试',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '输入正则和测试文本后，查看全局匹配、捕获分组和替换预览。',
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
                width: 430,
                child: _RegexInputPanel(
                  patternController: _patternController,
                  textController: _textController,
                  replacementController: _replacementController,
                  caseSensitive: _caseSensitive,
                  multiLine: _multiLine,
                  dotAll: _dotAll,
                  unicode: _unicode,
                  statusText: _errorText ?? _statusText,
                  isError: _errorText != null,
                  onCaseSensitiveChanged: _setCaseSensitive,
                  onMultiLineChanged: _setMultiLine,
                  onDotAllChanged: _setDotAll,
                  onUnicodeChanged: _setUnicode,
                  onRun: _runRegex,
                  onClear: _clearAll,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _RegexResultPanel(
                  matches: _matches,
                  replacementPreview: _replacementPreview,
                  onCopyMatches: _copyMatches,
                  onCopyReplacementPreview: _copyReplacementPreview,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegexInputPanel extends StatelessWidget {
  const _RegexInputPanel({
    required this.patternController,
    required this.textController,
    required this.replacementController,
    required this.caseSensitive,
    required this.multiLine,
    required this.dotAll,
    required this.unicode,
    required this.statusText,
    required this.isError,
    required this.onCaseSensitiveChanged,
    required this.onMultiLineChanged,
    required this.onDotAllChanged,
    required this.onUnicodeChanged,
    required this.onRun,
    required this.onClear,
  });

  final TextEditingController patternController;
  final TextEditingController textController;
  final TextEditingController replacementController;
  final bool caseSensitive;
  final bool multiLine;
  final bool dotAll;
  final bool unicode;
  final String? statusText;
  final bool isError;
  final ValueChanged<bool> onCaseSensitiveChanged;
  final ValueChanged<bool> onMultiLineChanged;
  final ValueChanged<bool> onDotAllChanged;
  final ValueChanged<bool> onUnicodeChanged;
  final VoidCallback onRun;
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: patternController,
                onSubmitted: (_) => onRun(),
                decoration: const InputDecoration(
                  labelText: '正则表达式',
                  hintText: r'(\w+)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _FlagOptions(
                caseSensitive: caseSensitive,
                multiLine: multiLine,
                dotAll: dotAll,
                unicode: unicode,
                onCaseSensitiveChanged: onCaseSensitiveChanged,
                onMultiLineChanged: onMultiLineChanged,
                onDotAllChanged: onDotAllChanged,
                onUnicodeChanged: onUnicodeChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 7,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '测试文本',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replacementController,
                decoration: const InputDecoration(
                  labelText: '替换为',
                  hintText: '留空则不生成替换预览',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRun,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('测试正则'),
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
              if (statusText != null) ...[
                const SizedBox(height: 14),
                _StatusBanner(message: statusText!, isError: isError),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagOptions extends StatelessWidget {
  const _FlagOptions({
    required this.caseSensitive,
    required this.multiLine,
    required this.dotAll,
    required this.unicode,
    required this.onCaseSensitiveChanged,
    required this.onMultiLineChanged,
    required this.onDotAllChanged,
    required this.onUnicodeChanged,
  });

  final bool caseSensitive;
  final bool multiLine;
  final bool dotAll;
  final bool unicode;
  final ValueChanged<bool> onCaseSensitiveChanged;
  final ValueChanged<bool> onMultiLineChanged;
  final ValueChanged<bool> onDotAllChanged;
  final ValueChanged<bool> onUnicodeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FlagChip(
          label: '区分大小写',
          selected: caseSensitive,
          onChanged: onCaseSensitiveChanged,
        ),
        _FlagChip(
          label: '多行',
          selected: multiLine,
          onChanged: onMultiLineChanged,
        ),
        _FlagChip(
          label: 'DotAll',
          selected: dotAll,
          onChanged: onDotAllChanged,
        ),
        _FlagChip(
          label: 'Unicode',
          selected: unicode,
          onChanged: onUnicodeChanged,
        ),
      ],
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
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

class _RegexResultPanel extends StatelessWidget {
  const _RegexResultPanel({
    required this.matches,
    required this.replacementPreview,
    required this.onCopyMatches,
    required this.onCopyReplacementPreview,
  });

  final List<_RegexMatchInfo> matches;
  final String replacementPreview;
  final VoidCallback onCopyMatches;
  final VoidCallback onCopyReplacementPreview;

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
            _ResultToolbar(
              matchCount: matches.length,
              hasReplacementPreview: replacementPreview.isNotEmpty,
              onCopyMatches: onCopyMatches,
              onCopyReplacementPreview: onCopyReplacementPreview,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: matches.isEmpty && replacementPreview.isEmpty
                  ? const Center(child: _MutedText('匹配结果和替换预览会显示在这里。'))
                  : ListView(
                      children: [
                        if (matches.isNotEmpty)
                          ...matches.map(_RegexMatchCard.new),
                        if (replacementPreview.isNotEmpty) ...[
                          if (matches.isNotEmpty) const SizedBox(height: 12),
                          _ReplacementPreviewCard(value: replacementPreview),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultToolbar extends StatelessWidget {
  const _ResultToolbar({
    required this.matchCount,
    required this.hasReplacementPreview,
    required this.onCopyMatches,
    required this.onCopyReplacementPreview,
  });

  final int matchCount;
  final bool hasReplacementPreview;
  final VoidCallback onCopyMatches;
  final VoidCallback onCopyReplacementPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '匹配结果 · $matchCount',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF23313C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: matchCount == 0 ? null : onCopyMatches,
          icon: const Icon(Icons.copy_all_rounded, size: 18),
          label: const Text('匹配'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: hasReplacementPreview ? onCopyReplacementPreview : null,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('替换预览'),
        ),
      ],
    );
  }
}

class _RegexMatchCard extends StatelessWidget {
  const _RegexMatchCard(this.match);

  final _RegexMatchInfo match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Match ${match.index} · ${match.start}-${match.end}',
                style: const TextStyle(
                  color: Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                match.value,
                style: const TextStyle(
                  color: Color(0xFF23313C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (match.groups.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...match.groups.map(_RegexGroupRow.new),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RegexGroupRow extends StatelessWidget {
  const _RegexGroupRow(this.group);

  final _RegexGroupInfo group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              'Group ${group.index}',
              style: const TextStyle(
                color: Color(0xFF607180),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              group.value ?? 'null',
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

class _ReplacementPreviewCard extends StatelessWidget {
  const _ReplacementPreviewCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '替换预览',
              style: TextStyle(
                color: Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: const TextStyle(
                color: Color(0xFF23313C),
                fontWeight: FontWeight.w700,
              ),
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

class _RegexMatchInfo {
  const _RegexMatchInfo({
    required this.index,
    required this.start,
    required this.end,
    required this.value,
    required this.groups,
  });

  factory _RegexMatchInfo.fromMatch(int index, RegExpMatch match) {
    return _RegexMatchInfo(
      index: index,
      start: match.start,
      end: match.end,
      value: match.group(0) ?? '',
      groups: List<_RegexGroupInfo>.generate(
        match.groupCount,
        (int index) =>
            _RegexGroupInfo(index: index + 1, value: match.group(index + 1)),
      ),
    );
  }

  final int index;
  final int start;
  final int end;
  final String value;
  final List<_RegexGroupInfo> groups;

  String toSummaryText() {
    return [
      'Match: $value',
      'Range: $start-$end',
      ...groups.map(
        (group) => 'Group ${group.index}: ${group.value ?? 'null'}',
      ),
    ].join('\n');
  }
}

class _RegexGroupInfo {
  const _RegexGroupInfo({required this.index, required this.value});

  final int index;
  final String? value;
}
