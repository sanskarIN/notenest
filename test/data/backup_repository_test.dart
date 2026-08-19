import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';

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

  test('exports and restores a validated backup', () async {
    final Note created = await notes.create(
      title: 'Backup me',
      body: 'Offline data',
    );
    final String payload = await backups.exportJson();
    await notes.permanentlyDelete(created.id);

    final RestoreReport report = await backups.restoreJson(payload);
    final Note restored = await notes.getById(created.id);

    expect(report.importedNotes, 1);
    expect(restored.title, 'Backup me');
    expect(restored.body, 'Offline data');
  });

  test('preserves a newer local note during restore', () async {
    final Note created = await notes.create(title: 'Old title', body: 'Old body');
    final String olderBackup = await backups.exportJson();

    await notes.saveContent(
      id: created.id,
      title: 'New title',
      body: 'New body',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );

    final RestoreReport report = await backups.restoreJson(olderBackup);
    final Note current = await notes.getById(created.id);

    expect(report.skippedNewerNotes, 1);
    expect(current.title, 'New title');
    expect(current.body, 'New body');
  });

  test('rejects a backup from another application', () async {
    const String payload =
        '{"app":"Other","schemaVersion":1,"notes":[],"versions":[]}';

    expect(
      () => backups.restoreJson(payload),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects an unsupported backup schema version', () async {
    const String payload =
        '{"app":"NoteNest","schemaVersion":99,"notes":[],"versions":[]}';

    expect(
      () => backups.restoreJson(payload),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects invalid timestamps before changing data', () async {
    final Note created = await notes.create(title: 'Keep me');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    firstNote['updatedAt'] = 'not-a-date';

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });

  test('rejects timestamps without an explicit UTC marker', () async {
    final Note created = await notes.create(title: 'Keep me');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    firstNote['updatedAt'] = '2026-08-19T10:00:00.000';

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });

  test('rejects note timestamps whose update precedes creation', () async {
    final Note created = await notes.create(title: 'Keep me');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    firstNote['createdAt'] = '2026-08-19T10:00:00.000Z';
    firstNote['updatedAt'] = '2026-08-19T09:00:00.000Z';

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });

  test('rejects out-of-range ARGB color values', () async {
    final Note created = await notes.create(title: 'Keep me');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    firstNote['colorValue'] = 0x100000000;

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });

  test('rejects malformed serialized tags before changing data', () async {
    final Note created = await notes.create(title: 'Keep me');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    firstNote['tags'] = '{broken';

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });

  test('rejects duplicate note ids', () async {
    await notes.create(title: 'Source');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    rawNotes.add(Map<String, Object?>.from(rawNotes.single! as Map<String, Object?>));

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects note ids with surrounding whitespace', () async {
    await notes.create(title: 'Source');
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    final Map<String, Object?> firstNote =
        rawNotes.single! as Map<String, Object?>;
    final Object? originalId = firstNote['id'];
    firstNote['id'] = ' $originalId ';

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects version history whose note does not exist', () async {
    final Note created = await notes.create(title: 'First', body: 'One');
    await notes.saveContent(
      id: created.id,
      title: 'Second',
      body: 'Two',
      folder: '',
      tags: const <String>[],
      colorValue: null,
    );
    final Map<String, Object?> payload =
        jsonDecode(await backups.exportJson()) as Map<String, Object?>;
    final List<Object?> rawNotes = payload['notes']! as List<Object?>;
    rawNotes.clear();
    final List<Object?> rawVersions = payload['versions']! as List<Object?>;
    final Map<String, Object?> version =
        rawVersions.single! as Map<String, Object?>;
    version['noteId'] = 'missing-note';

    await notes.permanentlyDelete(created.id);

    expect(
      () => backups.restoreJson(jsonEncode(payload)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects malformed JSON without changing data', () async {
    final Note created = await notes.create(title: 'Keep me');

    expect(
      () => backups.restoreJson('{broken'),
      throwsA(isA<ValidationException>()),
    );
    expect((await notes.getById(created.id)).title, 'Keep me');
  });
}
