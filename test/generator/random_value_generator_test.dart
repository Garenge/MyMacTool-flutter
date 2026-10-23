import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/generator/random_value_generator.dart';

void main() {
  test('generates RFC 4122 style uuid v4 values', () {
    final generator = RandomValueGenerator(random: Random(1));
    final uuid = generator.generateUuidV4();

    expect(
      uuid,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('builds character pools from selected options', () {
    final generator = RandomValueGenerator(random: Random(1));

    expect(
      generator.buildCharacterPool(
        const RandomCharacterOptions(
          includeLowercase: true,
          includeUppercase: false,
          includeDigits: true,
          includeSymbols: false,
        ),
      ),
      '${RandomValueGenerator.lowercaseChars}'
      '${RandomValueGenerator.digitChars}',
    );
  });

  test('generates random strings with requested count and length', () {
    final generator = RandomValueGenerator(random: Random(1));
    final results = generator.generateStrings(
      count: 3,
      length: 8,
      options: const RandomCharacterOptions(
        includeLowercase: false,
        includeUppercase: false,
        includeDigits: true,
        includeSymbols: false,
      ),
    );

    expect(results, hasLength(3));
    expect(results, everyElement(matches(RegExp(r'^\d{8}$'))));
  });

  test('rejects empty random string character pool', () {
    final generator = RandomValueGenerator(random: Random(1));

    expect(
      () => generator.generateStrings(
        count: 1,
        length: 8,
        options: const RandomCharacterOptions(
          includeLowercase: false,
          includeUppercase: false,
          includeDigits: false,
          includeSymbols: false,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          '请至少选择一种字符类型。',
        ),
      ),
    );
  });
}
