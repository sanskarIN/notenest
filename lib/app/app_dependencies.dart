import 'package:notenest/app/app_settings_controller.dart';
import 'package:notenest/core/logging/app_logger.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/data/repositories/note_repository.dart';
import 'package:notenest/data/repositories/settings_repository.dart';
import 'package:notenest/services/app_lock_service.dart';
import 'package:notenest/services/file_transfer_service.dart';

final class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.notes,
    required this.settings,
    required this.backups,
    required this.files,
    required this.appLock,
    required this.logger,
  });

  final AppDatabase database;
  final NoteRepository notes;
  final AppSettingsController settings;
  final BackupRepository backups;
  final FileTransferService files;
  final AppLockService appLock;
  final AppLogger logger;

  static Future<AppDependencies> create() async {
    const AppLogger logger = AppLogger();
    final AppDatabase database = AppDatabase();
    final NoteRepository notes = NoteRepository(database);
    final SettingsRepository settingsRepository = SettingsRepository();
    final AppSettingsController settings =
        AppSettingsController(settingsRepository);
    final BackupRepository backups = BackupRepository(database);
    final FileTransferService files = FileTransferService(
      backups: backups,
      notes: notes,
    );
    await settings.load();
    logger.info('app.dependencies_ready');
    return AppDependencies._(
      database: database,
      notes: notes,
      settings: settings,
      backups: backups,
      files: files,
      appLock: AppLockService(),
      logger: logger,
    );
  }

  Future<void> dispose() async {
    settings.dispose();
    await database.close();
    logger.info('app.dependencies_disposed');
  }
}
