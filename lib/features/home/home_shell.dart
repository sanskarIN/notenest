import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/app/app_dependencies.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/theme/app_tokens.dart';
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

  static const NavigationDestination _moreDestination = NavigationDestination(
    icon: Icon(Icons.more_horiz_rounded),
    label: AppStrings.more,
  );

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useRail =
            constraints.maxWidth >= AppTokens.compactNavigationBreakpoint;
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
                      extended: constraints.maxWidth >=
                          AppTokens.extendedNavigationBreakpoint,
                      labelType: constraints.maxWidth >=
                              AppTokens.extendedNavigationBreakpoint
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.selected,
                      destinations: _destinations
                          .map(
                            (NavigationDestination item) =>
                                NavigationRailDestination(
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
          bottomNavigationBar: useRail ? null : _compactNavigation(),
        );
      },
    );
  }

  Widget _compactNavigation() {
    return NavigationBar(
      selectedIndex: _index <= 3 ? _index : 4,
      onDestinationSelected: (int value) {
        if (value == 4) {
          unawaited(_showMoreDestinations());
          return;
        }
        _select(value);
      },
      destinations: <NavigationDestination>[
        ..._destinations.take(4),
        _moreDestination,
      ],
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
        onOpenAbout: () => _select(5),
      );
    }
    return const AboutPage();
  }

  Future<void> _showMoreDestinations() async {
    final int? destination = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text(AppStrings.settings),
              selected: _index == 4,
              onTap: () => Navigator.pop(context, 4),
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text(AppStrings.about),
              selected: _index == 5,
              onTap: () => Navigator.pop(context, 5),
            ),
            const SizedBox(height: AppTokens.space8),
          ],
        ),
      ),
    );
    if (!mounted || destination == null) return;
    _select(destination);
  }

  Future<void> _createNote() async {
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
