import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';

void main() {
  test('primary offline lifecycle survives backup and restore', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final NoteRepository notes = NoteRepository(database);
    final BackupRepository backups = BackupRepository(database);

    final Note created = await notes.create(
      title: 'Release checklist',
      body: 'Draft',
      folder: 'Work',
      tags: const <String>['offline', 'release'],
    );

    await notes.saveContent(
      id: created.id,
      title: 'Release checklist',
      body: 'Verify offline search and recovery',
      folder: 'Work',
      tags: const <String>['offline', 'release'],
      colorValue: 0xFFE3F2FD,
    );
    await notes.setPinned(created.id, value: true);
    await notes.setFavorite(created.id, value: true);

    final List<Note> searchResults = await notes.list(
      const NoteFilter(query: 'recovery'),
    );
    expect(searchResults.map((Note note) => note.id), <String>[created.id]);

    await notes.archive(created.id);
    expect(await notes.list(const NoteFilter()), isEmpty);
    expect(
      (await notes.list(
        const NoteFilter(collection: NoteCollection.archive),
      ))
          .single
          .id,
      created.id,
    );

    await notes.unarchive(created.id);
    await notes.trash(created.id);
    expect(
      (await notes.list(
        const NoteFilter(collection: NoteCollection.trash),
      ))
          .single
          .id,
      created.id,
    );

    await notes.restore(created.id);
    final Note restoredFromTrash = await notes.getById(created.id);
    expect(restoredFromTrash.isTrashed, isFalse);
    expect(restoredFromTrash.isPinned, isFalse);
    expect(restoredFromTrash.isFavorite, isTrue);

    final String backup = await backups.exportJson();
    expect(await notes.versions(created.id), hasLength(1));

    await notes.permanentlyDelete(created.id);
    expect(await notes.list(const NoteFilter()), isEmpty);

    final RestoreReport report = await backups.restoreJson(backup);
    expect(report.importedNotes, 1);
    expect(report.importedVersions, 1);
    expect(report.skippedNewerNotes, 0);

    final Note recovered = await notes.getById(created.id);
    expect(recovered.title, 'Release checklist');
    expect(recovered.body, 'Verify offline search and recovery');
    expect(recovered.folder, 'Work');
    expect(notes.decodeTags(recovered.tags), <String>['offline', 'release']);
    expect(recovered.colorValue, 0xFFE3F2FD);
    expect(recovered.isFavorite, isTrue);
    expect(recovered.isPinned, isFalse);
    expect(await notes.versions(created.id), hasLength(1));

    final List<Note> recoveredSearch = await notes.list(
      const NoteFilter(query: 'offline'),
    );
    expect(recoveredSearch.map((Note note) => note.id), <String>[created.id]);
  });
}
