import 'package:flutter/material.dart';
import 'package:notenest/core/constants/app_strings.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  const _Benefit(
                    icon: Icons.offline_bolt_rounded,
                    title: 'Offline first',
                    message: 'Notes stay useful without an account or internet connection.',
                  ),
                  const _Benefit(
                    icon: Icons.search_rounded,
                    title: 'Fast to find',
                    message: 'Folders, tags, favorites, pinning, and full-text search keep ideas organized.',
                  ),
                  const _Benefit(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Private by default',
                    message: 'Your note database lives locally. Backup and app lock remain under your control.',
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () async => onComplete(),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Start using NoteNest'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.credit,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(message),
      contentPadding: EdgeInsets.zero,
    );
  }
}
