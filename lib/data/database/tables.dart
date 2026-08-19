import 'package:drift/drift.dart';

class Notes extends Table {
  TextColumn get id => text().named('id')();
  TextColumn get title => text().named('title').withDefault(const Constant(''))();
  TextColumn get body => text().named('body').withDefault(const Constant(''))();
  TextColumn get folder => text().named('folder').withDefault(const Constant(''))();
  TextColumn get tags => text().named('tags').withDefault(const Constant('[]'))();
  IntColumn get colorValue => integer().named('color_value').nullable()();
  BoolColumn get isPinned =>
      boolean().named('is_pinned').withDefault(const Constant(false))();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();
  BoolColumn get isTrashed =>
      boolean().named('is_trashed').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class NoteVersions extends Table {
  IntColumn get id => integer().named('id').autoIncrement()();
  TextColumn get noteId => text()
      .named('note_id')
      .references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().named('title')();
  TextColumn get body => text().named('body')();
  TextColumn get folder => text().named('folder')();
  TextColumn get tags => text().named('tags')();
  IntColumn get colorValue => integer().named('color_value').nullable()();
  BoolColumn get isPinned => boolean().named('is_pinned')();
  BoolColumn get isFavorite => boolean().named('is_favorite')();
  BoolColumn get isArchived => boolean().named('is_archived')();
  BoolColumn get isTrashed => boolean().named('is_trashed')();
  DateTimeColumn get capturedAt => dateTime().named('captured_at')();
}
