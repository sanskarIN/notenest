import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/domain/models/note_filter.dart';
import 'package:uuid/uuid.dart';

final class NoteRepository {
  NoteRepository(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  Future<Note> create({
    String title = '',
    String body = '',
    String folder = '',
    Iterable<String> tags = const <String>[],
    int? colorValue,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String id = _uuid.v7();
    await _db.into(_db.notes).insert(
          NotesCompanion(
            id: Value<String>(id),
            title: Value<String>(title.trim()),
            body: Value<String>(body),
            folder: Value<String>(folder.trim()),
            tags: Value<String>(_encodeTags(tags)),
            colorValue: Value<int?>(colorValue),
            createdAt: Value<DateTime>(now),
            updatedAt: Value<DateTime>(now),
          ),
        );
    return getById(id);
  }

  Future<Note> getById(String id) {
    return (_db.select(_db.notes)..where((Notes row) => row.id.equals(id)))
        .getSingle();
  }

  Future<List<Note>> list(NoteFilter filter) async {
    final List<Note> source = filter.query.trim().isEmpty
        ? await _db.select(_db.notes).get()
        : await _db.searchFts(filter.query);

    final List<Note> filtered = source.where((Note note) {
      final bool collectionMatches = switch (filter.collection) {
        NoteCollection.all => !note.isTrashed && !note.isArchived,
        NoteCollection.favorites =>
          !note.isTrashed && !note.isArchived && note.isFavorite,
        NoteCollection.archive => !note.isTrashed && note.isArchived,
        NoteCollection.trash => note.isTrashed,
      };
      if (!collectionMatches) {
        return false;
      }
      if (filter.folder != null && note.folder != filter.folder) {
        return false;
      }
      if (filter.tag != null && !decodeTags(note.tags).contains(filter.tag)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final List<Note> sorted = List<Note>.of(filtered)
      ..sort((Note a, Note b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return sorted;
  }

  Future<void> saveContent({
    required String id,
    required String title,
    required String body,
    required String folder,
    required Iterable<String> tags,
    required int? colorValue,
  }) async {
    final Note existing = await getById(id);
    final String encodedTags = _encodeTags(tags);
    final String normalizedTitle = title.trim();
    final String normalizedFolder = folder.trim();

    final bool unchanged = existing.title == normalizedTitle &&
        existing.body == body &&
        existing.folder == normalizedFolder &&
        existing.tags == encodedTags &&
        existing.colorValue == colorValue;
    if (unchanged) {
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.noteVersions).insert(
            NoteVersionsCompanion(
              noteId: Value<String>(existing.id),
              title: Value<String>(existing.title),
              body: Value<String>(existing.body),
              folder: Value<String>(existing.folder),
              tags: Value<String>(existing.tags),
              colorValue: Value<int?>(existing.colorValue),
              isPinned: Value<bool>(existing.isPinned),
              isFavorite: Value<bool>(existing.isFavorite),
              isArchived: Value<bool>(existing.isArchived),
              isTrashed: Value<bool>(existing.isTrashed),
              capturedAt: Value<DateTime>(now),
            ),
          );
      await (_db.update(_db.notes)..where((Notes row) => row.id.equals(id)))
          .write(
        NotesCompanion(
          title: Value<String>(normalizedTitle),
          body: Value<String>(body),
          folder: Value<String>(normalizedFolder),
          tags: Value<String>(encodedTags),
          colorValue: Value<int?>(colorValue),
          updatedAt: Value<DateTime>(now),
        ),
      );
    });
  }

  Future<List<NoteVersion>> versions(String noteId) {
    final SimpleSelectStatement<$NoteVersionsTable, NoteVersion> query =
        _db.select(_db.noteVersions)
          ..where((NoteVersions row) => row.noteId.equals(noteId))
          ..orderBy(<OrderingTerm Function(NoteVersions)>[
            (NoteVersions row) => OrderingTerm.desc(row.capturedAt),
          ]);
    return query.get();
  }

  Future<void> restoreVersion(int versionId) async {
    final NoteVersion version = await (_db.select(_db.noteVersions)
          ..where((NoteVersions row) => row.id.equals(versionId)))
        .getSingle();
    await saveContent(
      id: version.noteId,
      title: version.title,
      body: version.body,
      folder: version.folder,
      tags: decodeTags(version.tags),
      colorValue: version.colorValue,
    );
  }

  Future<void> setPinned(String id, {required bool value}) =>
      _patch(id, NotesCompanion(isPinned: Value<bool>(value)));

  Future<void> setFavorite(String id, {required bool value}) =>
      _patch(id, NotesCompanion(isFavorite: Value<bool>(value)));

  Future<void> archive(String id) => _patch(
        id,
        const NotesCompanion(
          isArchived: Value<bool>(true),
          isTrashed: Value<bool>(false),
        ),
      );

  Future<void> unarchive(String id) => _patch(
        id,
        const NotesCompanion(isArchived: Value<bool>(false)),
      );

  Future<void> trash(String id) => _patch(
        id,
        const NotesCompanion(
          isTrashed: Value<bool>(true),
          isArchived: Value<bool>(false),
          isPinned: Value<bool>(false),
        ),
      );

  Future<void> restore(String id) => _patch(
        id,
        const NotesCompanion(isTrashed: Value<bool>(false)),
      );

  Future<void> permanentlyDelete(String id) async {
    await (_db.delete(_db.notes)..where((Notes row) => row.id.equals(id))).go();
  }

  Future<int> emptyTrash() {
    return (_db.delete(_db.notes)..where((Notes row) => row.isTrashed.equals(true)))
        .go();
  }

  Future<Set<String>> folders() async {
    final List<Note> values = await _db.select(_db.notes).get();
    return values
        .where((Note note) => !note.isTrashed && note.folder.trim().isNotEmpty)
        .map((Note note) => note.folder.trim())
        .toSet();
  }

  Future<Set<String>> tags() async {
    final List<Note> values = await _db.select(_db.notes).get();
    return values
        .where((Note note) => !note.isTrashed)
        .expand((Note note) => decodeTags(note.tags))
        .toSet();
  }

  List<String> decodeTags(String encoded) {
    try {
      final Object? value = jsonDecode(encoded);
      if (value is! List<Object?>) {
        return <String>[];
      }
      return value
          .whereType<String>()
          .map((String tag) => tag.trim())
          .where((String tag) => tag.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return <String>[];
    }
  }

  Future<void> _patch(String id, NotesCompanion patch) async {
    await (_db.update(_db.notes)..where((Notes row) => row.id.equals(id))).write(
      patch.copyWith(updatedAt: Value<DateTime>(DateTime.now().toUtc())),
    );
  }

  String _encodeTags(Iterable<String> tags) {
    final List<String> values = tags
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return jsonEncode(values);
  }
}
