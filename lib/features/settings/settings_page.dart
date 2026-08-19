import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/app/app_settings_controller.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/services/app_lock_service.dart';
import 'package:notenest/services/file_transfer_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.files,
    required this.appLock,
    required this.onOpenAbout,
    super.key,
  });

  final AppSettingsController settings;
  final FileTransferService files;
  final AppLockService appLock;
  final VoidCallback onOpenAbout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_changed);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppSettingsController settings = widget.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(AppStrings.appearance, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded),
              label: Text(AppStrings.system),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded),
              label: Text(AppStrings.light),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded),
              label: Text(AppStrings.dark),
            ),
          ],
          selected: <ThemeMode>{settings.themeMode},
          onSelectionChanged: (Set<ThemeMode> values) {
            unawaited(settings.setThemeMode(values.single));
          },
        ),
        const SizedBox(height: 28),
        Text(
          AppStrings.accessibility,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.textSize),
          subtitle: Slider(
            value: settings.fontScale,
            min: 0.9,
            max: 1.4,
            divisions: 5,
            label: '${(settings.fontScale * 100).round()}%',
            onChanged: (double value) {
              unawaited(settings.setFontScale(value));
            },
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.reduceMotion),
          subtitle: const Text(AppStrings.reduceMotionBody),
          value: settings.reduceMotion,
          onChanged: (bool value) {
            unawaited(settings.setReduceMotion(value: value));
          },
        ),
        const Divider(height: 36),
        Text(AppStrings.privacy, style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.localAppLock),
          subtitle: const Text(AppStrings.localAppLockBody),
          value: settings.appLockEnabled,
          onChanged: _busy
              ? null
              : (bool value) {
                  unawaited(_toggleAppLock(value));
                },
        ),
        const Divider(height: 36),
        Text(AppStrings.data, style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.backup_rounded),
          title: const Text(AppStrings.exportBackup),
          subtitle: const Text(AppStrings.exportBackupBody),
          enabled: !_busy,
          onTap: _busy
              ? null
              : () {
                  unawaited(_exportBackup());
                },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore_rounded),
          title: const Text(AppStrings.restoreBackup),
          subtitle: const Text(AppStrings.restoreBackupBody),
          enabled: !_busy,
          onTap: _busy
              ? null
              : () {
                  unawaited(_restoreBackup());
                },
        ),
        const Divider(height: 36),
        Text(AppStrings.updates, style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.system_update_alt_rounded),
          title: const Text(AppStrings.releaseUpdates),
          subtitle: const Text(AppStrings.releaseUpdatesBody),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () {
            unawaited(_openReleases());
          },
        ),
        const Divider(height: 36),
        Text(AppStrings.about, style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text(AppStrings.aboutNoteNest),
          subtitle: const Text(AppStrings.aboutNoteNestBody),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: widget.onOpenAbout,
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _toggleAppLock(bool enable) async {
    setState(() => _busy = true);
    try {
      if (enable) {
        final bool supported = await widget.appLock.canAuthenticate();
        if (!supported) {
          _message(AppStrings.authUnavailable);
          return;
        }
        final bool verified = await widget.appLock.authenticate();
        if (!verified) {
          _message(AppStrings.appLockNotEnabled);
          return;
        }
      }
      await widget.settings.setAppLockEnabled(value: enable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final bool saved = await widget.files.exportBackup();
      if (saved) _message(AppStrings.backupExported);
    } on Object {
      _message(AppStrings.backupExportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final bool confirmed = await _confirmRestore();
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final RestoreReport? report = await widget.files.importBackup();
      if (report != null) {
        _message(
          AppStrings.restoreReport(
            importedNotes: report.importedNotes,
            importedVersions: report.importedVersions,
            skippedNewerNotes: report.skippedNewerNotes,
          ),
        );
      }
    } on Object {
      _message(AppStrings.backupRestoreFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReleases() async {
    final Uri releases = Uri.parse('${AppStrings.repositoryUrl}/releases');
    final bool opened = await launchUrl(
      releases,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      _message(AppStrings.releasesOpenFailed);
    }
  }

  Future<bool> _confirmRestore() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.restoreBackupQuestion),
            content: const Text(AppStrings.restoreBackupWarning),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(AppStrings.restore),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
