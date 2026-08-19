import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/features/notes/note_editor_page.dart';
import 'package:notenest/services/file_transfer_service.dart';

void main() {
  testWidgets('shows a retryable safe state when a note cannot be loaded',
      (WidgetTester tester) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final NoteRepository notes = NoteRepository(database);
    final FileTransferService files = FileTransferService(
      backups: BackupRepository(database),
      notes: notes,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NoteEditorPage(
          noteId: 'missing-note',
          repository: notes,
          files: files,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noteLoadFailedTitle), findsOneWidget);
    expect(find.text(AppStrings.noteLoadFailedBody), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
