import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';
import 'package:notenest/features/notes/notes_controller.dart';
import 'package:notenest/features/notes/notes_page.dart';
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

  Future<NotesController> pumpCollection(
    WidgetTester tester,
    NoteCollection collection,
  ) async {
    final NotesController controller = NotesController(repository);
    controller.filter = NoteFilter(collection: collection);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotesPage(
            controller: controller,
            repository: repository,
            files: files,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> unmount(WidgetTester tester, NotesController controller) async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  testWidgets('all-notes empty state offers create and import actions', (
    WidgetTester tester,
  ) async {
    final NotesController controller = await pumpCollection(
      tester,
      NoteCollection.all,
    );

    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(find.text(AppStrings.newNote), findsOneWidget);
    expect(find.byTooltip(AppStrings.importMarkdown), findsOneWidget);

    await unmount(tester, controller);
  });

  testWidgets(
    'favorites empty state does not offer mismatched create or import',
    (WidgetTester tester) async {
      final NotesController controller = await pumpCollection(
        tester,
        NoteCollection.favorites,
      );

      expect(find.text(AppStrings.favoritesEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.newNote), findsNothing);
      expect(find.byTooltip(AppStrings.importMarkdown), findsNothing);

      await unmount(tester, controller);
    },
  );

  testWidgets(
    'archive empty state explains the collection without create action',
    (WidgetTester tester) async {
      final NotesController controller = await pumpCollection(
        tester,
        NoteCollection.archive,
      );

      expect(find.text(AppStrings.archiveEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.newNote), findsNothing);
      expect(find.byTooltip(AppStrings.importMarkdown), findsNothing);

      await unmount(tester, controller);
    },
  );

  testWidgets('trash empty state explains retention without create action', (
    WidgetTester tester,
  ) async {
    final NotesController controller = await pumpCollection(
      tester,
      NoteCollection.trash,
    );

    expect(find.text(AppStrings.trashEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.newNote), findsNothing);
    expect(find.byTooltip(AppStrings.importMarkdown), findsNothing);

    await unmount(tester, controller);
  });

  testWidgets('sort control changes the controller and visible note order', (
    WidgetTester tester,
  ) async {
    await repository.create(title: 'Zebra');
    await repository.create(title: 'alpha');
    await repository.create(title: 'Middle');
    final NotesController controller = await pumpCollection(
      tester,
      NoteCollection.all,
    );

    expect(find.text('Newest first'), findsOneWidget);

    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();
    expect(find.text('Title A–Z'), findsOneWidget);

    await tester.tap(find.text('Title A–Z'));
    await tester.pumpAndSettle();

    expect(controller.filter.sort, NoteSort.titleAscending);
    expect(controller.notes.map((Note note) => note.title), <String>[
      'alpha',
      'Middle',
      'Zebra',
    ]);
    expect(find.text('Title A–Z'), findsOneWidget);

    await unmount(tester, controller);
  });
}
