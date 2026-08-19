abstract final class MarkdownLite {
  static String toggleChecklist(String line, {required bool checked}) {
    final String normalized = line.replaceFirst(
      RegExp(r'^\s*[-*]\s+\[[ xX]\]\s*'),
      '',
    );
    return '- [${checked ? 'x' : ' '}] $normalized';
  }

  static String togglePrefix(String line, String prefix) {
    final String trimmedLeft = line.trimLeft();
    if (trimmedLeft.startsWith(prefix)) {
      final int offset = line.length - trimmedLeft.length;
      return '${line.substring(0, offset)}${trimmedLeft.substring(prefix.length)}';
    }
    return '$prefix$line';
  }

  static String plainPreview(String markdown, {int maxLength = 220}) {
    final String text = markdown
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+\[[ xX]\]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'[*_`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength).trimRight()}…';
  }
}
