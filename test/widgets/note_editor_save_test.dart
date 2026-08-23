import 'dart:async';

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
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => NoteEditorPage(
                          noteId: note.id,
                          repository: repository,
                          files: files,
                        ),
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
    expect(
      (await repository.getById(note.id)).body,
      'Newest draft before back',
    );
  });

  testWidgets('formatting at offset zero targets the empty first line', (
    WidgetTester tester,
  ) async {
    final Note note = await repository.create(
      title: 'Formatting boundary',
      body: '\nSecond line',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => NoteEditorPage(
                          noteId: note.id,
                          repository: repository,
                          files: files,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open formatting editor'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open formatting editor'));
    await tester.pumpAndSettle();

    final Finder textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));
    final TextField bodyField = tester.widget<TextField>(textFields.last);
    final TextEditingController bodyController = bodyField.controller!;
    bodyController.selection = const TextSelection.collapsed(offset: 0);

    await tester.tap(find.byTooltip('Heading'));
    await tester.pump();

    expect(bodyController.text, '## \nSecond line');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Open formatting editor'), findsOneWidget);
  });

  testWidgets('editor shows live local word and character counts', (
    WidgetTester tester,
  ) async {
    final Note note = await repository.create(
      title: 'Text metrics',
      body: 'One two',
    );

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

    expect(find.text('2 words · 7 characters'), findsOneWidget);

    final Finder bodyField = find.byType(TextField).last;
    await tester.enterText(bodyField, 'One\n two   three');
    await tester.pump();

    expect(find.text('3 words · 16 characters'), findsOneWidget);

    await tester.enterText(bodyField, 'Solo');
    await tester.pump();

    expect(find.text('1 word · 4 characters'), findsOneWidget);
  });

  testWidgets(
    'a missing note shows a retryable load error instead of spinning',
    (WidgetTester tester) async {
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
    },
  );
}
