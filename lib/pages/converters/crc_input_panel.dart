import 'package:flutter/material.dart';

import 'crc_algorithm.dart';
import 'crc_algorithm_selector.dart';
import 'crc_input.dart';

class CrcInputPanel extends StatelessWidget {
  const CrcInputPanel({
    super.key,
    required this.controller,
    required this.mode,
    required this.algorithm,
    required this.onWidthChanged,
    required this.onAlgorithmChanged,
    required this.onModeChanged,
    required this.onInputChanged,
    required this.onCalculate,
    required this.onClear,
  });

  final TextEditingController controller;
  final CrcInputMode mode;
  final CrcAlgorithm algorithm;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<CrcAlgorithm> onAlgorithmChanged;
  final ValueChanged<CrcInputMode> onModeChanged;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onCalculate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<CrcInputMode>(
            segments: const [
              ButtonSegment(value: CrcInputMode.text, label: Text('UTF-8 文本')),
              ButtonSegment(value: CrcInputMode.hex, label: Text('十六进制字节')),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onModeChanged(selection.single),
          ),
        ),
        const SizedBox(height: 16),
        CrcAlgorithmSelector(
          algorithm: algorithm,
          onWidthChanged: onWidthChanged,
          onAlgorithmChanged: onAlgorithmChanged,
        ),
        const SizedBox(height: 16),
        _buildTextField(),
        const SizedBox(height: 12),
        _buildActions(),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: controller,
      onChanged: onInputChanged,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: mode == CrcInputMode.text ? '输入文本' : '输入十六进制字节',
        hintText: mode == CrcInputMode.text
            ? '123456789'
            : '31 32 33 34 35 36 37 38 39',
        helperText: mode == CrcInputMode.text
            ? '按 UTF-8 编码计算，保留空格和换行。'
            : '支持连续字节或用空格、换行分隔，例如 010300000001。',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildActions() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onCalculate,
          icon: const Icon(Icons.calculate_rounded, size: 18),
          label: const Text('计算'),
        ),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('清空'),
        ),
      ],
    );
  }
}
