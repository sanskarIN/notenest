import 'package:flutter/material.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: Icon(
            Icons.auto_stories_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        const Text(AppStrings.tagline, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Version ${AppStrings.version} • MIT License',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        const _AboutCard(
          icon: Icons.lock_outline_rounded,
          title: 'Privacy by design',
          body:
              'NoteNest is offline-first. Core note content is stored locally in a Drift/SQLite database and does not require an account.',
        ),
        const SizedBox(height: 12),
        _LinkTile(
          icon: Icons.code_rounded,
          title: 'GitHub repository',
          subtitle: AppStrings.repositoryUrl,
          uri: Uri.parse(AppStrings.repositoryUrl),
        ),
        _LinkTile(
          icon: Icons.favorite_outline_rounded,
          title: 'Buy Me a Coffee',
          subtitle: AppStrings.fundingUrl,
          uri: Uri.parse(AppStrings.fundingUrl),
        ),
        _LinkTile(
          icon: Icons.mail_outline_rounded,
          title: 'Business email',
          subtitle: AppStrings.businessEmail,
          uri: Uri(scheme: 'mailto', path: AppStrings.businessEmail),
        ),
        _LinkTile(
          icon: Icons.business_center_outlined,
          title: 'Secondary business email',
          subtitle: AppStrings.secondaryBusinessEmail,
          uri: Uri(scheme: 'mailto', path: AppStrings.secondaryBusinessEmail),
        ),
        _LinkTile(
          icon: Icons.support_agent_rounded,
          title: 'Support email',
          subtitle: AppStrings.supportEmail,
          uri: Uri(scheme: 'mailto', path: AppStrings.supportEmail),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.credit,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uri,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
}
