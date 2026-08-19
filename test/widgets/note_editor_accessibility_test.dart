import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/theme/app_tokens.dart';
import 'package:notenest/widgets/note_color_swatch.dart';

void main() {
  testWidgets(
    'selected note color swatch is explicit and touch-friendly',
    (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NoteColorSwatch(
                label: 'Red',
                color: const Color(0xFFFFD7D7),
                selected: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Red note color, selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        tester.getSize(find.byType(NoteColorSwatch)),
        Size.square(AppTokens.minimumTouchTarget),
      );

      await tester.tap(find.byType(NoteColorSwatch));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'unselected default swatch has a non-color reset cue',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NoteColorSwatch(
                label: 'Default',
                color: null,
                selected: false,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Default note color'), findsOneWidget);
      expect(find.byIcon(Icons.format_color_reset_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    },
  );
}
