import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';

void main() {
  late AppDatabase database;
  late NoteRepository notes;
  late BackupRepository backups;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notes = NoteRepository(database);
    backups = BackupRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('primary offline lifecycle survives backup and restore', () async {
    final Note created = await notes.create(
      title: 'Release roadmap',
      body: 'Plan the offline-first release.',
      folder: 'Projects',
      tags: const <String>['flutter', 'todo'],
    );

    await notes.saveContent(
      id: created.id,
      title: 'Release roadmap v2',
      body: '- [ ] Ship the offline-first release',
      folder: 'Projects',
      tags: const <String>['flutter', 'todo'],
      colorValue: 0xFFE3F2FD,
    );

    final List<Note> searchResults = await notes.list(
      const NoteFilter(query: 'ship'),
    );
    expect(searchResults, hasLength(1));
    expect(searchResults.single.id, created.id);

    await notes.setPinned(created.id, value: true);
    await notes.setFavorite(created.id, value: true);

    final List<Note> favorites = await notes.list(
      const NoteFilter(collection: NoteCollection.favorites),
    );
    expect(favorites, hasLength(1));
    expect(favorites.single.isPinned, isTrue);
    expect(favorites.single.isFavorite, isTrue);

    await notes.archive(created.id);
    expect(
      await notes.list(const NoteFilter(collection: NoteCollection.all)),
      isEmpty,
    );
    expect(
      await notes.list(const NoteFilter(collection: NoteCollection.archive)),
      hasLength(1),
    );

    await notes.unarchive(created.id);
    await notes.trash(created.id);
    final List<Note> trashed = await notes.list(
      const NoteFilter(collection: NoteCollection.trash),
    );
    expect(trashed, hasLength(1));
    expect(trashed.single.isPinned, isFalse);

    await notes.restore(created.id);
    final Note beforeBackup = await notes.getById(created.id);
    expect(beforeBackup.title, 'Release roadmap v2');
    expect(beforeBackup.body, contains('offline-first'));
    expect(notes.decodeTags(beforeBackup.tags), <String>['flutter', 'todo']);

    final String backup = await backups.exportJson();
    await notes.permanentlyDelete(created.id);
    expect(
      await notes.list(const NoteFilter(collection: NoteCollection.all)),
      isEmpty,
    );

    final RestoreReport report = await backups.restoreJson(backup);
    final Note restored = await notes.getById(created.id);

    expect(report.importedNotes, 1);
    expect(report.importedVersions, greaterThanOrEqualTo(1));
    expect(restored.title, 'Release roadmap v2');
    expect(restored.body, '- [ ] Ship the offline-first release');
    expect(restored.folder, 'Projects');
    expect(notes.decodeTags(restored.tags), <String>['flutter', 'todo']);
  });
}
