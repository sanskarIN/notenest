import 'package:flutter/material.dart';
import 'package:notenest/app/app_settings_controller.dart';
import 'package:notenest/data/repositories/backup_repository.dart';
import 'package:notenest/services/app_lock_service.dart';
import 'package:notenest/services/file_transfer_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.files,
    required this.appLock,
    super.key,
  });

  final AppSettingsController settings;
  final FileTransferService files;
  final AppLockService appLock;

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
          onSelectionChanged: (Set<ThemeMode> values) =>
              settings.setThemeMode(values.single),
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
            onChanged: settings.setFontScale,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reduce motion'),
          subtitle: const Text('Prefer fewer non-essential interface animations.'),
          value: settings.reduceMotion,
          onChanged: (bool value) => settings.setReduceMotion(value: value),
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
          subtitle: const Text('Merge a NoteNest JSON backup without overwriting newer local notes.'),
          enabled: !_busy,
          onTap: _restoreBackup,
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final bool saved = await widget.files.exportBackup();
      if (saved) _message('Backup exported successfully.');
    } on Object catch (error) {
      _message('Backup export failed: $error');
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
    } on Object catch (error) {
      _message('Backup restore failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
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
