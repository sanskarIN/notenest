import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(updated.title, 'Second');
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

  test('trash is separated from active notes and can be restored', () async {
    final Note created = await repository.create(title: 'Temporary');
    await repository.trash(created.id);

    expect(await repository.list(const NoteFilter()), isEmpty);
    expect(
      await repository.list(
        const NoteFilter(collection: NoteCollection.trash),
      ),
      hasLength(1),
    );

    await repository.restore(created.id);
    expect(await repository.list(const NoteFilter()), hasLength(1));
  });
}
