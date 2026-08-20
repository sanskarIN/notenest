import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';
import 'package:notenest/features/notes/notes_controller.dart';

void main() {
  late AppDatabase database;
  late NoteRepository repository;
  late NotesController controller;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = NoteRepository(database);
    controller = NotesController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test('switching collections clears stale folder and tag filters', () async {
    controller.filter = const NoteFilter(folder: 'Projects', tag: 'flutter');

    controller.setCollection(NoteCollection.archive);

    expect(controller.filter.collection, NoteCollection.archive);
    expect(controller.filter.folder, isNull);
    expect(controller.filter.tag, isNull);

    await controller.load(showLoading: false);
  });

  test('loads collection-specific filter metadata', () async {
    final Note archived = await repository.create(
      title: 'Archived',
      folder: 'Archive folder',
      tags: const <String>['archive-tag'],
    );
    final Note trashed = await repository.create(
      title: 'Trashed',
      folder: 'Trash folder',
      tags: const <String>['trash-tag'],
    );
    await repository.archive(archived.id);
    await repository.trash(trashed.id);

    controller.filter = const NoteFilter(collection: NoteCollection.trash);
    await controller.load(showLoading: false);

    expect(controller.folders, <String>{'Trash folder'});
    expect(controller.tags, <String>{'trash-tag'});
    expect(controller.notes.map((Note note) => note.id), <String>[trashed.id]);
  });
}
