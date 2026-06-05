import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextDiffPage extends StatefulWidget {
  const TextDiffPage({super.key});

  @override
  State<TextDiffPage> createState() => _TextDiffPageState();
}

class _TextDiffPageState extends State<TextDiffPage> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  List<_DiffLine> _diffLines = const <_DiffLine>[];
  String? _statusText;
  String? _errorText;

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  void _compareText() {
    final leftText = _leftController.text;
    final rightText = _rightController.text;

    if (leftText.isEmpty && rightText.isEmpty) {
      setState(() {
        _diffLines = const <_DiffLine>[];
        _errorText = '请先输入需要对比的文本。';
        _statusText = null;
      });
      return;
    }

    final diffLines = _buildLineDiff(leftText, rightText);
    final changedCount = diffLines
        .where((_DiffLine line) => line.type != _DiffLineType.equal)
        .length;

    setState(() {
      _diffLines = diffLines;
      _statusText = changedCount == 0
          ? '两侧文本完全一致。'
          : '对比完成，发现 $changedCount 行差异。';
      _errorText = null;
    });
  }

  Future<void> _copyDiff() async {
    if (_diffLines.isEmpty) {
      setState(() {
        _errorText = '当前没有可复制的 Diff 结果。';
        _statusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: _formatDiffText(_diffLines)));

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = '已复制 Diff 结果。';
      _errorText = null;
    });
  }

  void _clearAll() {
    setState(() {
      _leftController.clear();
      _rightController.clear();
      _diffLines = const <_DiffLine>[];
      _statusText = null;
      _errorText = null;
    });
  }

  List<_DiffLine> _buildLineDiff(String leftText, String rightText) {
    final leftLines = leftText.split('\n');
    final rightLines = rightText.split('\n');
    final table = List<List<int>>.generate(
      leftLines.length + 1,
      (_) => List<int>.filled(rightLines.length + 1, 0),
    );

    for (var leftIndex = leftLines.length - 1; leftIndex >= 0; leftIndex -= 1) {
      for (
        var rightIndex = rightLines.length - 1;
        rightIndex >= 0;
        rightIndex -= 1
      ) {
        if (leftLines[leftIndex] == rightLines[rightIndex]) {
          table[leftIndex][rightIndex] =
              table[leftIndex + 1][rightIndex + 1] + 1;
          continue;
        }

        table[leftIndex][rightIndex] =
            table[leftIndex + 1][rightIndex] >= table[leftIndex][rightIndex + 1]
            ? table[leftIndex + 1][rightIndex]
            : table[leftIndex][rightIndex + 1];
      }
    }

    return _backtrackDiff(leftLines, rightLines, table);
  }

  List<_DiffLine> _backtrackDiff(
    List<String> leftLines,
    List<String> rightLines,
    List<List<int>> table,
  ) {
    final diffLines = <_DiffLine>[];
    var leftIndex = 0;
    var rightIndex = 0;

    while (leftIndex < leftLines.length && rightIndex < rightLines.length) {
      if (leftLines[leftIndex] == rightLines[rightIndex]) {
        diffLines.add(
          _DiffLine(
            type: _DiffLineType.equal,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: rightIndex + 1,
            text: leftLines[leftIndex],
          ),
        );
        leftIndex += 1;
        rightIndex += 1;
        continue;
      }

      if (table[leftIndex + 1][rightIndex] >=
          table[leftIndex][rightIndex + 1]) {
        diffLines.add(
          _DiffLine(
            type: _DiffLineType.removed,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: null,
            text: leftLines[leftIndex],
          ),
        );
        leftIndex += 1;
        continue;
      }

      diffLines.add(
        _DiffLine(
          type: _DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
          text: rightLines[rightIndex],
        ),
      );
      rightIndex += 1;
    }

    while (leftIndex < leftLines.length) {
      diffLines.add(
        _DiffLine(
          type: _DiffLineType.removed,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: null,
          text: leftLines[leftIndex],
        ),
      );
      leftIndex += 1;
    }

    while (rightIndex < rightLines.length) {
      diffLines.add(
        _DiffLine(
          type: _DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
          text: rightLines[rightIndex],
        ),
      );
      rightIndex += 1;
    }

    return diffLines;
  }

  String _formatDiffText(List<_DiffLine> diffLines) {
    return diffLines
        .map((_DiffLine line) => '${line.type.prefix} ${line.text}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文本Diff',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '对比左右两段文本，查看行级新增、删除和相同内容。',
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
                width: 460,
                child: _DiffInputPanel(
                  leftController: _leftController,
                  rightController: _rightController,
                  statusText: _errorText ?? _statusText,
                  isError: _errorText != null,
                  onCompare: _compareText,
                  onCopyDiff: _copyDiff,
                  onClear: _clearAll,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: _DiffResultPanel(diffLines: _diffLines)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiffInputPanel extends StatelessWidget {
  const _DiffInputPanel({
    required this.leftController,
    required this.rightController,
    required this.statusText,
    required this.isError,
    required this.onCompare,
    required this.onCopyDiff,
    required this.onClear,
  });

  final TextEditingController leftController;
  final TextEditingController rightController;
  final String? statusText;
  final bool isError;
  final VoidCallback onCompare;
  final VoidCallback onCopyDiff;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _DiffTextField(controller: leftController, label: '左侧文本'),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _DiffTextField(controller: rightController, label: '右侧文本'),
            ),
            const SizedBox(height: 14),
            if (statusText != null) ...[
              _StatusBanner(message: statusText!, isError: isError),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCompare,
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: const Text('对比'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onCopyDiff,
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('复制Diff'),
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
  }
}

class _DiffTextField extends StatelessWidget {
  const _DiffTextField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DiffResultPanel extends StatelessWidget {
  const _DiffResultPanel({required this.diffLines});

  final List<_DiffLine> diffLines;

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
              'Diff结果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: diffLines.isEmpty
                  ? const Center(child: _MutedText('对比结果会显示在这里。'))
                  : ListView.separated(
                      itemCount: diffLines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        return _DiffLineTile(line: diffLines[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffLineTile extends StatelessWidget {
  const _DiffLineTile({required this.line});

  final _DiffLine line;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: line.type.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line.type.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                line.type.prefix,
                style: TextStyle(
                  color: line.type.foregroundColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 86,
              child: Text(
                line.lineLabel,
                style: const TextStyle(
                  color: Color(0xFF607180),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                line.text,
                style: const TextStyle(
                  color: Color(0xFF23313C),
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

class _DiffLine {
  const _DiffLine({
    required this.type,
    required this.leftLineNumber,
    required this.rightLineNumber,
    required this.text,
  });

  final _DiffLineType type;
  final int? leftLineNumber;
  final int? rightLineNumber;
  final String text;

  String get lineLabel {
    final left = leftLineNumber?.toString() ?? '-';
    final right = rightLineNumber?.toString() ?? '-';
    return '$left / $right';
  }
}

enum _DiffLineType {
  equal(' ', Color(0xFFFFFFFF), Color(0xFFD8E2E8), Color(0xFF607180)),
  added('+', Color(0xFFEAF7F6), Color(0xFFD1E8E4), Color(0xFF0F766E)),
  removed('-', Color(0xFFFFEEF2), Color(0xFFFFCCD5), Color(0xFF9F1239));

  const _DiffLineType(
    this.prefix,
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
  );

  final String prefix;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}
