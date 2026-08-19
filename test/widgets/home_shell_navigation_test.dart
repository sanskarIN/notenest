import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/app/app_dependencies.dart';
import 'package:notenest/core/constants/app_strings.dart';
import 'package:notenest/data/database/app_database.dart';
import 'package:notenest/features/home/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('compact navigation exposes Settings through More',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies dependencies = await AppDependencies.create(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      MaterialApp(home: HomeShell(dependencies: dependencies)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(AppStrings.more), findsOneWidget);

    await tester.tap(find.text(AppStrings.more));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settings), findsOneWidget);
    expect(find.text(AppStrings.about), findsOneWidget);

    await tester.tap(find.text(AppStrings.settings));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appearance), findsOneWidget);
  });

  testWidgets('wide navigation uses a navigation rail',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final AppDependencies dependencies = await AppDependencies.create(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      MaterialApp(home: HomeShell(dependencies: dependencies)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
