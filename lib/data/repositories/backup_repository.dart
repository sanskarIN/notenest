import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/data/database/app_database.dart';

final class RestoreReport {
  const RestoreReport({
    required this.importedNotes,
    required this.skippedNewerNotes,
    required this.importedVersions,
  });

  final int importedNotes;
  final int skippedNewerNotes;
  final int importedVersions;
}

final class BackupRepository {
  BackupRepository(this._db);

  static const int backupSchemaVersion = 1;
  final AppDatabase _db;

  Future<String> exportJson() async {
    final List<Note> notes = await _db.select(_db.notes).get();
    final List<NoteVersion> versions = await _db.select(_db.noteVersions).get();
    final Map<String, Object?> payload = <String, Object?>{
      'app': 'NoteNest',
      'schemaVersion': backupSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'notes': notes.map(_noteToJson).toList(growable: false),
      'versions': versions.map(_versionToJson).toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<RestoreReport> restoreJson(String raw) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw ValidationException('Backup is not valid JSON.', error);
    }
    if (decoded is! Map<String, Object?>) {
      throw const ValidationException('Backup root must be a JSON object.');
    }
    if (decoded['app'] != 'NoteNest') {
      throw const ValidationException('Backup does not identify as NoteNest data.');
    }
    if (decoded['schemaVersion'] != backupSchemaVersion) {
      throw const ValidationException('Unsupported backup schema version.');
    }

    final Object? rawNotes = decoded['notes'];
    final Object? rawVersions = decoded['versions'];
    if (rawNotes is! List<Object?> || rawVersions is! List<Object?>) {
      throw const ValidationException('Backup notes or versions are malformed.');
    }

    final List<NotesCompanion> notes = rawNotes
        .map(_parseNote)
        .toList(growable: false);
    final List<NoteVersionsCompanion> versions = rawVersions
        .map(_parseVersion)
        .toList(growable: false);

    int importedNotes = 0;
    int skippedNewerNotes = 0;
    int importedVersions = 0;

    await _db.transaction(() async {
      for (final NotesCompanion incoming in notes) {
        final String id = incoming.id.value;
        final List<Note> existing = await (_db.select(_db.notes)
              ..where((Notes row) => row.id.equals(id)))
            .get();
        if (existing.isNotEmpty &&
            existing.single.updatedAt.isAfter(incoming.updatedAt.value)) {
          skippedNewerNotes += 1;
          continue;
        }
        await _db.into(_db.notes).insertOnConflictUpdate(incoming);
        importedNotes += 1;
      }

      for (final NoteVersionsCompanion incoming in versions) {
        final List<NoteVersion> duplicate = await (_db.select(_db.noteVersions)
              ..where(
                (NoteVersions row) =>
                    row.noteId.equals(incoming.noteId.value) &
                    row.capturedAt.equals(incoming.capturedAt.value),
              ))
            .get();
        if (duplicate.isEmpty) {
          await _db.into(_db.noteVersions).insert(incoming);
          importedVersions += 1;
        }
      }
    });

    return RestoreReport(
      importedNotes: importedNotes,
      skippedNewerNotes: skippedNewerNotes,
      importedVersions: importedVersions,
    );
  }

  Map<String, Object?> _noteToJson(Note note) => <String, Object?>{
        'id': note.id,
        'title': note.title,
        'body': note.body,
        'folder': note.folder,
        'tags': note.tags,
        'colorValue': note.colorValue,
        'isPinned': note.isPinned,
        'isFavorite': note.isFavorite,
        'isArchived': note.isArchived,
        'isTrashed': note.isTrashed,
        'createdAt': note.createdAt.toUtc().toIso8601String(),
        'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      };

  Map<String, Object?> _versionToJson(NoteVersion version) => <String, Object?>{
        'noteId': version.noteId,
        'title': version.title,
        'body': version.body,
        'folder': version.folder,
        'tags': version.tags,
        'colorValue': version.colorValue,
        'isPinned': version.isPinned,
        'isFavorite': version.isFavorite,
        'isArchived': version.isArchived,
        'isTrashed': version.isTrashed,
        'capturedAt': version.capturedAt.toUtc().toIso8601String(),
      };

  NotesCompanion _parseNote(Object? raw) {
    final Map<String, Object?> map = _map(raw, 'note');
    return NotesCompanion(
      id: Value<String>(_string(map, 'id')),
      title: Value<String>(_string(map, 'title')),
      body: Value<String>(_string(map, 'body')),
      folder: Value<String>(_string(map, 'folder')),
      tags: Value<String>(_string(map, 'tags')),
      colorValue: Value<int?>(_nullableInt(map, 'colorValue')),
      isPinned: Value<bool>(_bool(map, 'isPinned')),
      isFavorite: Value<bool>(_bool(map, 'isFavorite')),
      isArchived: Value<bool>(_bool(map, 'isArchived')),
      isTrashed: Value<bool>(_bool(map, 'isTrashed')),
      createdAt: Value<DateTime>(_date(map, 'createdAt')),
      updatedAt: Value<DateTime>(_date(map, 'updatedAt')),
    );
  }

  NoteVersionsCompanion _parseVersion(Object? raw) {
    final Map<String, Object?> map = _map(raw, 'version');
    return NoteVersionsCompanion(
      noteId: Value<String>(_string(map, 'noteId')),
      title: Value<String>(_string(map, 'title')),
      body: Value<String>(_string(map, 'body')),
      folder: Value<String>(_string(map, 'folder')),
      tags: Value<String>(_string(map, 'tags')),
      colorValue: Value<int?>(_nullableInt(map, 'colorValue')),
      isPinned: Value<bool>(_bool(map, 'isPinned')),
      isFavorite: Value<bool>(_bool(map, 'isFavorite')),
      isArchived: Value<bool>(_bool(map, 'isArchived')),
      isTrashed: Value<bool>(_bool(map, 'isTrashed')),
      capturedAt: Value<DateTime>(_date(map, 'capturedAt')),
    );
  }

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map<String, Object?>) return value;
    throw ValidationException('Backup $label entry is malformed.');
  }

  String _string(Map<String, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String) return value;
    throw ValidationException('Backup field "$key" must be text.');
  }

  bool _bool(Map<String, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) return value;
    throw ValidationException('Backup field "$key" must be true or false.');
  }

  int? _nullableInt(Map<String, Object?> map, String key) {
    final Object? value = map[key];
    if (value == null || value is int) return value as int?;
    throw ValidationException('Backup field "$key" must be an integer or null.');
  }

  DateTime _date(Map<String, Object?> map, String key) {
    final String value = _string(map, key);
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw ValidationException('Backup field "$key" is not a valid date.');
    }
    return parsed.toUtc();
  }
}
