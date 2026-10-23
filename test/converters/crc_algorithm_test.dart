import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/converters/crc_algorithm.dart';
import 'package:mytools/pages/converters/crc_input.dart';

void main() {
  // CRC RevEng catalogue "check" values for ASCII 123456789.
  const checks = {
    'CRC16/MODBUS': 0x4B37,
    'CRC16/ARC (IBM)': 0xBB3D,
    'CRC16/CCITT-FALSE': 0x29B1,
    'CRC16/XMODEM': 0x31C3,
    'CRC16/KERMIT': 0x2189,
    'CRC16/X-25': 0x906E,
    'CRC8 (SMBUS)': 0xF4,
    'CRC8/MAXIM': 0xA1,
    'CRC8/ROHC': 0xD0,
  };
  for (final algorithm in crcAlgorithms) {
    test('${algorithm.name} matches catalogue check', () {
      expect(
        algorithm.calculate(ascii.encode('123456789')),
        checks[algorithm.name],
      );
    });
  }

  test('MODBUS request has expected CRC and byte order', () {
    final algorithm = crcAlgorithms.first;
    final result = CrcResult(
      algorithm,
      algorithm.calculate([1, 3, 0, 0, 0, 1]),
    );
    expect(result.hex, '0A84');
    expect(result.highByteFirst, '0A 84');
    expect(result.lowByteFirst, '84 0A');
  });

  test('zero values keep the full CRC width', () {
    expect(CrcResult(crcAlgorithms[1], 0).hex, '0000');
    expect(CrcResult(crcAlgorithms[6], 0).hex, '00');
  });

  test('empty bytes follow initialization and final xor', () {
    for (final algorithm in crcAlgorithms) {
      expect(algorithm.calculate([]), algorithm.initial ^ algorithm.xorOut);
    }
  });

  test('UTF-8 parsing preserves non ASCII, whitespace and newlines', () {
    expect(parseCrcInput(' 中文\n', CrcInputMode.text), utf8.encode(' 中文\n'));
  });

  test('hex parsing supports contiguous, grouped and lowercase input', () {
    expect(parseCrcInput(' 01aB\n00\tFF10 ', CrcInputMode.hex), [
      1,
      171,
      0,
      255,
      16,
    ]);
    final text = parseCrcInput('123456789', CrcInputMode.text);
    final hex = parseCrcInput('313233343536373839', CrcInputMode.hex);
    for (final algorithm in crcAlgorithms) {
      expect(algorithm.calculate(text), algorithm.calculate(hex));
    }
  });

  for (final input in ['', '   ', 'GG', '0x12', '123', 'A B', '01,02']) {
    test('rejects invalid hex input "$input"', () {
      expect(
        () => parseCrcInput(input, CrcInputMode.hex),
        throwsFormatException,
      );
    });
  }

  test('rejects empty text and out of range bytes', () {
    expect(() => parseCrcInput('', CrcInputMode.text), throwsFormatException);
    expect(() => crcAlgorithms.first.calculate([256]), throwsRangeError);
    expect(() => crcAlgorithms.first.calculate([-1]), throwsRangeError);
  });
}
