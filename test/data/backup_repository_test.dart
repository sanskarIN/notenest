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
    await notes.create(title: 'Backup me', body: 'Offline data');
    final String payload = await backups.exportJson();

    await notes.emptyTrash();
    final RestoreReport report = await backups.restoreJson(payload);

    expect(report.importedNotes, 1);
    expect(jsonDecode(payload), isA<Map<String, Object?>>());
  });

  test('rejects a backup from another application', () async {
    const String payload = '{"app":"Other","schemaVersion":1,"notes":[],"versions":[]}';

    expect(
      () => backups.restoreJson(payload),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects malformed JSON without changing data', () async {
    await notes.create(title: 'Keep me');

    expect(
      () => backups.restoreJson('{broken'),
      throwsA(isA<ValidationException>()),
    );
    expect((await database.select(database.notes).get()), hasLength(1));
  });
}
