import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/services/external_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('returns true when the platform launcher succeeds', () async {
    final ExternalLinkService service = ExternalLinkService(
      launcher: (Uri uri, LaunchMode mode) async {
        expect(uri, Uri.parse('https://example.com'));
        expect(mode, LaunchMode.externalApplication);
        return true;
      },
    );

    expect(await service.open(Uri.parse('https://example.com')), isTrue);
  });

  test('returns false when the platform launcher declines the URI', () async {
    final ExternalLinkService service = ExternalLinkService(
      launcher: (Uri _, LaunchMode __) async => false,
    );

    expect(await service.open(Uri.parse('https://example.com')), isFalse);
  });

  test('converts launcher exceptions into a safe false result', () async {
    final ExternalLinkService service = ExternalLinkService(
      launcher: (Uri _, LaunchMode __) async {
        throw StateError('launcher unavailable');
      },
    );

    expect(await service.open(Uri.parse('mailto:test@example.com')), isFalse);
  });
}
