import 'dart:convert';

import 'package:notenest/core/errors/app_exception.dart';

final class MarkdownDocument {
  const MarkdownDocument({
    required this.title,
    required this.body,
    required this.folder,
    required this.tags,
    this.updatedAt,
    this.hasNoteNestMetadata = false,
  });

  final String title;
  final String body;
  final String folder;
  final List<String> tags;
  final DateTime? updatedAt;
  final bool hasNoteNestMetadata;
}

abstract final class MarkdownDocumentCodec {
  static const int schemaVersion = 1;

  static String encode({
    required String title,
    required String body,
    required String folder,
    required Iterable<String> tags,
    required DateTime updatedAt,
  }) {
    final List<String> normalizedTags =
        tags
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final List<String> lines = <String>[
      '---',
      'notenest: $schemaVersion',
      'title: ${jsonEncode(title)}',
      'folder: ${jsonEncode(folder)}',
      'tags: ${jsonEncode(normalizedTags)}',
      'updatedAt: ${jsonEncode(updatedAt.toUtc().toIso8601String())}',
      '---',
      '',
      body,
    ];
    return lines.join('\n');
  }

  static MarkdownDocument decode(String raw, {required String fallbackTitle}) {
    final String normalized = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    if (!normalized.startsWith('---\n')) {
      return MarkdownDocument(
        title: fallbackTitle,
        body: normalized,
        folder: '',
        tags: const <String>[],
      );
    }

    final int closingMarker = normalized.indexOf('\n---\n', 4);
    if (closingMarker == -1) {
      return MarkdownDocument(
        title: fallbackTitle,
        body: normalized,
        folder: '',
        tags: const <String>[],
      );
    }

    final String metadataBlock = normalized.substring(4, closingMarker);
    final Map<String, String> metadata = <String, String>{};
    for (final String line in metadataBlock.split('\n')) {
      final int separator = line.indexOf(':');
      if (separator <= 0) continue;
      final String key = line.substring(0, separator).trim();
      final String value = line.substring(separator + 1).trim();
      if (key.isNotEmpty) metadata[key] = value;
    }

    final String? rawSchema = metadata['notenest'];
    if (rawSchema == null) {
      return MarkdownDocument(
        title: fallbackTitle,
        body: normalized,
        folder: '',
        tags: const <String>[],
      );
    }

    final Object? schema = _decodeJsonField(rawSchema, 'notenest');
    if (schema != schemaVersion) {
      throw const ValidationException(
        'Unsupported NoteNest Markdown metadata version.',
      );
    }

    final String title = _decodeOptionalString(
      metadata['title'],
      field: 'title',
      fallback: fallbackTitle,
    );
    final String folder = _decodeOptionalString(
      metadata['folder'],
      field: 'folder',
      fallback: '',
    );
    final List<String> tags = _decodeTags(metadata['tags']);
    final DateTime? updatedAt = _decodeOptionalDate(metadata['updatedAt']);
    int bodyStart = closingMarker + '\n---\n'.length;
    if (normalized.startsWith('\n', bodyStart)) {
      bodyStart += 1;
    }
    final String body = normalized.substring(bodyStart);

    return MarkdownDocument(
      title: title,
      body: body,
      folder: folder,
      tags: tags,
      updatedAt: updatedAt,
      hasNoteNestMetadata: true,
    );
  }

  static Object? _decodeJsonField(String raw, String field) {
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      throw ValidationException(
        'Invalid NoteNest Markdown metadata field "$field".',
        error,
      );
    }
  }

  static String _decodeOptionalString(
    String? raw, {
    required String field,
    required String fallback,
  }) {
    if (raw == null) return fallback;
    final Object? value = _decodeJsonField(raw, field);
    if (value is! String) {
      throw ValidationException(
        'NoteNest Markdown metadata field "$field" must be text.',
      );
    }
    return value;
  }

  static List<String> _decodeTags(String? raw) {
    if (raw == null) return const <String>[];
    final Object? value = _decodeJsonField(raw, 'tags');
    if (value is! List<Object?>) {
      throw const ValidationException(
        'NoteNest Markdown metadata field "tags" must be a list.',
      );
    }
    final List<String> tags = <String>[];
    for (final Object? item in value) {
      if (item is! String) {
        throw const ValidationException(
          'Every NoteNest Markdown tag must be text.',
        );
      }
      final String normalized = item.trim();
      if (normalized.isNotEmpty && !tags.contains(normalized)) {
        tags.add(normalized);
      }
    }
    return tags;
  }

  static DateTime? _decodeOptionalDate(String? raw) {
    if (raw == null) return null;
    final Object? value = _decodeJsonField(raw, 'updatedAt');
    if (value is! String) {
      throw const ValidationException(
        'NoteNest Markdown metadata field "updatedAt" must be text.',
      );
    }
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const ValidationException(
        'NoteNest Markdown metadata field "updatedAt" is not a valid date.',
      );
    }
    return parsed.toUtc();
  }
}
