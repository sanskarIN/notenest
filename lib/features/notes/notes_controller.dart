import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notenest/core/logging/app_logger.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/core/utils/debouncer.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';

final class NotesController extends ChangeNotifier {
  NotesController(
    this._repository, {
    AppLogger logger = const AppLogger(),
  })  : _logger = logger,
        _searchDebouncer = Debouncer(AppTokens.searchDebounce);

  final NoteRepository _repository;
  final AppLogger _logger;
  final Debouncer _searchDebouncer;

  NoteFilter filter = const NoteFilter();
  List<Note> notes = const <Note>[];
  Set<String> folders = const <String>{};
  Set<String> tags = const <String>{};
  bool loading = false;
  Object? error;
  bool _disposed = false;
  int _loadGeneration = 0;

  Future<void> load({bool showLoading = true}) async {
    final int generation = ++_loadGeneration;
    final NoteFilter requestedFilter = filter;
    if (showLoading) {
      loading = true;
      error = null;
      _notify();
    }
    try {
      final List<Note> nextNotes = await _repository.list(requestedFilter);
      final Set<String> nextFolders = await _repository.folders();
      final Set<String> nextTags = await _repository.tags();
      if (!_isCurrentLoad(generation)) return;
      notes = nextNotes;
      folders = nextFolders;
      tags = nextTags;
      error = null;
    } catch (caught) {
      if (!_isCurrentLoad(generation)) return;
      error = caught;
      _logger.error(
        'notes.load_failed',
        fields: <String, Object?>{
          'errorType': caught.runtimeType.toString(),
          'collection': requestedFilter.collection,
        },
      );
    } finally {
      if (_isCurrentLoad(generation)) {
        loading = false;
        _notify();
      }
    }
  }

  void setCollection(NoteCollection value) {
    filter = filter.copyWith(collection: value);
    unawaited(load());
  }

  void setQuery(String value) {
    filter = filter.copyWith(query: value);
    _searchDebouncer.run(() => load(showLoading: false));
  }

  void setFolder(String? value) {
    filter = filter.copyWith(
      folder: value,
      clearFolder: value == null,
    );
    unawaited(load(showLoading: false));
  }

  void setTag(String? value) {
    filter = filter.copyWith(tag: value, clearTag: value == null);
    unawaited(load(showLoading: false));
  }

  Future<Note> createNote() async {
    final Note note = await _repository.create();
    await load(showLoading: false);
    return note;
  }

  Future<void> setPinned(Note note, {required bool value}) async {
    await _repository.setPinned(note.id, value: value);
    await load(showLoading: false);
  }

  Future<void> setFavorite(Note note, {required bool value}) async {
    await _repository.setFavorite(note.id, value: value);
    await load(showLoading: false);
  }

  Future<void> archive(Note note) async {
    await _repository.archive(note.id);
    await load(showLoading: false);
  }

  Future<void> unarchive(Note note) async {
    await _repository.unarchive(note.id);
    await load(showLoading: false);
  }

  Future<void> trash(Note note) async {
    await _repository.trash(note.id);
    await load(showLoading: false);
  }

  Future<void> restore(Note note) async {
    await _repository.restore(note.id);
    await load(showLoading: false);
  }

  Future<void> permanentlyDelete(Note note) async {
    await _repository.permanentlyDelete(note.id);
    await load(showLoading: false);
  }

  Future<int> emptyTrash() async {
    final int deleted = await _repository.emptyTrash();
    await load(showLoading: false);
    return deleted;
  }

  bool _isCurrentLoad(int generation) {
    return !_disposed && generation == _loadGeneration;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration += 1;
    _searchDebouncer.dispose();
    super.dispose();
  }
}
