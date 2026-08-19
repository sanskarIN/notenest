abstract final class AppStrings {
  static const String appName = 'NoteNest';
  static const String tagline = 'Your thoughts, safely nested.';
  static const String credit = 'Made by the Sanskar';
  static const String version = '1.0.0';
  static const String businessEmail = 'sanskarin@outlook.in';
  static const String secondaryBusinessEmail = 'sanskarin.business@gmail.com';
  static const String supportEmail = 'supportramsandesh@gmail.com';
  static const String githubUrl = 'https://github.com/sanskarIN';
  static const String repositoryUrl = 'https://github.com/sanskarIN/notenest';
  static const String fundingUrl = 'https://buymeacoffee.com/sanskarIN';

  static const String allNotes = 'All notes';
  static const String favorites = 'Favorites';
  static const String archive = 'Archive';
  static const String trash = 'Trash';
  static const String settings = 'Settings';
  static const String about = 'About';
  static const String searchHint = 'Search notes';
  static const String newNote = 'New note';
  static const String emptyTitle = 'No notes here yet';
  static const String emptyBody = 'Create a note or adjust the current filters.';

  static const String appearance = 'Appearance';
  static const String system = 'System';
  static const String light = 'Light';
  static const String dark = 'Dark';
  static const String accessibility = 'Accessibility';
  static const String textSize = 'Text size';
  static const String reduceMotion = 'Reduce motion';
  static const String reduceMotionBody =
      'Prefer fewer non-essential interface animations.';
  static const String privacy = 'Privacy';
  static const String localAppLock = 'Local app lock';
  static const String localAppLockBody =
      'Use device authentication when supported.';
  static const String data = 'Data';
  static const String exportBackup = 'Export backup';
  static const String exportBackupBody =
      'Save notes and version history as validated JSON.';
  static const String restoreBackup = 'Restore backup';
  static const String restoreBackupBody =
      'Merge a NoteNest JSON backup without overwriting newer local notes.';
  static const String updates = 'Updates';
  static const String releaseUpdates = 'Release updates';
  static const String releaseUpdatesBody =
      'Open the official NoteNest GitHub Releases page to review published versions.';
  static const String aboutNoteNest = 'About NoteNest';
  static const String aboutNoteNestBody =
      'Version, license, privacy summary, support, source code, and funding.';

  static const String authUnavailable =
      'Device authentication is not available on this platform or device.';
  static const String authUnavailableTitle =
      'Device authentication unavailable';
  static const String authUnavailableLockBody =
      'Device authentication is unavailable. Disable app lock to continue using your local notes on this device.';
  static const String appLockNotEnabled =
      'App lock was not enabled because authentication did not complete.';
  static const String disableAppLock = 'Disable app lock';
  static const String lockedTitle = 'NoteNest is locked';
  static const String lockedBody =
      'Use your device authentication to access local notes.';
  static const String unlock = 'Unlock';
  static const String unlockReason = 'Unlock NoteNest to access your notes.';

  static const String backupExported = 'Backup exported successfully.';
  static const String backupExportFailed =
      'Backup export failed. Your local notes were not changed.';
  static const String backupRestoreFailed =
      'Backup restore failed. No partial restore was kept.';
  static const String releasesOpenFailed =
      'Could not open the releases page on this device.';
  static const String restoreBackupQuestion = 'Restore backup?';
  static const String restoreBackupWarning =
      'The backup is validated before changes are applied. Newer local notes are preserved.';
  static const String cancel = 'Cancel';
  static const String restore = 'Restore';

  static const String exportBackupDialog = 'Export NoteNest backup';
  static const String restoreBackupDialog = 'Restore NoteNest backup';
  static const String exportMarkdownDialog = 'Export note as Markdown';
  static const String importMarkdownDialog = 'Import Markdown note';

  static String restoreReport({
    required int importedNotes,
    required int importedVersions,
    required int skippedNewerNotes,
  }) =>
      'Restored $importedNotes notes and $importedVersions snapshots; '
      'kept $skippedNewerNotes newer local notes.';
}
