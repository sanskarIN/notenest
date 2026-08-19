import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:notenest/data/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[Notes, NoteVersions])
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'notenest'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator migrator) async {
          await migrator.createAll();
          await _createSearchInfrastructure();
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createSearchInfrastructure() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        id UNINDEXED,
        title,
        body,
        folder,
        tags,
        content='notes',
        content_rowid='rowid'
      )
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, id, title, body, folder, tags)
        VALUES (new.rowid, new.id, new.title, new.body, new.folder, new.tags);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, id, title, body, folder, tags)
        VALUES ('delete', old.rowid, old.id, old.title, old.body, old.folder, old.tags);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, id, title, body, folder, tags)
        VALUES ('delete', old.rowid, old.id, old.title, old.body, old.folder, old.tags);
        INSERT INTO notes_fts(rowid, id, title, body, folder, tags)
        VALUES (new.rowid, new.id, new.title, new.body, new.folder, new.tags);
      END
    ''');
    await customStatement("INSERT INTO notes_fts(notes_fts) VALUES('rebuild')");
  }

  Future<List<Note>> searchFts(String rawQuery) async {
    final String query = _ftsQuery(rawQuery);
    if (query.isEmpty) {
      return select(notes).get();
    }

    final List<QueryRow> rows = await customSelect(
      '''
      SELECT n.*
      FROM notes AS n
      JOIN notes_fts ON notes_fts.rowid = n.rowid
      WHERE notes_fts MATCH ?
      ORDER BY bm25(notes_fts), n.updated_at DESC
      ''',
      variables: <Variable<Object>>[Variable<String>(query)],
      readsFrom: <ResultSetImplementation<dynamic>>{notes},
    ).get();

    return rows
        .map((QueryRow row) => notes.map(row.data))
        .toList(growable: false);
  }

  String _ftsQuery(String input) {
    final Iterable<String> terms = input
        .trim()
        .split(RegExp(r'\s+'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .map((String value) => value.replaceAll('"', '""'));
    return terms.map((String value) => '"$value"*').join(' AND ');
  }
}
