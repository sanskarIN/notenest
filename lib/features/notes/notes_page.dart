import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/theme/app_tokens.dart';
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final NotesController controller = widget.controller;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space16,
            AppTokens.space8,
          ),
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
                        tooltip: AppStrings.clearSearch,
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
              if (controller.filter.collection == NoteCollection.all) ...<Widget>[
                const SizedBox(width: AppTokens.space8),
                IconButton.filledTonal(
                  tooltip: AppStrings.importMarkdown,
                  onPressed: () {
                    unawaited(_importMarkdown());
                  },
                  icon: const Icon(Icons.file_open_rounded),
                ),
              ],
              if (controller.filter.collection == NoteCollection.trash) ...<Widget>[
                const SizedBox(width: AppTokens.space8),
                IconButton.filledTonal(
                  tooltip: AppStrings.emptyTrash,
                  onPressed: controller.notes.isEmpty
                      ? null
                      : () {
                          unawaited(_emptyTrash());
                        },
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
              ],
            ],
          ),
        ),
        _FilterRow(controller: controller),
        Expanded(child: _body(controller)),
      ],
    );
  }

  Widget _body(NotesController controller) {
    if (controller.loading && controller.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.notes.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: AppStrings.loadFailedTitle,
        message: AppStrings.loadFailedBody,
        action: FilledButton.icon(
          onPressed: () {
            unawaited(controller.load());
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(AppStrings.retry),
        ),
      );
    }
    if (controller.notes.isEmpty) {
      return _collectionEmptyState(controller.filter.collection);
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = switch (constraints.maxWidth) {
            >= AppTokens.gridFourColumnBreakpoint => 4,
            >= AppTokens.gridThreeColumnBreakpoint => 3,
            >= AppTokens.gridTwoColumnBreakpoint => 2,
            _ => 1,
          };
          return GridView.builder(
            padding: AppTokens.pagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppTokens.space12,
              mainAxisSpacing: AppTokens.space12,
              mainAxisExtent: columns == 1
                  ? AppTokens.compactNoteCardExtent
                  : AppTokens.regularNoteCardExtent,
            ),
            itemCount: controller.notes.length,
            itemBuilder: (BuildContext context, int index) {
              final Note note = controller.notes[index];
              return NoteCard(
                note: note,
                onOpen: () {
                  unawaited(_openEditor(note));
                },
                onFavorite: () {
                  unawaited(
                    controller.setFavorite(note, value: !note.isFavorite),
                  );
                },
                onPin: () {
                  unawaited(controller.setPinned(note, value: !note.isPinned));
                },
                onArchive: () {
                  unawaited(
                    note.isArchived
                        ? controller.unarchive(note)
                        : controller.archive(note),
                  );
                },
                onTrash: () {
                  unawaited(_trashWithUndo(note));
                },
                onRestore: () {
                  unawaited(controller.restore(note));
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
              onPressed: () {
                unawaited(_createNote());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.newNote),
            )
          : null,
    );
  }

  Future<void> _createNote() async {
    final Note note = await widget.controller.createNote();
    if (!mounted) return;
    await _openEditor(note);
  }

  Future<void> _openEditor(Note note) async {
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
  }

  Future<void> _trashWithUndo(Note note) async {
    await widget.controller.trash(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.noteMovedToTrash),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            unawaited(widget.controller.restore(note));
          },
        ),
      ),
    );
  }

  Future<void> _importMarkdown() async {
    try {
      final Note? note = await widget.files.importMarkdown();
      if (note == null || !mounted) return;
      await widget.controller.load(showLoading: false);
      if (mounted) await _openEditor(note);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.importFailedSafe)),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final bool confirmed = await _confirm(
      title: AppStrings.emptyTrashQuestion,
      message: AppStrings.emptyTrashWarning,
    );
    if (!confirmed) return;
    final int count = await widget.controller.emptyTrash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.permanentlyDeletedNotes(count))),
    );
  }

  Future<void> _deleteForever(Note note) async {
    final bool confirmed = await _confirm(
      title: AppStrings.deletePermanentlyQuestion,
      message: AppStrings.deletePermanentlyWarning,
    );
    if (confirmed) await widget.controller.permanentlyDelete(note);
  }

  Future<bool> _confirm({required String title, required String message}) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(AppStrings.continueLabel),
              ),
            ],
          ),
        ) ??
        false;
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text(controller.filter.folder ?? AppStrings.allFolders),
            selected: controller.filter.folder != null,
            onSelected: (_) {
              unawaited(
                _showFilterMenu(
                  context,
                  title: AppStrings.folder,
                  values: folders,
                  selected: controller.filter.folder,
                  onSelected: controller.setFolder,
                ),
              );
            },
          ),
          const SizedBox(width: AppTokens.space8),
          FilterChip(
            label: Text(
              controller.filter.tag == null
                  ? AppStrings.allTags
                  : '#${controller.filter.tag}',
            ),
            selected: controller.filter.tag != null,
            onSelected: (_) {
              unawaited(
                _showFilterMenu(
                  context,
                  title: AppStrings.tag,
                  values: tags,
                  selected: controller.filter.tag,
                  onSelected: controller.setTag,
                ),
              );
            },
          ),
          if (controller.filter.folder != null || controller.filter.tag != null)
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.space8),
              child: TextButton.icon(
                onPressed: () {
                  controller.setFolder(null);
                  controller.setTag(null);
                },
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text(AppStrings.clearFilters),
              ),
            ),
        ],
      ),
    );
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
              title: Text(AppStrings.allFilterValues(title)),
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
