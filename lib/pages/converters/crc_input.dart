import 'dart:convert';

enum CrcInputMode { text, hex }

List<int> parseCrcInput(String input, CrcInputMode mode) {
  if (input.isEmpty) {
    throw const FormatException('请先输入需要计算 CRC 的内容。');
  }
  if (mode == CrcInputMode.text) {
    return utf8.encode(input);
  }
  if (input.trim().isEmpty) {
    throw const FormatException('请先输入十六进制字节。');
  }
  final groups = input.trim().split(RegExp(r'\s+'));
  final bytes = <int>[];
  for (final group in groups) {
    bytes.addAll(_parseHexGroup(group));
  }
  return bytes;
}

List<int> _parseHexGroup(String group) {
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(group)) {
    throw const FormatException('十六进制只能包含 0-9、A-F，可用空格或换行分隔。');
  }
  if (group.length.isOdd) {
    throw const FormatException('十六进制每组必须包含完整字节（每个字节 2 位）。');
  }
  return [
    for (var offset = 0; offset < group.length; offset += 2)
      int.parse(group.substring(offset, offset + 2), radix: 16),
  ];
}
