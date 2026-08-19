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
}
