import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/utils/time_utils.dart';

void main() {
  test('formats time and date time values with stable padding', () {
    final value = DateTime(2026, 6, 7, 9, 8, 5, 42);

    expect(formatTimeOfDay(value), '09:08:05');
    expect(formatCompactTimestamp(value), '20260607090805');
    expect(formatDateTimeSecond(value), '2026-06-07 09:08:05');
    expect(formatDateTimeMinute(value), '2026-06-07 09:08');
    expect(formatDateTimeMillisecond(value), '2026-06-07 09:08:05.042');
  });

  test('pads short years for file-name friendly timestamps', () {
    final value = DateTime(9, 1, 2, 3, 4, 5, 6);

    expect(formatCompactTimestamp(value), '00090102030405');
    expect(formatDateTimeMillisecond(value), '0009-01-02 03:04:05.006');
  });
}
