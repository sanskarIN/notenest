import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/features/notes/note_editor_page.dart';
import 'package:notenest/services/file_transfer_service.dart';

void main() {
  late AppDatabase database;
  late NoteRepository repository;
  late FileTransferService files;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = NoteRepository(database);
    files = FileTransferService(
      backups: BackupRepository(database),
      notes: repository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets(
    'color palette exposes an explicit selected state',
    (WidgetTester tester) async {
      final Note note = await repository.create(title: 'Palette test');
      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorPage(
            noteId: note.id,
            repository: repository,
            files: files,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Default note color, selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byTooltip('Red note color'));
      await tester.pump();

      expect(find.byTooltip('Red note color, selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
