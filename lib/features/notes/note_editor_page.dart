import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/core/utils/debouncer.dart';
import 'package:notenest/core/utils/markdown_lite.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/services/file_transfer_service.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    required this.noteId,
    required this.repository,
    required this.files,
    super.key,
  });

  final String noteId;
  final NoteRepository repository;
  final FileTransferService files;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

enum _SaveState { idle, saving, saved, failed }

class _NoteEditorPageState extends State<NoteEditorPage>
    with WidgetsBindingObserver {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _folder = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final Debouncer _autosave = Debouncer(AppTokens.autosaveDebounce);

  Note? _note;
  _SaveState _saveState = _SaveState.idle;
  bool _loading = true;
  bool _loadFailed = false;
  bool _distractionFree = false;
  bool _disposed = false;
  int? _colorValue;
  int _saveGeneration = 0;
  Future<void> _saveTail = Future<void>.value();

  static const List<Color?> _palette = <Color?>[
    null,
    Color(0xFFFFD7D7),
    Color(0xFFFFE7B3),
    Color(0xFFD9F2D9),
    Color(0xFFD8EBFF),
    Color(0xFFE8DBFF),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_save(force: true));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _autosave.dispose();
    _title.removeListener(_changed);
    _body.removeListener(_changed);
    _folder.removeListener(_changed);
    _tags.removeListener(_changed);
    unawaited(_save(force: true));
    _title.dispose();
    _body.dispose();
    _folder.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Note note = await widget.repository.getById(widget.noteId);
      if (!mounted) return;
      _note = note;
      _title.text = note.title;
      _body.text = note.body;
      _folder.text = note.folder;
      _tags.text = widget.repository.decodeTags(note.tags).join(', ');
      _colorValue = note.colorValue;
      _title.addListener(_changed);
      _body.addListener(_changed);
      _folder.addListener(_changed);
      _tags.addListener(_changed);
      setState(() {
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _retryLoad() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await _load();
  }

  void _changed() {
    if (_loading || _disposed) return;
    setState(() => _saveState = _SaveState.idle);
    _autosave.run(() {
      unawaited(_save());
    });
  }

  Future<void> _save({bool force = false}) {
    if (_note == null || (!force && _disposed)) {
      return Future<void>.value();
    }

    final int generation = ++_saveGeneration;
    final String title = _title.text;
    final String body = _body.text;
    final String folder = _folder.text;
    final List<String> tags = _parseTags(_tags.text);
    final int? colorValue = _colorValue;

    if (!_disposed && mounted) {
      setState(() => _saveState = _SaveState.saving);
    }

    final Future<void> operation = _saveTail.then((_) async {
      try {
        await widget.repository.saveContent(
          id: widget.noteId,
          title: title,
          body: body,
          folder: folder,
          tags: tags,
          colorValue: colorValue,
        );
        if (_disposed) return;
        final Note refreshed = await widget.repository.getById(widget.noteId);
        _note = refreshed;
        if (mounted && generation == _saveGeneration) {
          setState(() => _saveState = _SaveState.saved);
        }
      } on Object {
        if (!_disposed && mounted && generation == _saveGeneration) {
          setState(() => _saveState = _SaveState.failed);
        }
      }
    });
    _saveTail = operation;
    return operation;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: AppTokens.space16),
                Text(
                  AppStrings.noteLoadFailedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space8),
                const Text(
                  AppStrings.noteLoadFailedBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space16),
                FilledButton.icon(
                  onPressed: () {
                    unawaited(_retryLoad());
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _title,
          maxLines: 1,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(
            hintText: AppStrings.untitledNote,
            filled: false,
            border: InputBorder.none,
          ),
        ),
        actions: <Widget>[
          _SaveIndicator(state: _saveState),
          IconButton(
            tooltip: _distractionFree
                ? AppStrings.showEditorControls
                : AppStrings.distractionFree,
            onPressed: () => setState(() => _distractionFree = !_distractionFree),
            icon: Icon(
              _distractionFree
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: AppStrings.noteActions,
            onSelected: (String action) {
              unawaited(_handleMenu(action));
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'versions',
                child: Text(AppStrings.versionHistory),
              ),
              PopupMenuItem<String>(
                value: 'export',
                child: Text(AppStrings.exportMarkdown),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: <Widget>[
                if (!_distractionFree) _metadata(),
                if (!_distractionFree) _formatToolbar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: TextField(
                      controller: _body,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: AppStrings.editorHint,
                        filled: false,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metadata() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _folder,
                  decoration: const InputDecoration(
                    labelText: AppStrings.folder,
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: AppStrings.tags,
                    hintText: AppStrings.tagsHint,
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                for (final Color? color in _palette)
                  Tooltip(
                    message: color == null
                        ? AppStrings.defaultColor
                        : AppStrings.noteColor,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        setState(() => _colorValue = color?.toARGB32());
                        _autosave.run(() {
                          unawaited(_save());
                        });
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color ?? Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            width: _colorValue == color?.toARGB32() ? 3 : 1,
                            color: _colorValue == color?.toARGB32()
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: color == null
                            ? const Icon(Icons.format_color_reset_rounded, size: 17)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: AppStrings.heading,
            onPressed: () => _prefixCurrentLine('## '),
            icon: const Icon(Icons.title_rounded),
          ),
          IconButton(
            tooltip: AppStrings.bold,
            onPressed: () => _wrapSelection('**'),
            icon: const Icon(Icons.format_bold_rounded),
          ),
          IconButton(
            tooltip: AppStrings.italic,
            onPressed: () => _wrapSelection('_'),
            icon: const Icon(Icons.format_italic_rounded),
          ),
          IconButton(
            tooltip: AppStrings.bulletList,
            onPressed: () => _prefixCurrentLine('- '),
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
          IconButton(
            tooltip: AppStrings.checklistItem,
            onPressed: () => _prefixCurrentLine('- [ ] '),
            icon: const Icon(Icons.checklist_rounded),
          ),
        ],
      ),
    );
  }

  void _wrapSelection(String marker) {
    final TextSelection selection = _body.selection;
    final int start = selection.isValid ? selection.start : _body.text.length;
    final int end = selection.isValid ? selection.end : start;
    final String selected = _body.text.substring(start, end);
    _body.value = TextEditingValue(
      text: _body.text.replaceRange(start, end, '$marker$selected$marker'),
      selection: TextSelection.collapsed(offset: end + marker.length * 2),
    );
  }

  void _prefixCurrentLine(String prefix) {
    final int caret = _body.selection.isValid
        ? _body.selection.baseOffset.clamp(0, _body.text.length).toInt()
        : _body.text.length;
    final int lineStart = caret == 0
        ? 0
        : _body.text.lastIndexOf('\n', caret - 1) + 1;
    final int lineEndCandidate = _body.text.indexOf('\n', caret);
    final int lineEnd =
        lineEndCandidate == -1 ? _body.text.length : lineEndCandidate;
    final String line = _body.text.substring(lineStart, lineEnd);
    final String replacement = MarkdownLite.togglePrefix(line, prefix);
    final int nextCaret = (lineStart + replacement.length)
        .clamp(0, _body.text.length - line.length + replacement.length)
        .toInt();
    _body.value = TextEditingValue(
      text: _body.text.replaceRange(lineStart, lineEnd, replacement),
      selection: TextSelection.collapsed(offset: nextCaret),
    );
  }

  Future<void> _handleMenu(String action) async {
    switch (action) {
      case 'versions':
        await _showVersions();
        break;
      case 'export':
        await _exportMarkdown();
        break;
    }
  }

  Future<void> _exportMarkdown() async {
    try {
      await _save(force: true);
      final Note note = await widget.repository.getById(widget.noteId);
      final bool saved = await widget.files.exportMarkdown(note);
      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.markdownExported)),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.markdownExportFailed)),
      );
    }
  }

  Future<void> _showVersions() async {
    await _save(force: true);
    final List<NoteVersion> versions =
        await widget.repository.versions(widget.noteId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: versions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text(AppStrings.noSnapshots)),
              )
            : ListView.builder(
                itemCount: versions.length,
                itemBuilder: (BuildContext context, int index) {
                  final NoteVersion version = versions[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(
                      version.title.isEmpty ? AppStrings.untitled : version.title,
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(version.capturedAt.toLocal()),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        unawaited(_restoreVersion(version.id));
                      },
                      child: const Text(AppStrings.restore),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _restoreVersion(int versionId) async {
    await widget.repository.restoreVersion(versionId);
    await _reloadFromDatabase();
  }

  Future<void> _reloadFromDatabase() async {
    final Note note = await widget.repository.getById(widget.noteId);
    if (!mounted) return;
    setState(() {
      _note = note;
      _title.text = note.title;
      _body.text = note.body;
      _folder.text = note.folder;
      _tags.text = widget.repository.decodeTags(note.tags).join(', ');
      _colorValue = note.colorValue;
      _saveState = _SaveState.saved;
    });
  }

  List<String> _parseTags(String value) => value
      .split(',')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false)
    ..sort();
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.state});

  final _SaveState state;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (state) {
      _SaveState.idle => (Icons.edit_rounded, AppStrings.editing),
      _SaveState.saving => (Icons.sync_rounded, AppStrings.saving),
      _SaveState.saved => (Icons.cloud_done_outlined, AppStrings.savedLocally),
      _SaveState.failed => (Icons.error_outline_rounded, AppStrings.saveFailed),
    };
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
