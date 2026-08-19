import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/app/app_dependencies.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/domain/models/note_filter.dart';
import 'package:notenest/features/about/about_page.dart';
import 'package:notenest/features/notes/note_editor_page.dart';
import 'package:notenest/features/notes/notes_controller.dart';
import 'package:notenest/features/notes/notes_page.dart';
import 'package:notenest/features/settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final NotesController _notes = NotesController(
    widget.dependencies.notes,
    logger: widget.dependencies.logger,
  );
  int _index = 0;

  static const List<NavigationDestination> _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.notes_rounded), label: AppStrings.allNotes),
    NavigationDestination(
      icon: Icon(Icons.star_outline_rounded),
      selectedIcon: Icon(Icons.star_rounded),
      label: AppStrings.favorites,
    ),
    NavigationDestination(
      icon: Icon(Icons.archive_outlined),
      selectedIcon: Icon(Icons.archive_rounded),
      label: AppStrings.archive,
    ),
    NavigationDestination(
      icon: Icon(Icons.delete_outline_rounded),
      selectedIcon: Icon(Icons.delete_rounded),
      label: AppStrings.trash,
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: AppStrings.settings,
    ),
    NavigationDestination(
      icon: Icon(Icons.info_outline_rounded),
      selectedIcon: Icon(Icons.info_rounded),
      label: AppStrings.about,
    ),
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useRail = constraints.maxWidth >= 760;
        final Widget content = _content();
        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[_index].label),
            centerTitle: false,
          ),
          body: useRail
              ? Row(
                  children: <Widget>[
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      extended: constraints.maxWidth >= 1120,
                      labelType: constraints.maxWidth >= 1120
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.selected,
                      destinations: _destinations
                          .map(
                            (NavigationDestination item) => NavigationRailDestination(
                              icon: item.icon,
                              selectedIcon: item.selectedIcon,
                              label: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          floatingActionButton: _index == 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    unawaited(_createNote());
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.newNote),
                )
              : null,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: _destinations,
                ),
        );
      },
    );
  }

  Widget _content() {
    if (_index <= 3) {
      return NotesPage(
        controller: _notes,
        repository: widget.dependencies.notes,
        files: widget.dependencies.files,
      );
    }
    if (_index == 4) {
      return SettingsPage(
        settings: widget.dependencies.settings,
        files: widget.dependencies.files,
        appLock: widget.dependencies.appLock,
        externalLinks: widget.dependencies.externalLinks,
        onOpenAbout: () => _select(5),
      );
    }
    return AboutPage(externalLinks: widget.dependencies.externalLinks);
  }

  Future<void> _createNote() async {
    try {
      final Note note = await _notes.createNote();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => NoteEditorPage(
            noteId: note.id,
            repository: widget.dependencies.notes,
            files: widget.dependencies.files,
          ),
        ),
      );
      if (mounted) await _notes.load(showLoading: false);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not create or open a new note. Existing notes were not changed.',
          ),
        ),
      );
    }
  }

  void _select(int value) {
    setState(() => _index = value);
    final NoteCollection? collection = switch (value) {
      0 => NoteCollection.all,
      1 => NoteCollection.favorites,
      2 => NoteCollection.archive,
      3 => NoteCollection.trash,
      _ => null,
    };
    if (collection != null) _notes.setCollection(collection);
  }
}
