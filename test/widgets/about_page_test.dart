import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/features/about/about_page.dart';
import 'package:notenest/services/external_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  testWidgets('shows feedback when an About link cannot be opened', (
    WidgetTester tester,
  ) async {
    final ExternalLinkService externalLinks = ExternalLinkService(
      launcher: (Uri _, LaunchMode __) async => false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AboutPage(externalLinks: externalLinks)),
      ),
    );

    await tester.tap(find.text('GitHub repository'));
    await tester.pump();

    expect(
      find.text('Could not open this link on the current device.'),
      findsOneWidget,
    );
  });
}
