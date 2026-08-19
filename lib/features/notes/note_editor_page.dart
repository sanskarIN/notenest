import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/core/utils/async_serial_queue.dart';
import 'package:notenest/core/utils/debouncer.dart';
import 'package:notenest/core/utils/markdown_lite.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/services/file_transfer_service.dart';
import 'package:notenest/widgets/empty_state.dart';
import 'package:notenest/widgets/note_color_swatch.dart';

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

final class _EditorDraft {
  const _EditorDraft({
    required this.title,
    required this.body,
    required this.folder,
    required this.tagsText,
    required this.tags,
    required this.colorValue,
  });

  final String title;
  final String body;
  final String folder;
  final String tagsText;
  final List<String> tags;
  final int? colorValue;
}

class _NoteEditorPageState extends State<NoteEditorPage>
    with WidgetsBindingObserver {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _folder = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final Debouncer _autosave = Debouncer(AppTokens.autosaveDebounce);
  final AsyncSerialQueue _saveQueue = AsyncSerialQueue();

  Note? _note;
  Object? _loadError;
  _SaveState _saveState = _SaveState.idle;
  bool _loading = true;
  bool _distractionFree = false;
  bool _leaving = false;
  bool _allowPop = false;
  int? _colorValue;

  static const List<({Color? color, String label})> _palette =
      <({Color? color, String label})>[
    (label: 'Default', color: null),
    (label: 'Red', color: Color(0xFFFFD7D7)),
    (label: 'Amber', color: Color(0xFFFFE7B3)),
    (label: 'Green', color: Color(0xFFD9F2D9)),
    (label: 'Blue', color: Color(0xFFD8EBFF)),
    (label: 'Purple', color: Color(0xFFE8DBFF)),
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
      _queueBackgroundSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosave.dispose();
    _title.removeListener(_changed);
    _body.removeListener(_changed);
    _folder.removeListener(_changed);
    _tags.removeListener(_changed);
    if (_note != null && !_allowPop) {
      _queueBackgroundSave();
    }
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
        _loadError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _retryLoad() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _load();
  }

  void _changed() {
    if (_loading || _leaving) return;
    setState(() => _saveState = _SaveState.idle);
    _autosave.run(() async {
      await _save();
    });
  }

  void _queueBackgroundSave() {
    unawaited(_save().then<void>((_) {}));
  }

  Future<bool> _save() {
    if (_note == null) return Future<bool>.value(false);
    return _enqueueDraft(_captureDraft());
  }

  Future<bool> _enqueueDraft(_EditorDraft draft) {
    return _saveQueue.add<bool>(() => _persistDraft(draft));
  }

  _EditorDraft _captureDraft() {
    final String tagsText = _tags.text;
    return _EditorDraft(
      title: _title.text,
      body: _body.text,
      folder: _folder.text,
      tagsText: tagsText,
      tags: _parseTags(tagsText),
      colorValue: _colorValue,
    );
  }

  bool _matchesCurrentDraft(_EditorDraft draft) {
    return _title.text == draft.title &&
        _body.text == draft.body &&
        _folder.text == draft.folder &&
        _tags.text == draft.tagsText &&
        _colorValue == draft.colorValue;
  }

  Future<bool> _persistDraft(_EditorDraft draft) async {
    if (mounted && _matchesCurrentDraft(draft)) {
      setState(() => _saveState = _SaveState.saving);
    }
    try {
      await widget.repository.saveContent(
        id: widget.noteId,
        title: draft.title,
        body: draft.body,
        folder: draft.folder,
        tags: draft.tags,
        colorValue: draft.colorValue,
      );
      final Note savedNote = await widget.repository.getById(widget.noteId);
      if (mounted) {
        _note = savedNote;
        setState(
          () => _saveState =
              _matchesCurrentDraft(draft) ? _SaveState.saved : _SaveState.idle,
        );
      }
      return true;
    } on Object {
      if (mounted) {
        setState(
          () => _saveState =
              _matchesCurrentDraft(draft) ? _SaveState.failed : _SaveState.idle,
        );
      }
      return false;
    }
  }

  Future<void> _attemptLeave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    final bool saved = await _save();
    if (!mounted) return;
    if (!saved) {
      setState(() => _leaving = false);
      _message('Could not save this note. Resolve the save problem before leaving.');
      return;
    }

    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not open this note',
          message:
              'The note could not be loaded from local storage. You can retry without changing other notes.',
          action: FilledButton.icon(
            onPressed: _retryLoad,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) unawaited(_attemptLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _title,
            maxLines: 1,
            readOnly: _leaving,
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Untitled note',
              filled: false,
              border: InputBorder.none,
            ),
          ),
          actions: <Widget>[
            _SaveIndicator(state: _saveState),
            IconButton(
              tooltip: _distractionFree
                  ? 'Show editor controls'
                  : 'Distraction-free editor',
              onPressed: _leaving
                  ? null
                  : () =>
                      setState(() => _distractionFree = !_distractionFree),
              icon: Icon(
                _distractionFree
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Note actions',
              enabled: !_leaving,
              onSelected: _handleMenu,
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'versions',
                  child: Text('Version history'),
                ),
                PopupMenuItem<String>(
                  value: 'export',
                  child: Text('Export Markdown'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: IgnorePointer(
            ignoring: _leaving,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppTokens.maxEditorWidth),
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
                            hintText: 'Start writing…\n\nMarkdown-lite supported: headings, emphasis, lists, and checklists.',
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
                    labelText: 'Folder',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'school, ideas, todo',
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
              spacing: 4,
              children: <Widget>[
                for (final ({Color? color, String label}) swatch in _palette)
                  NoteColorSwatch(
                    label: swatch.label,
                    color: swatch.color,
                    selected: _colorValue == swatch.color?.toARGB32(),
                    onPressed: () {
                      setState(
                        () => _colorValue = swatch.color?.toARGB32(),
                      );
                      _autosave.run(() async {
                        await _save();
                      });
                    },
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
            tooltip: 'Heading',
            onPressed: () => _prefixCurrentLine('## '),
            icon: const Icon(Icons.title_rounded),
          ),
          IconButton(
            tooltip: 'Bold',
            onPressed: () => _wrapSelection('**'),
            icon: const Icon(Icons.format_bold_rounded),
          ),
          IconButton(
            tooltip: 'Italic',
            onPressed: () => _wrapSelection('_'),
            icon: const Icon(Icons.format_italic_rounded),
          ),
          IconButton(
            tooltip: 'Bullet list',
            onPressed: () => _prefixCurrentLine('- '),
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
          IconButton(
            tooltip: 'Checklist item',
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
    final int lineStart =
        caret == 0 ? 0 : _body.text.lastIndexOf('\n', caret - 1) + 1;
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
    final bool saved = await _save();
    if (!mounted) return;
    if (!saved) {
      _message('Save failed. The requested note action was not started.');
      return;
    }

    try {
      switch (action) {
        case 'versions':
          await _showVersions();
          break;
        case 'export':
          final Note? note = _note;
          if (note == null) return;
          final bool exported = await widget.files.exportMarkdown(note);
          if (exported) _message('Note exported successfully.');
          break;
      }
    } on Object {
      if (mounted) {
        _message('The requested note action could not be completed.');
      }
    }
  }

  Future<void> _showVersions() async {
    final List<NoteVersion> versions =
        await widget.repository.versions(widget.noteId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: versions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No earlier snapshots yet.')),
              )
            : ListView.builder(
                itemCount: versions.length,
                itemBuilder: (BuildContext context, int index) {
                  final NoteVersion version = versions[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(version.title.isEmpty ? 'Untitled' : version.title),
                    subtitle: Text(version.capturedAt.toLocal().toString()),
                    trailing: TextButton(
                      onPressed: () => _restoreVersion(
                        sheetContext,
                        version.id,
                      ),
                      child: const Text('Restore'),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _restoreVersion(BuildContext sheetContext, int versionId) async {
    try {
      await widget.repository.restoreVersion(versionId);
      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      await _reloadFromDatabase();
      if (mounted) _message('Version restored.');
    } on Object {
      if (mounted) {
        _message('Could not restore that version. Your current note was kept.');
      }
    }
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

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _parseTags(String value) => value
      .split(',')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.state});

  final _SaveState state;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label) = switch (state) {
      _SaveState.idle => (Icons.edit_rounded, 'Editing'),
      _SaveState.saving => (Icons.sync_rounded, 'Saving'),
      _SaveState.saved => (Icons.cloud_done_outlined, 'Saved locally'),
      _SaveState.failed => (Icons.error_outline_rounded, 'Save failed'),
    };
    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
