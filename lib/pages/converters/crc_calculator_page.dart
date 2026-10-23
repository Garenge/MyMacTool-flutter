import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crc_algorithm.dart';
import 'crc_input.dart';
import 'crc_input_panel.dart';
import 'crc_result_card.dart';

class CrcCalculatorPage extends StatefulWidget {
  const CrcCalculatorPage({super.key});

  @override
  State<CrcCalculatorPage> createState() => _CrcCalculatorPageState();
}

class _CrcCalculatorPageState extends State<CrcCalculatorPage> {
  final _controller = TextEditingController();
  CrcInputMode _mode = CrcInputMode.text;
  CrcAlgorithm _algorithm = crcAlgorithms.first;
  CrcResult? _result;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final bytes = parseCrcInput(_controller.text, _mode);
      setState(() {
        _result = CrcResult(_algorithm, _algorithm.calculate(bytes));
        _message = 'CRC 计算完成，共 ${bytes.length} 字节。';
        _isError = false;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _message = error.message;
        _isError = true;
      });
    }
  }

  void _resetResults() {
    setState(() {
      _result = null;
      _message = null;
      _isError = false;
    });
  }

  void _changeMode(CrcInputMode mode) {
    _mode = mode;
    _resetResults();
  }

  void _changeAlgorithm(CrcAlgorithm algorithm) {
    final shouldCalculate = _result != null;
    setState(() => _algorithm = algorithm);
    if (shouldCalculate) {
      _calculate();
    }
  }

  void _changeWidth(int width) {
    _changeAlgorithm(
      crcAlgorithms.firstWhere((algorithm) => algorithm.width == width),
    );
  }

  void _clear() {
    _controller.clear();
    _resetResults();
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复制 $label。')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CRC校验',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF23313C),
            ),
          ),
          const SizedBox(height: 8),
          const Text('支持 6 种 CRC16 和 3 种 CRC8，适合通信报文与数据校验。'),
          const SizedBox(height: 20),
          _buildWorkspace(),
        ],
      ),
    );
  }

  Widget _buildWorkspace() {
    return DecoratedBox(
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
            CrcInputPanel(
              controller: _controller,
              mode: _mode,
              algorithm: _algorithm,
              onWidthChanged: _changeWidth,
              onAlgorithmChanged: _changeAlgorithm,
              onModeChanged: _changeMode,
              onInputChanged: (_) => _resetResults(),
              onCalculate: _calculate,
              onClear: _clear,
            ),
            const SizedBox(height: 16),
            if (_message != null) _buildMessage(),
            if (_result == null && _message == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('选择算法并输入内容后点击计算，这里会显示所选算法的 CRC 校验值。'),
              ),
            if (_result case final result?)
              CrcResultCard(result: result, onCopy: _copy),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        _message!,
        style: TextStyle(
          color: _isError ? const Color(0xFF9F1239) : const Color(0xFF0F766E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
