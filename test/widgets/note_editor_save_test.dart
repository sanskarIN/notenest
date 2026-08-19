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

  testWidgets('back navigation persists the latest draft before leaving', (
    WidgetTester tester,
  ) async {
    final Note note = await repository.create(
      title: 'Navigation save',
      body: 'Old body',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => NoteEditorPage(
                        noteId: note.id,
                        repository: repository,
                        files: files,
                      ),
                    ),
                  );
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    final Finder textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));
    await tester.enterText(textFields.last, 'Newest draft before back');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    expect((await repository.getById(note.id)).body, 'Newest draft before back');
  });

  testWidgets('a missing note shows a retryable load error instead of spinning', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NoteEditorPage(
          noteId: 'missing-note',
          repository: repository,
          files: files,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Could not open this note'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
