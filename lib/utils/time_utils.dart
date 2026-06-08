String formatTimeOfDay(DateTime value) {
  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:'
      '${_twoDigits(value.second)}';
}

String formatCompactTimestamp(DateTime value) {
  return '${_fourDigits(value.year)}${_twoDigits(value.month)}'
      '${_twoDigits(value.day)}${_twoDigits(value.hour)}'
      '${_twoDigits(value.minute)}${_twoDigits(value.second)}';
}

String formatDateTimeSecond(DateTime value) {
  return '${_formatDate(value)} ${formatTimeOfDay(value)}';
}

String formatDateTimeMinute(DateTime value) {
  return '${_formatDate(value)} ${_twoDigits(value.hour)}:'
      '${_twoDigits(value.minute)}';
}

String formatDateTimeMillisecond(DateTime value) {
  return '${formatDateTimeSecond(value)}.${_threeDigits(value.millisecond)}';
}

String _formatDate(DateTime value) {
  return '${_fourDigits(value.year)}-${_twoDigits(value.month)}-'
      '${_twoDigits(value.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _threeDigits(int value) => value.toString().padLeft(3, '0');

String _fourDigits(int value) => value.toString().padLeft(4, '0');
