import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:path/path.dart' as p;

final class FileTransferService {
  FileTransferService({
    required BackupRepository backups,
    required NoteRepository notes,
  })  : _backups = backups,
        _notes = notes;

  final BackupRepository _backups;
  final NoteRepository _notes;

  Future<bool> exportBackup() async {
    final String payload = await _backups.exportJson();
    final String? result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export NoteNest backup',
      fileName: 'notenest-backup-${_dateStamp()}.json',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
    return result != null;
  }

  Future<RestoreReport?> importBackup() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Restore NoteNest backup',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );
    if (result == null) return null;
    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const ImportExportException('Could not read the selected backup.');
    }
    return _backups.restoreJson(utf8.decode(bytes, allowMalformed: false));
  }

  Future<bool> exportMarkdown(Note note) async {
    final String tags = _notes.decodeTags(note.tags).join(', ');
    final String frontMatter = '''---\ntitle: ${_yamlValue(note.title)}\nfolder: ${_yamlValue(note.folder)}\ntags: ${_yamlValue(tags)}\nupdated: ${note.updatedAt.toUtc().toIso8601String()}\n---\n\n''';
    final String payload = '$frontMatter${note.body}';
    final String fileName = '${_safeFileName(note.title)}.md';
    final String? result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export note as Markdown',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>['md'],
      bytes: Uint8List.fromList(utf8.encode(payload)),
    );
    return result != null;
  }

  Future<Note?> importMarkdown() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Markdown note',
      type: FileType.custom,
      allowedExtensions: <String>['md', 'markdown', 'txt'],
      withData: true,
    );
    if (result == null) return null;
    final PlatformFile file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      throw const ImportExportException('Could not read the selected note.');
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw ImportExportException('The selected note is not valid UTF-8.', error);
    }
    return _notes.create(
      title: p.basenameWithoutExtension(file.name),
      body: text,
    );
  }

  String _dateStamp() {
    final DateTime now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _safeFileName(String value) {
    final String cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'untitled-note';
    return cleaned.length <= 80 ? cleaned : cleaned.substring(0, 80).trimRight();
  }

  String _yamlValue(String value) =>
      '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
}
