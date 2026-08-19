import 'package:flutter/material.dart';
import 'package:notenest/app/app.dart';
import 'package:notenest/app/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppDependencies dependencies = await AppDependencies.create();
  runApp(NoteNestApp(dependencies: dependencies));
}
