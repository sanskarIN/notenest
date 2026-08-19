import 'dart:convert';
import 'dart:developer' as developer;

enum AppLogLevel { debug, info, warning, error }

final class AppLogger {
  const AppLogger({this.name = 'NoteNest'});

  final String name;

  static const Set<String> _sensitiveKeyFragments = <String>{
    'authorization',
    'backup',
    'body',
    'content',
    'credential',
    'email',
    'file',
    'message',
    'note',
    'password',
    'path',
    'secret',
    'text',
    'title',
    'token',
  };

  void debug(
    String event, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _write(AppLogLevel.debug, event, fields);
  }

  void info(
    String event, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _write(AppLogLevel.info, event, fields);
  }

  void warning(
    String event, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _write(AppLogLevel.warning, event, fields);
  }

  void error(
    String event, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    _write(AppLogLevel.error, event, fields);
  }

  Map<String, Object?> sanitizeFields(Map<String, Object?> fields) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in fields.entries)
        entry.key: _sanitizeValue(entry.key, entry.value),
    };
  }

  void _write(
    AppLogLevel level,
    String event,
    Map<String, Object?> fields,
  ) {
    final Map<String, Object?> record = <String, Object?>{
      'event': _safeEventName(event),
      'severity': level.name,
      if (fields.isNotEmpty) 'fields': sanitizeFields(fields),
    };
    developer.log(
      jsonEncode(record),
      name: name,
      level: _developerLevel(level),
    );
  }

  Object? _sanitizeValue(String key, Object? value) {
    final String normalizedKey = key.toLowerCase();
    if (_sensitiveKeyFragments.any(normalizedKey.contains)) {
      return '[redacted]';
    }
    if (value == null || value is bool || value is num) {
      return value;
    }
    if (value is Enum) {
      return value.name;
    }
    if (value is String) {
      final String compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      return compact.length <= 120 ? compact : '${compact.substring(0, 120)}…';
    }
    return value.runtimeType.toString();
  }

  String _safeEventName(String value) {
    final String normalized = value
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9._-]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'unknown_event' : normalized;
  }

  int _developerLevel(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.debug => 500,
      AppLogLevel.info => 800,
      AppLogLevel.warning => 900,
      AppLogLevel.error => 1000,
    };
  }
}
