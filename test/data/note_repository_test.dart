import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';

void main() {
  late AppDatabase database;
  late NoteRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = NoteRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists a note', () async {
    final Note created = await repository.create(
      title: 'Ideas',
      body: 'Build a local notes app',
      folder: 'Projects',
      tags: const <String>['flutter', 'offline'],
    );

    final List<Note> notes = await repository.list(const NoteFilter());

    expect(notes, hasLength(1));
    expect(notes.single.id, created.id);
    expect(notes.single.folder, 'Projects');
    expect(repository.decodeTags(notes.single.tags), <String>[
      'flutter',
      'offline',
    ]);
  });

  test('content and lifecycle changes advance the stored update time', () async {
    final Note created = await repository.create(title: 'Timestamp');

    await repository.saveContent(
      id: created.id,
      title: 'Timestamp changed',
      body: '',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );
    final Note contentChanged = await repository.getById(created.id);
    expect(contentChanged.updatedAt.isAfter(created.updatedAt), isTrue);

    await repository.setFavorite(created.id, value: true);
    final Note lifecycleChanged = await repository.getById(created.id);
    expect(
      lifecycleChanged.updatedAt.isAfter(contentChanged.updatedAt),
      isTrue,
    );
  });

  test('saving changed content creates a version snapshot', () async {
    final Note created = await repository.create(title: 'First', body: 'One');

    await repository.saveContent(
      id: created.id,
      title: 'Second',
      body: 'Two',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );

    final List<NoteVersion> versions = await repository.versions(created.id);
    final Note updated = await repository.getById(created.id);

    expect(versions, hasLength(1));
    expect(versions.single.title, 'First');
    expect(versions.single.body, 'One');
    expect(updated.title, 'Second');
  });

  test(
    'saving unchanged content does not create duplicate snapshots',
    () async {
      final Note created = await repository.create(
        title: 'Same',
        body: 'Content',
      );

      await repository.saveContent(
        id: created.id,
        title: 'Same',
        body: 'Content',
        folder: '',
        tags: const <String>[],
        colorValue: null,
      );

      expect(await repository.versions(created.id), isEmpty);
    },
  );

  test('restoring a version makes earlier content current', () async {
    final Note created = await repository.create(title: 'First', body: 'One');
    await repository.saveContent(
      id: created.id,
      title: 'Second',
      body: 'Two',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );
    final NoteVersion version = (await repository.versions(created.id)).single;

    await repository.restoreVersion(version.id);

    final Note restored = await repository.getById(created.id);
    expect(restored.title, 'First');
    expect(restored.body, 'One');
  });

  test('full-text search finds note content', () async {
    await repository.create(title: 'Trip', body: 'Packing checklist');
    await repository.create(title: 'School', body: 'Physics homework');

    final List<Note> results = await repository.list(
      const NoteFilter(query: 'physics'),
    );

    expect(results, hasLength(1));
    expect(results.single.title, 'School');
  });

  test('full-text search safely handles quote punctuation', () async {
    await repository.create(title: 'Quoted idea', body: 'A physics note');

    final List<Note> results = await repository.list(
      const NoteFilter(query: 'physics"'),
    );

    expect(results, hasLength(1));
    expect(results.single.title, 'Quoted idea');
  });

  test('favorite collection contains only active favorites', () async {
    final Note favorite = await repository.create(title: 'Favorite');
    final Note archived = await repository.create(title: 'Archived favorite');
    await repository.setFavorite(favorite.id, value: true);
    await repository.setFavorite(archived.id, value: true);
    await repository.archive(archived.id);

    final List<Note> results = await repository.list(
      const NoteFilter(collection: NoteCollection.favorites),
    );

    expect(results.map((Note note) => note.id), <String>[favorite.id]);
  });

  test('archive and unarchive move a note between collections', () async {
    final Note created = await repository.create(title: 'Archive me');
    await repository.archive(created.id);

    expect(await repository.list(const NoteFilter()), isEmpty);
    expect(
      await repository.list(
        const NoteFilter(collection: NoteCollection.archive),
      ),
      hasLength(1),
    );

    await repository.unarchive(created.id);
    expect(await repository.list(const NoteFilter()), hasLength(1));
  });

  test('trash is separated from active notes and can be restored', () async {
    final Note created = await repository.create(title: 'Temporary');
    await repository.setPinned(created.id, value: true);
    await repository.trash(created.id);

    final Note trashed = await repository.getById(created.id);
    expect(trashed.isPinned, isFalse);
    expect(await repository.list(const NoteFilter()), isEmpty);
    expect(
      await repository.list(const NoteFilter(collection: NoteCollection.trash)),
      hasLength(1),
    );

    await repository.restore(created.id);
    expect(await repository.list(const NoteFilter()), hasLength(1));
  });

  test('trashed notes cannot be pinned', () async {
    final Note created = await repository.create(title: 'Trashed');
    await repository.trash(created.id);

    await expectLater(
      repository.setPinned(created.id, value: true),
      throwsA(isA<ValidationException>()),
    );

    final Note trashed = await repository.getById(created.id);
    expect(trashed.isTrashed, isTrue);
    expect(trashed.isPinned, isFalse);
  });

  test('folder metadata is scoped to the requested collection', () async {
    final Note active = await repository.create(
      title: 'Active',
      folder: 'Active folder',
    );
    final Note favorite = await repository.create(
      title: 'Favorite',
      folder: 'Favorite folder',
    );
    final Note archived = await repository.create(
      title: 'Archived',
      folder: 'Archive folder',
    );
    final Note trashed = await repository.create(
      title: 'Trashed',
      folder: 'Trash folder',
    );

    await repository.setFavorite(favorite.id, value: true);
    await repository.archive(archived.id);
    await repository.trash(trashed.id);

    expect(await repository.folders(collection: NoteCollection.all), <String>{
      'Active folder',
      'Favorite folder',
    });
    expect(
      await repository.folders(collection: NoteCollection.favorites),
      <String>{'Favorite folder'},
    );
    expect(
      await repository.folders(collection: NoteCollection.archive),
      <String>{'Archive folder'},
    );
    expect(await repository.folders(collection: NoteCollection.trash), <String>{
      'Trash folder',
    });

    expect((await repository.getById(active.id)).folder, 'Active folder');
  });

  test('tag metadata is scoped to the requested collection', () async {
    final Note favorite = await repository.create(
      title: 'Favorite',
      tags: const <String>['fav-tag'],
    );
    final Note archived = await repository.create(
      title: 'Archived',
      tags: const <String>['archive-tag'],
    );
    final Note trashed = await repository.create(
      title: 'Trashed',
      tags: const <String>['trash-tag'],
    );

    await repository.setFavorite(favorite.id, value: true);
    await repository.archive(archived.id);
    await repository.trash(trashed.id);

    expect(await repository.tags(collection: NoteCollection.all), <String>{
      'fav-tag',
    });
    expect(
      await repository.tags(collection: NoteCollection.favorites),
      <String>{'fav-tag'},
    );
    expect(await repository.tags(collection: NoteCollection.archive), <String>{
      'archive-tag',
    });
    expect(await repository.tags(collection: NoteCollection.trash), <String>{
      'trash-tag',
    });
  });

  test('permanent delete cascades version history', () async {
    final Note created = await repository.create(title: 'First', body: 'One');
    await repository.saveContent(
      id: created.id,
      title: 'Second',
      body: 'Two',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );
    expect(await repository.versions(created.id), hasLength(1));

    await repository.permanentlyDelete(created.id);

    expect(await repository.versions(created.id), isEmpty);
  });
}
