import 'package:flutter/material.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/theme/app_tokens.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppTokens.space24),
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    AppStrings.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.space32),
                  const _Benefit(
                    icon: Icons.offline_bolt_rounded,
                    title: AppStrings.onboardingOfflineTitle,
                    message: AppStrings.onboardingOfflineBody,
                  ),
                  const _Benefit(
                    icon: Icons.search_rounded,
                    title: AppStrings.onboardingFindTitle,
                    message: AppStrings.onboardingFindBody,
                  ),
                  const _Benefit(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.onboardingPrivacyTitle,
                    message: AppStrings.onboardingPrivacyBody,
                  ),
                  const SizedBox(height: AppTokens.space28),
                  FilledButton.icon(
                    onPressed: () async {
                      await onComplete();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
                      child: Text(AppStrings.onboardingStart),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
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
