abstract final class SafeFileName {
  static const int maxLength = 80;

  static const Set<String> _windowsReservedNames = <String>{
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  static String fromTitle(
    String value, {
    String fallback = 'untitled-note',
  }) {
    String cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    cleaned = _trimTrailingDotsAndSpaces(cleaned);

    if (cleaned.isEmpty) return fallback;
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
      cleaned = _trimTrailingDotsAndSpaces(cleaned);
    }
    if (cleaned.isEmpty) return fallback;

    final String firstSegment = cleaned.split('.').first.toUpperCase();
    if (_windowsReservedNames.contains(firstSegment)) {
      cleaned = '_$cleaned';
      if (cleaned.length > maxLength) {
        cleaned = cleaned.substring(0, maxLength);
        cleaned = _trimTrailingDotsAndSpaces(cleaned);
      }
    }

    return cleaned.isEmpty ? fallback : cleaned;
  }

  static String _trimTrailingDotsAndSpaces(String value) {
    return value.replaceFirst(RegExp(r'[. ]+$'), '');
  }
}
