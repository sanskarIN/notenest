import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notenest/core/utils/markdown_lite.dart';
import 'package:notenest/data/database/app_database.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    required this.onOpen,
    required this.onFavorite,
    required this.onPin,
    required this.onArchive,
    required this.onTrash,
    required this.onRestore,
    required this.onDeleteForever,
    super.key,
  });

  final Note note;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onTrash;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = note.colorValue == null
        ? colors.surfaceContainerLow
        : Color(note.colorValue!).withValues(alpha: 0.22);
    final String preview = MarkdownLite.plainPreview(note.body);

    return Semantics(
      button: true,
      label: note.title.trim().isEmpty ? 'Untitled note' : note.title,
      child: Card(
        color: background,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (note.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin_rounded, size: 18),
                      ),
                    Expanded(
                      child: Text(
                        note.title.trim().isEmpty ? 'Untitled' : note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: note.isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onPressed: onFavorite,
                      icon: Icon(
                        note.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More actions',
                      onSelected: (String action) {
                        switch (action) {
                          case 'pin':
                            onPin();
                            break;
                          case 'archive':
                            onArchive();
                            break;
                          case 'trash':
                            onTrash();
                            break;
                          case 'restore':
                            onRestore();
                            break;
                          case 'delete':
                            onDeleteForever();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            if (!note.isTrashed)
                              PopupMenuItem<String>(
                                value: 'pin',
                                child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                              ),
                            if (!note.isTrashed)
                              PopupMenuItem<String>(
                                value: 'archive',
                                child: Text(
                                  note.isArchived ? 'Unarchive' : 'Archive',
                                ),
                              ),
                            if (!note.isTrashed)
                              const PopupMenuItem<String>(
                                value: 'trash',
                                child: Text('Move to trash'),
                              ),
                            if (note.isTrashed)
                              const PopupMenuItem<String>(
                                value: 'restore',
                                child: Text('Restore'),
                              ),
                            if (note.isTrashed)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete permanently'),
                              ),
                          ],
                    ),
                  ],
                ),
                if (preview.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(preview, maxLines: 6, overflow: TextOverflow.ellipsis),
                ],
                const Spacer(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (note.folder.isNotEmpty)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(note.folder),
                      ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        note.updatedAt.toLocal(),
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
