import 'package:flutter/material.dart';
import 'package:notenest/app/app.dart';
import 'package:notenest/app/app_dependencies.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/core/logging/app_logger.dart';
import 'package:notenest/core/theme/app_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AppLogger logger = AppLogger();
  try {
    final AppDependencies dependencies = await AppDependencies.create();
    runApp(NoteNestApp(dependencies: dependencies));
  } on Object catch (error) {
    logger.error(
      'app.bootstrap_failed',
      fields: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
    runApp(const _BootstrapFailureApp());
  }
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Padding(
                padding: EdgeInsets.all(AppTokens.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.error_outline_rounded, size: 64),
                    SizedBox(height: AppTokens.space20),
                    Text(
                      AppStrings.startFailedTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppTokens.space12),
                    Text(
                      AppStrings.startFailedBody,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
