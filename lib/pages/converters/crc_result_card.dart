import 'package:flutter/material.dart';

import 'crc_algorithm.dart';

class CrcResultCard extends StatelessWidget {
  const CrcResultCard({super.key, required this.result, required this.onCopy});

  final CrcResult result;
  final void Function(String value, String label) onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD8E2E8)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              result.algorithm.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            _buildValue('校验值', result.hex),
            if (result.algorithm.width == 16) ...[
              _buildValue('高字节在前', result.highByteFirst),
              _buildValue('低字节在前', result.lowByteFirst),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValue(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: '复制 ${result.algorithm.name} $label',
          onPressed: () => onCopy(value, '${result.algorithm.name} $label'),
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }
}
