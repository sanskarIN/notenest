import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/core/utils/bounded_file_reader.dart';
import 'package:notenest/core/utils/import_limits.dart';
import 'package:notenest/core/utils/markdown_document_codec.dart';
import 'package:notenest/core/utils/safe_file_name.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:path/path.dart' as p;

final class FileTransferService {
  FileTransferService({
    required BackupRepository backups,
    required NoteRepository notes,
  }) : _backups = backups,
       _notes = notes;

  final BackupRepository _backups;
  final NoteRepository _notes;

  Future<bool> exportBackup() async {
    final String payload = await _backups.exportJson();
    final Uri? result = await FilePicker.saveFile(
      dialogTitle: 'Export NoteNest backup',
      fileName: 'notenest-backup-${_dateStamp()}.json',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      bytes: Uint8List.fromList(utf8.encode(payload)),
      mimeType: 'application/json',
    );
    return result != null;
  }

  Future<RestoreReport?> importBackup() async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Restore NoteNest backup',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (file == null) return null;
    final Uint8List bytes = await _readPickedFile(
      file,
      validateLength: ImportLimits.validateBackupBytes,
      failureMessage: 'Could not read the selected backup.',
    );
    try {
      return await _backups.restoreJson(
        utf8.decode(bytes, allowMalformed: false),
      );
    } on FormatException catch (error) {
      throw ImportExportException(
        'The selected backup is not valid UTF-8.',
        error,
      );
    }
  }

  Future<bool> exportMarkdown(Note note) async {
    final String payload = MarkdownDocumentCodec.encode(
      title: note.title,
      body: note.body,
      folder: note.folder,
      tags: _notes.decodeTags(note.tags),
      updatedAt: note.updatedAt,
    );
    final String fileName = '${SafeFileName.fromTitle(note.title)}.md';
    final Uri? result = await FilePicker.saveFile(
      dialogTitle: 'Export note as Markdown',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>['md'],
      bytes: Uint8List.fromList(utf8.encode(payload)),
      mimeType: 'text/markdown',
    );
    return result != null;
  }

  Future<Note?> importMarkdown() async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Import Markdown note',
      type: FileType.custom,
      allowedExtensions: <String>['md', 'markdown', 'txt'],
    );
    if (file == null) return null;
    final Uint8List bytes = await _readPickedFile(
      file,
      validateLength: ImportLimits.validateMarkdownBytes,
      failureMessage: 'Could not read the selected note.',
    );
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw ImportExportException(
        'The selected note is not valid UTF-8.',
        error,
      );
    }
    final MarkdownDocument document = MarkdownDocumentCodec.decode(
      text,
      fallbackTitle: p.basenameWithoutExtension(file.name),
    );
    return _notes.create(
      title: document.title,
      body: document.body,
      folder: document.folder,
      tags: document.tags,
    );
  }

  Future<Uint8List> _readPickedFile(
    PlatformFile file, {
    required void Function(int byteLength) validateLength,
    required String failureMessage,
  }) async {
    try {
      validateLength(await file.length());

      final String? path = file.path;
      if (path != null && path.trim().isNotEmpty) {
        return BoundedFileReader.read(path, validateLength: validateLength);
      }

      final BytesBuilder builder = BytesBuilder(copy: false);
      int total = 0;
      await for (final Uint8List chunk in file.readAsByteStream()) {
        total += chunk.length;
        validateLength(total);
        builder.add(chunk);
      }
      validateLength(total);
      return builder.takeBytes();
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw ImportExportException(failureMessage, error);
    }
  }

  String _dateStamp() {
    final DateTime now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
