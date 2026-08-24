import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/domain/models/note_filter.dart';
import 'package:notenest/features/notes/note_editor_page.dart';
import 'package:notenest/features/notes/notes_controller.dart';
import 'package:notenest/services/file_transfer_service.dart';
import 'package:notenest/widgets/empty_state.dart';
import 'package:notenest/widgets/note_card.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({
    required this.controller,
    required this.repository,
    required this.files,
    super.key,
  });

  final NotesController controller;
  final NoteRepository repository;
  final FileTransferService files;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  bool _selectionBusy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
    unawaited(widget.controller.load());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    _searchController.dispose();
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    final Set<String> visibleIds = widget.controller.notes
        .map((Note note) => note.id)
        .toSet();
    setState(() {
      _selectedIds.removeWhere((String id) => !visibleIds.contains(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final NotesController controller = widget.controller;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: AppStrings.searchHint,
                  leading: const Icon(Icons.search_rounded),
                  onChanged: controller.setQuery,
                  trailing: <Widget>[
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          controller.setQuery('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
              if (controller.filter.collection ==
                  NoteCollection.all) ...<Widget>[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: AppStrings.importMarkdown,
                  onPressed: _selectionBusy ? null : _importMarkdown,
                  icon: const Icon(Icons.file_open_rounded),
                ),
              ],
              if (controller.filter.collection ==
                  NoteCollection.trash) ...<Widget>[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Empty trash',
                  onPressed:
                      controller.notes.isEmpty || _selectionBusy ? null : _emptyTrash,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
              ],
            ],
          ),
        ),
        _FilterRow(controller: controller),
        if (_selectedIds.isNotEmpty) _selectionBar(controller),
        Expanded(child: _body(controller)),
      ],
    );
  }

  Widget _selectionBar(NotesController controller) {
    final int count = _selectedIds.length;
    final String countLabel = '$count ${count == 1 ? 'note' : 'notes'} selected';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Clear selection',
              onPressed: _selectionBusy ? null : _clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
            Text(countLabel, key: const Key('note-selection-count')),
            const SizedBox(width: 8),
            if (controller.filter.collection == NoteCollection.all ||
                controller.filter.collection == NoteCollection.favorites) ...<Widget>[
              TextButton.icon(
                onPressed: _selectionBusy ? null : _archiveSelected,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
              TextButton.icon(
                onPressed: _selectionBusy ? null : _trashSelected,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Trash'),
              ),
            ],
            if (controller.filter.collection == NoteCollection.archive) ...<Widget>[
              TextButton.icon(
                onPressed: _selectionBusy ? null : _unarchiveSelected,
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('Unarchive'),
              ),
              TextButton.icon(
                onPressed: _selectionBusy ? null : _trashSelected,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Trash'),
              ),
            ],
            if (controller.filter.collection == NoteCollection.trash) ...<Widget>[
              TextButton.icon(
                onPressed: _selectionBusy ? null : _restoreSelected,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore'),
              ),
              TextButton.icon(
                onPressed: _selectionBusy ? null : _deleteSelectedForever,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete permanently'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(NotesController controller) {
    if (controller.loading && controller.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.notes.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load notes',
        message: 'Your notes remain on this device. Try loading them again.',
        action: FilledButton.icon(
          onPressed: () {
            unawaited(controller.load());
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }
    if (controller.notes.isEmpty) {
      return _collectionEmptyState(controller.filter.collection);
    }

    final bool selectionMode = _selectedIds.isNotEmpty;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = switch (constraints.maxWidth) {
            >= 1200 => 4,
            >= 850 => 3,
            >= 560 => 2,
            _ => 1,
          };
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: columns == 1 ? 250 : 270,
            ),
            itemCount: controller.notes.length,
            itemBuilder: (BuildContext context, int index) {
              final Note note = controller.notes[index];
              return NoteCard(
                note: note,
                selectionMode: selectionMode,
                selected: _selectedIds.contains(note.id),
                onSelect: _selectionBusy ? null : () => _toggleSelection(note),
                onOpen: () {
                  unawaited(_openEditor(note));
                },
                onFavorite: () {
                  unawaited(
                    _runNoteAction(
                      () =>
                          controller.setFavorite(note, value: !note.isFavorite),
                      failureMessage: 'Could not update the favorite state.',
                    ),
                  );
                },
                onPin: () {
                  unawaited(
                    _runNoteAction(
                      () => controller.setPinned(note, value: !note.isPinned),
                      failureMessage: 'Could not update the pin state.',
                    ),
                  );
                },
                onArchive: () {
                  unawaited(
                    _runNoteAction(
                      () => note.isArchived
                          ? controller.unarchive(note)
                          : controller.archive(note),
                      failureMessage: note.isArchived
                          ? 'Could not restore this note from Archive.'
                          : 'Could not archive this note.',
                    ),
                  );
                },
                onTrash: () {
                  unawaited(_trashWithUndo(note));
                },
                onRestore: () {
                  unawaited(
                    _runNoteAction(
                      () => controller.restore(note),
                      failureMessage: 'Could not restore this note.',
                    ),
                  );
                },
                onDeleteForever: () {
                  unawaited(_deleteForever(note));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _collectionEmptyState(NoteCollection collection) {
    final (IconData icon, String title, String message) = switch (collection) {
      NoteCollection.all => (
        Icons.note_add_outlined,
        AppStrings.emptyTitle,
        AppStrings.emptyBody,
      ),
      NoteCollection.favorites => (
        Icons.star_outline_rounded,
        AppStrings.favoritesEmptyTitle,
        AppStrings.favoritesEmptyBody,
      ),
      NoteCollection.archive => (
        Icons.archive_outlined,
        AppStrings.archiveEmptyTitle,
        AppStrings.archiveEmptyBody,
      ),
      NoteCollection.trash => (
        Icons.delete_outline_rounded,
        AppStrings.trashEmptyTitle,
        AppStrings.trashEmptyBody,
      ),
    };
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      action: collection == NoteCollection.all
          ? FilledButton.icon(
              onPressed: _createNote,
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.newNote),
            )
          : null,
    );
  }

  void _toggleSelection(Note note) {
    setState(() {
      if (!_selectedIds.add(note.id)) {
        _selectedIds.remove(note.id);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }

  Future<void> _archiveSelected() async {
    final Set<String> ids = Set<String>.of(_selectedIds);
    if (await _runSelectionAction(
      () => widget.controller.archiveMany(ids),
      failureMessage: 'Could not archive the selected notes.',
    )) {
      _message('Archived ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}.');
    }
  }

  Future<void> _unarchiveSelected() async {
    final Set<String> ids = Set<String>.of(_selectedIds);
    if (await _runSelectionAction(
      () => widget.controller.unarchiveMany(ids),
      failureMessage: 'Could not unarchive the selected notes.',
    )) {
      _message('Unarchived ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}.');
    }
  }

  Future<void> _trashSelected() async {
    final Set<String> ids = Set<String>.of(_selectedIds);
    final bool moved = await _runSelectionAction(
      () => widget.controller.trashMany(ids),
      failureMessage: 'Could not move the selected notes to trash.',
    );
    if (!moved || !mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved ${ids.length} ${ids.length == 1 ? 'note' : 'notes'} to trash.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            unawaited(_restoreBatchAfterUndo(ids));
          },
        ),
      ),
    );
  }

  Future<void> _restoreBatchAfterUndo(Set<String> ids) async {
    try {
      await widget.controller.restoreMany(ids);
    } on Object {
      _message('Could not undo the bulk trash action.');
    }
  }

  Future<void> _restoreSelected() async {
    final Set<String> ids = Set<String>.of(_selectedIds);
    if (await _runSelectionAction(
      () => widget.controller.restoreMany(ids),
      failureMessage: 'Could not restore the selected notes.',
    )) {
      _message('Restored ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}.');
    }
  }

  Future<void> _deleteSelectedForever() async {
    final Set<String> ids = Set<String>.of(_selectedIds);
    final bool confirmed = await _confirm(
      title: 'Delete selected notes permanently?',
      message:
          'This permanently deletes ${ids.length} ${ids.length == 1 ? 'note' : 'notes'} and their version history.',
    );
    if (!confirmed) return;
    if (await _runSelectionAction(
      () => widget.controller.permanentlyDeleteMany(ids),
      failureMessage: 'Could not permanently delete the selected notes.',
    )) {
      _message(
        'Permanently deleted ${ids.length} ${ids.length == 1 ? 'note' : 'notes'}.',
      );
    }
  }

  Future<bool> _runSelectionAction(
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    if (_selectionBusy || _selectedIds.isEmpty) return false;
    setState(() => _selectionBusy = true);
    try {
      await action();
      if (!mounted) return true;
      setState(_selectedIds.clear);
      return true;
    } on Object {
      _message(failureMessage);
      return false;
    } finally {
      if (mounted) setState(() => _selectionBusy = false);
    }
  }

  Future<void> _createNote() async {
    try {
      final Note note = await widget.controller.createNote();
      if (!mounted) return;
      await _openEditor(note);
    } on Object {
      _message(
        'Could not create a new note. Your existing notes were not changed.',
      );
    }
  }

  Future<void> _openEditor(Note note) async {
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => NoteEditorPage(
            noteId: note.id,
            repository: widget.repository,
            files: widget.files,
          ),
        ),
      );
      if (mounted) await widget.controller.load(showLoading: false);
    } on Object {
      _message('Could not open this note. Try again.');
    }
  }

  Future<void> _trashWithUndo(Note note) async {
    try {
      await widget.controller.trash(note);
    } on Object {
      _message('Could not move this note to trash.');
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note moved to trash.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            unawaited(_undoTrash(note));
          },
        ),
      ),
    );
  }

  Future<void> _undoTrash(Note note) async {
    await _runNoteAction(
      () => widget.controller.restore(note),
      failureMessage: 'Could not undo the trash action.',
    );
  }

  Future<void> _importMarkdown() async {
    try {
      final Note? note = await widget.files.importMarkdown();
      if (note == null || !mounted) return;
      await widget.controller.load(showLoading: false);
      if (mounted) await _openEditor(note);
    } on Object {
      _message('Import failed. The selected file was not changed.');
    }
  }

  Future<void> _emptyTrash() async {
    final bool confirmed = await _confirm(
      title: 'Empty trash?',
      message: 'This permanently deletes every note currently in trash.',
    );
    if (!confirmed) return;
    try {
      final int count = await widget.controller.emptyTrash();
      _message('Permanently deleted $count notes.');
    } on Object {
      _message('Could not empty trash. Some notes may still be present.');
    }
  }

  Future<void> _deleteForever(Note note) async {
    final bool confirmed = await _confirm(
      title: 'Delete permanently?',
      message: 'This note and its version history cannot be recovered.',
    );
    if (!confirmed) return;
    await _runNoteAction(
      () => widget.controller.permanentlyDelete(note),
      failureMessage: 'Could not permanently delete this note.',
    );
  }

  Future<void> _runNoteAction(
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    try {
      await action();
    } on Object {
      _message(failureMessage);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller});

  final NotesController controller;

  @override
  Widget build(BuildContext context) {
    final List<String> folders = controller.folders.toList()..sort();
    final List<String> tags = controller.tags.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text(controller.filter.folder ?? 'All folders'),
            selected: controller.filter.folder != null,
            onSelected: (_) => _showFilterMenu(
              context,
              title: 'Folder',
              values: folders,
              selected: controller.filter.folder,
              onSelected: controller.setFolder,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(
              controller.filter.tag == null
                  ? 'All tags'
                  : '#${controller.filter.tag}',
            ),
            selected: controller.filter.tag != null,
            onSelected: (_) => _showFilterMenu(
              context,
              title: 'Tag',
              values: tags,
              selected: controller.filter.tag,
              onSelected: controller.setTag,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.sort_rounded),
            label: Text(_sortLabel(controller.filter.sort)),
            onPressed: () => _showSortMenu(context),
          ),
          if (controller.filter.folder != null || controller.filter.tag != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: () {
                  controller.setFolder(null);
                  controller.setTag(null);
                },
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear filters'),
              ),
            ),
        ],
      ),
    );
  }

  String _sortLabel(NoteSort sort) {
    return switch (sort) {
      NoteSort.updatedNewest => 'Newest first',
      NoteSort.updatedOldest => 'Oldest first',
      NoteSort.titleAscending => 'Title A–Z',
      NoteSort.titleDescending => 'Title Z–A',
    };
  }

  Future<void> _showSortMenu(BuildContext context) async {
    final NoteSort? value = await showModalBottomSheet<NoteSort>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final NoteSort sort in NoteSort.values)
              ListTile(
                leading: controller.filter.sort == sort
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                title: Text(_sortLabel(sort)),
                onTap: () => Navigator.pop(context, sort),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || value == null) return;
    controller.setSort(value);
  }

  Future<void> _showFilterMenu(
    BuildContext context, {
    required String title,
    required List<String> values,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    final String? value = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            ListTile(
              title: Text('All ${title.toLowerCase()}s'),
              leading: selected == null
                  ? const Icon(Icons.check_rounded)
                  : const SizedBox(width: 24),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final String item in values)
              ListTile(
                title: Text(item),
                leading: selected == item
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || value == null) return;
    onSelected(value.isEmpty ? null : value);
  }
}
