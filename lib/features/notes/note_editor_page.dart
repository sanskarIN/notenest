import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/core/utils/async_serial_queue.dart';
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
  _SaveState _saveState = _SaveState.idle;
  bool _loading = true;
  bool _distractionFree = false;
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
      unawaited(_save());
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
    if (_note != null) {
      unawaited(_save());
    }
    _title.dispose();
    _body.dispose();
    _folder.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
    setState(() => _loading = false);
  }

  void _changed() {
    if (_loading) return;
    setState(() => _saveState = _SaveState.idle);
    _autosave.run(_save);
  }

  Future<void> _save() {
    if (_note == null) return Future<void>.value();
    final _EditorDraft draft = _captureDraft();
    return _saveQueue.add(() => _persistDraft(draft));
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

  Future<void> _persistDraft(_EditorDraft draft) async {
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
      if (!mounted) return;
      _note = savedNote;
      setState(
        () => _saveState =
            _matchesCurrentDraft(draft) ? _SaveState.saved : _SaveState.idle,
      );
    } on Object {
      if (!mounted) return;
      setState(
        () => _saveState =
            _matchesCurrentDraft(draft) ? _SaveState.failed : _SaveState.idle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _title,
          maxLines: 1,
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
            onPressed: () => setState(() => _distractionFree = !_distractionFree),
            icon: Icon(
              _distractionFree
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Note actions',
            onSelected: _handleMenu,
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.maxEditorWidth),
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
                  _colorSwatch(context, swatch),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch(
    BuildContext context,
    ({Color? color, String label}) swatch,
  ) {
    final Color? color = swatch.color;
    final bool selected = _colorValue == color?.toARGB32();
    final String label =
        '${swatch.label} note color${selected ? ', selected' : ''}';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() => _colorValue = color?.toARGB32());
            _autosave.run(_save);
          },
          child: SizedBox.square(
            dimension: AppTokens.minimumTouchTarget,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color ?? Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    width: selected ? 3 : 1,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : color == null
                        ? const Icon(Icons.format_color_reset_rounded, size: 17)
                        : null,
              ),
            ),
          ),
        ),
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
        _body.text.lastIndexOf('\n', caret == 0 ? 0 : caret - 1) + 1;
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
        await _save();
        if (_note != null) await widget.files.exportMarkdown(_note!);
        break;
    }
  }

  Future<void> _showVersions() async {
    await _save();
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
                      onPressed: () async {
                        await widget.repository.restoreVersion(version.id);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await _reloadFromDatabase();
                      },
                      child: const Text('Restore'),
                    ),
                  );
                },
              ),
      ),
    );
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
