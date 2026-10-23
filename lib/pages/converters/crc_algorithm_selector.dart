import 'package:flutter/material.dart';

import 'crc_algorithm.dart';

class CrcAlgorithmSelector extends StatelessWidget {
  const CrcAlgorithmSelector({
    super.key,
    required this.algorithm,
    required this.onWidthChanged,
    required this.onAlgorithmChanged,
  });

  final CrcAlgorithm algorithm;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<CrcAlgorithm> onAlgorithmChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildWidthSelector()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildAlgorithmSelector()),
      ],
    );
  }

  Widget _buildWidthSelector() {
    return _decorate(
      'CRC 类型',
      DropdownButton<int>(
        value: algorithm.width,
        isExpanded: true,
        isDense: true,
        items: const [
          DropdownMenuItem(value: 8, child: Text('CRC8')),
          DropdownMenuItem(value: 16, child: Text('CRC16')),
        ],
        onChanged: (value) {
          if (value != null && value != algorithm.width) onWidthChanged(value);
        },
      ),
    );
  }

  Widget _buildAlgorithmSelector() {
    return _decorate(
      '算法类型',
      DropdownButton<CrcAlgorithm>(
        value: algorithm,
        isExpanded: true,
        isDense: true,
        items: [
          for (final preset in crcAlgorithms)
            if (preset.width == algorithm.width)
              DropdownMenuItem(
                value: preset,
                child: Text(_algorithmLabel(preset)),
              ),
        ],
        onChanged: (value) {
          if (value != null) onAlgorithmChanged(value);
        },
      ),
    );
  }

  String _algorithmLabel(CrcAlgorithm preset) {
    return preset.name == 'CRC8 (SMBUS)'
        ? 'SMBUS'
        : preset.name.split('/').last;
  }

  Widget _decorate(String label, Widget child) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
