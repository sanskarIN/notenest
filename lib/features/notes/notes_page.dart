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
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Import Markdown',
                onPressed: _importMarkdown,
                icon: const Icon(Icons.file_open_rounded),
              ),
              if (controller.filter.collection == NoteCollection.trash) ...<Widget>[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Empty trash',
                  onPressed: controller.notes.isEmpty ? null : _emptyTrash,
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
        title: 'Could not load notes',
        message: 'Your notes remain on this device. Try loading them again.',
        action: FilledButton.icon(
          onPressed: controller.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }
    if (controller.notes.isEmpty) {
      return EmptyState(
        icon: Icons.note_add_outlined,
        title: AppStrings.emptyTitle,
        message: AppStrings.emptyBody,
        action: controller.filter.collection == NoteCollection.trash
            ? null
            : FilledButton.icon(
                onPressed: _createNote,
                icon: const Icon(Icons.add_rounded),
                label: const Text(AppStrings.newNote),
              ),
      );
    }

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
                onOpen: () => _openEditor(note),
                onFavorite: () => controller.setFavorite(
                  note,
                  value: !note.isFavorite,
                ),
                onPin: () => controller.setPinned(note, value: !note.isPinned),
                onArchive: () => note.isArchived
                    ? controller.unarchive(note)
                    : controller.archive(note),
                onTrash: () => controller.trash(note),
                onRestore: () => controller.restore(note),
                onDeleteForever: () => _deleteForever(note),
              );
            },
          );
        },
      ),
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

  Future<void> _importMarkdown() async {
    try {
      final Note? note = await widget.files.importMarkdown();
      if (note == null || !mounted) return;
      await widget.controller.load(showLoading: false);
      if (mounted) await _openEditor(note);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final bool confirmed = await _confirm(
      title: 'Empty trash?',
      message: 'This permanently deletes every note currently in trash.',
    );
    if (!confirmed) return;
    final int count = await widget.controller.emptyTrash();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permanently deleted $count notes.')),
    );
  }

  Future<void> _deleteForever(Note note) async {
    final bool confirmed = await _confirm(
      title: 'Delete permanently?',
      message: 'This note and its version history cannot be recovered.',
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
            label: Text(controller.filter.tag == null
                ? 'All tags'
                : '#${controller.filter.tag}'),
            selected: controller.filter.tag != null,
            onSelected: (_) => _showFilterMenu(
              context,
              title: 'Tag',
              values: tags,
              selected: controller.filter.tag,
              onSelected: controller.setTag,
            ),
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
