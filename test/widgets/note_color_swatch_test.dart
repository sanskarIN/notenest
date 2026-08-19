import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/widgets/note_color_swatch.dart';

void main() {
  testWidgets('exposes semantic selection and minimum touch target',
      (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteColorSwatch(
            label: 'Blue',
            color: Colors.blue,
            selected: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    final Finder swatch = find.byType(NoteColorSwatch);
    expect(tester.getSize(swatch).width, greaterThanOrEqualTo(AppTokens.minimumTouchTarget));
    expect(tester.getSize(swatch).height, greaterThanOrEqualTo(AppTokens.minimumTouchTarget));
    expect(find.bySemanticsLabel('Blue note color, selected'), findsOneWidget);

    await tester.tap(swatch);
    await tester.pump();
    expect(pressed, isTrue);
  });
}
