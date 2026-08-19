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
}
