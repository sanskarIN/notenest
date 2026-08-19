import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notenest/app/app_settings_controller.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/services/app_lock_service.dart';
import 'package:notenest/services/external_link_service.dart';
import 'package:notenest/services/file_transfer_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.files,
    required this.appLock,
    required this.externalLinks,
    required this.onOpenAbout,
    super.key,
  });

  final AppSettingsController settings;
  final FileTransferService files;
  final AppLockService appLock;
  final ExternalLinkService externalLinks;
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
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded),
              label: Text('System'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded),
              label: Text('Light'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded),
              label: Text('Dark'),
            ),
          ],
          selected: <ThemeMode>{settings.themeMode},
          onSelectionChanged: (Set<ThemeMode> values) {
            _queuePreference(() => settings.setThemeMode(values.single));
          },
        ),
        const SizedBox(height: 28),
        Text('Accessibility', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Text size'),
          subtitle: Slider(
            value: settings.fontScale,
            min: 0.9,
            max: 1.4,
            divisions: 5,
            label: '${(settings.fontScale * 100).round()}%',
            onChanged: (double value) {
              _queuePreference(() => settings.setFontScale(value));
            },
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reduce motion'),
          subtitle: const Text('Prefer fewer non-essential interface animations.'),
          value: settings.reduceMotion,
          onChanged: (bool value) {
            _queuePreference(() => settings.setReduceMotion(value: value));
          },
        ),
        const Divider(height: 36),
        Text('Privacy', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Local app lock'),
          subtitle: const Text('Use device authentication when supported.'),
          value: settings.appLockEnabled,
          onChanged: _busy ? null : _toggleAppLock,
        ),
        const Divider(height: 36),
        Text('Data', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.backup_rounded),
          title: const Text('Export backup'),
          subtitle: const Text('Save notes and version history as validated JSON.'),
          enabled: !_busy,
          onTap: _exportBackup,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore_rounded),
          title: const Text('Restore backup'),
          subtitle: const Text(
            'Merge a NoteNest JSON backup without overwriting newer local notes.',
          ),
          enabled: !_busy,
          onTap: _restoreBackup,
        ),
        const Divider(height: 36),
        Text('Updates', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.system_update_alt_rounded),
          title: const Text('Release updates'),
          subtitle: const Text(
            'Open the official NoteNest GitHub Releases page to review published versions.',
          ),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: _busy ? null : _openReleases,
        ),
        const Divider(height: 36),
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('About NoteNest'),
          subtitle: const Text(
            'Version, license, privacy summary, support, source code, and funding.',
          ),
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

  void _queuePreference(Future<void> Function() action) {
    unawaited(_savePreference(action));
  }

  Future<void> _savePreference(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      _message('Could not save this setting. The previous saved value was restored.');
    }
  }

  Future<void> _toggleAppLock(bool enable) async {
    setState(() => _busy = true);
    try {
      if (enable) {
        final bool supported = await widget.appLock.canAuthenticate();
        if (!supported) {
          _message('Device authentication is not available on this platform or device.');
          return;
        }
        final bool verified = await widget.appLock.authenticate();
        if (!verified) {
          _message('App lock was not enabled because authentication did not complete.');
          return;
        }
      }
      await widget.settings.setAppLockEnabled(value: enable);
    } on Object {
      _message(
        'Could not save the app-lock setting. The previous saved value was restored.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final bool saved = await widget.files.exportBackup();
      if (saved) _message('Backup exported successfully.');
    } on Object {
      _message('Backup export failed. Your local notes were not changed.');
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
          'Restored ${report.importedNotes} notes and ${report.importedVersions} snapshots; '
          'kept ${report.skippedNewerNotes} newer local notes.',
        );
      }
    } on Object {
      _message('Backup restore failed. No partial restore was kept.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReleases() async {
    final Uri releases = Uri.parse('${AppStrings.repositoryUrl}/releases');
    final bool opened = await widget.externalLinks.open(releases);
    if (!opened) {
      _message('Could not open the releases page on this device.');
    }
  }

  Future<bool> _confirmRestore() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Restore backup?'),
            content: const Text(
              'The backup is validated before changes are applied. Newer local notes are preserved.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
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
