/// Parameters and aliases follow https://reveng.sourceforge.io/crc-catalogue/all.htm.
/// All presets have identical input/output reflection flags.
class CrcAlgorithm {
  const CrcAlgorithm(
    this.name,
    this.width,
    this.polynomial,
    this.initial,
    this.reflected, [
    this.xorOut = 0,
  ]);

  final String name;
  final int width;
  final int polynomial;
  final int initial;
  final bool reflected;
  final int xorOut;

  int calculate(List<int> bytes) {
    final mask = (1 << width) - 1;
    final topBit = 1 << (width - 1);
    var crc = initial;
    for (final byte in bytes) {
      RangeError.checkValueInInterval(byte, 0, 255, 'byte');
      final input = reflected ? _reflect(byte, 8) : byte;
      crc ^= input << (width - 8);
      crc = _advanceByte(crc, topBit, mask);
    }
    if (reflected) {
      crc = _reflect(crc, width);
    }
    return (crc ^ xorOut) & mask;
  }

  int _advanceByte(int crc, int topBit, int mask) {
    for (var bit = 0; bit < 8; bit++) {
      crc = ((crc & topBit) != 0 ? (crc << 1) ^ polynomial : crc << 1) & mask;
    }
    return crc;
  }

  int _reflect(int value, int bits) {
    var reflected = 0;
    for (var bit = 0; bit < bits; bit++) {
      reflected = (reflected << 1) | ((value >> bit) & 1);
    }
    return reflected;
  }
}

const crcAlgorithms = [
  CrcAlgorithm('CRC16/MODBUS', 16, 0x8005, 0xFFFF, true),
  CrcAlgorithm('CRC16/ARC (IBM)', 16, 0x8005, 0, true),
  CrcAlgorithm('CRC16/CCITT-FALSE', 16, 0x1021, 0xFFFF, false),
  CrcAlgorithm('CRC16/XMODEM', 16, 0x1021, 0, false),
  CrcAlgorithm('CRC16/KERMIT', 16, 0x1021, 0, true),
  CrcAlgorithm('CRC16/X-25', 16, 0x1021, 0xFFFF, true, 0xFFFF),
  CrcAlgorithm('CRC8 (SMBUS)', 8, 0x07, 0, false),
  CrcAlgorithm('CRC8/MAXIM', 8, 0x31, 0, true),
  CrcAlgorithm('CRC8/ROHC', 8, 0x07, 0xFF, true),
];

class CrcResult {
  const CrcResult(this.algorithm, this.value);

  final CrcAlgorithm algorithm;
  final int value;

  String get hex =>
      value.toRadixString(16).padLeft(algorithm.width ~/ 4, '0').toUpperCase();

  String get highByteFirst => '${hex.substring(0, 2)} ${hex.substring(2)}';
  String get lowByteFirst => '${hex.substring(2)} ${hex.substring(0, 2)}';
}
