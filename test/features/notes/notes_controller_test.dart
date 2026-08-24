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

  test('changing sort order reloads notes with the selected order', () async {
    await repository.create(title: 'Zebra');
    await repository.create(title: 'alpha');
    await repository.create(title: 'Middle');

    controller.setSort(NoteSort.titleAscending);
    await controller.load(showLoading: false);

    expect(controller.filter.sort, NoteSort.titleAscending);
    expect(controller.notes.map((Note note) => note.title), <String>[
      'alpha',
      'Middle',
      'Zebra',
    ]);
  });

  test('changing sort preserves active collection and filters', () async {
    controller.filter = const NoteFilter(
      collection: NoteCollection.favorites,
      query: 'idea',
      folder: 'Projects',
      tag: 'flutter',
    );

    controller.setSort(NoteSort.titleDescending);

    expect(controller.filter.collection, NoteCollection.favorites);
    expect(controller.filter.query, 'idea');
    expect(controller.filter.folder, 'Projects');
    expect(controller.filter.tag, 'flutter');
    expect(controller.filter.sort, NoteSort.titleDescending);

    await controller.load(showLoading: false);
  });

  test('folder rename keeps the active filter aligned', () async {
    final Note note = await repository.create(
      title: 'Folder rename',
      folder: 'Old folder',
    );
    controller.filter = const NoteFilter(folder: 'Old folder');
    await controller.load(showLoading: false);

    final int changed = await controller.renameFolder(
      'Old folder',
      'New folder',
    );

    expect(changed, 1);
    expect(controller.filter.folder, 'New folder');
    expect(controller.notes.map((Note value) => value.id), <String>[note.id]);
    expect(controller.folders, contains('New folder'));
    expect(controller.folders, isNot(contains('Old folder')));
  });

  test('tag merge keeps the active filter aligned', () async {
    final Note note = await repository.create(
      title: 'Tag merge',
      tags: const <String>['old-tag', 'existing'],
    );
    controller.filter = const NoteFilter(tag: 'old-tag');
    await controller.load(showLoading: false);

    final int changed = await controller.renameTag('old-tag', 'existing');

    expect(changed, 1);
    expect(controller.filter.tag, 'existing');
    expect(controller.notes.map((Note value) => value.id), <String>[note.id]);
    expect(controller.tags, contains('existing'));
    expect(controller.tags, isNot(contains('old-tag')));
  });
}
