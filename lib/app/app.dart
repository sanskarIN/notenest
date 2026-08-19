import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notenest/app/app_dependencies.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/theme/app_theme.dart';
import 'package:notenest/features/home/home_shell.dart';
import 'package:notenest/features/onboarding/onboarding_page.dart';

class NoteNestApp extends StatefulWidget {
  const NoteNestApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<NoteNestApp> createState() => _NoteNestAppState();
}

class _NoteNestAppState extends State<NoteNestApp> {
  @override
  void initState() {
    super.initState();
    widget.dependencies.settings.addListener(_settingsChanged);
  }

  @override
  void dispose() {
    widget.dependencies.settings.removeListener(_settingsChanged);
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.dependencies.settings;
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(textScale: settings.fontScale),
      darkTheme: AppTheme.dark(textScale: settings.fontScale),
      themeMode: settings.themeMode,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en')],
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: settings.reduceMotion),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: settings.onboardingComplete
          ? _LockGate(dependencies: widget.dependencies)
          : OnboardingPage(onComplete: settings.completeOnboarding),
    );
  }
}

class _LockGate extends StatefulWidget {
  const _LockGate({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.dependencies.settings.appLockEnabled) {
      _unlocked = true;
    } else {
      unawaited(_authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.dependencies.settings.appLockEnabled &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      if (mounted) setState(() => _unlocked = false);
    }
    if (widget.dependencies.settings.appLockEnabled &&
        state == AppLifecycleState.resumed &&
        !_unlocked) {
      unawaited(_authenticate());
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating || _unlocked) return;
    setState(() => _authenticating = true);
    final bool success = await widget.dependencies.appLock.authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _unlocked = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked || !widget.dependencies.settings.appLockEnabled) {
      return HomeShell(dependencies: widget.dependencies);
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.lock_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NoteNest is locked',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use your device authentication to access local notes.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _authenticating ? null : _authenticate,
                    icon: _authenticating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint_rounded),
                    label: const Text('Unlock'),
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
