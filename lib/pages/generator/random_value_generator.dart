import 'dart:math';

class RandomValueGenerator {
  RandomValueGenerator({Random? random}) : _random = random ?? Random.secure();

  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String digitChars = '0123456789';
  static const String symbolChars = r'!@#$%^&*_-+=';

  final Random _random;

  List<String> generateUuids(int count) {
    return List<String>.generate(count, (_) => generateUuidV4());
  }

  List<String> generateStrings({
    required int count,
    required int length,
    required RandomCharacterOptions options,
  }) {
    final pool = buildCharacterPool(options);

    if (pool.isEmpty) {
      throw const FormatException('请至少选择一种字符类型。');
    }

    return List<String>.generate(
      count,
      (_) => _buildRandomString(pool, length),
    );
  }

  String generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String buildCharacterPool(RandomCharacterOptions options) {
    return [
      if (options.includeLowercase) lowercaseChars,
      if (options.includeUppercase) uppercaseChars,
      if (options.includeDigits) digitChars,
      if (options.includeSymbols) symbolChars,
    ].join();
  }

  String _buildRandomString(String pool, int length) {
    return List<String>.generate(
      length,
      (_) => pool[_random.nextInt(pool.length)],
    ).join();
  }
}

class RandomCharacterOptions {
  const RandomCharacterOptions({
    required this.includeLowercase,
    required this.includeUppercase,
    required this.includeDigits,
    required this.includeSymbols,
  });

  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeDigits;
  final bool includeSymbols;
}
