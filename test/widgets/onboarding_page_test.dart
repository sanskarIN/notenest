import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/features/onboarding/onboarding_page.dart';

void main() {
  testWidgets('onboarding explains offline-first privacy and completes', (
    WidgetTester tester,
  ) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () async {
            completed = true;
          },
        ),
      ),
    );

    expect(find.text('Offline first'), findsOneWidget);
    expect(find.text('Private by default'), findsOneWidget);

    await tester.tap(find.text('Start using NoteNest'));
    await tester.pump();

    expect(completed, isTrue);
  });

  testWidgets('onboarding reports a persistence failure and stays usable', (
    WidgetTester tester,
  ) async {
    int attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () async {
            attempts += 1;
            throw StateError('preference write failed');
          },
        ),
      ),
    );

    await tester.tap(find.text('Start using NoteNest'));
    await tester.pump();

    expect(attempts, 1);
    expect(
      find.text('Could not save onboarding progress. Please try again.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Start using NoteNest'), findsOneWidget);
  });

  testWidgets('onboarding scrolls safely on a compact viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(home: OnboardingPage(onComplete: () async {})),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start using NoteNest'),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Start using NoteNest'), findsOneWidget);
  });
}
