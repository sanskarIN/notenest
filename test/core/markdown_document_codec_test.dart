import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/errors/app_exception.dart';
import 'package:notenest/core/utils/markdown_document_codec.dart';

void main() {
  group('MarkdownDocumentCodec', () {
    test('round trips NoteNest metadata and Unicode content', () {
      final String encoded = MarkdownDocumentCodec.encode(
        title: 'Ideas "अध्ययन"',
        body: '# Body\n\n- [ ] नमस्ते\n\n--- inside body',
        folder: 'Projects/2026',
        tags: const <String>['flutter', 'offline', 'flutter', 'नोट्स'],
        updatedAt: DateTime.utc(2026, 8, 19, 10, 30),
      );

      final MarkdownDocument decoded = MarkdownDocumentCodec.decode(
        encoded,
        fallbackTitle: 'fallback',
      );

      expect(decoded.hasNoteNestMetadata, isTrue);
      expect(decoded.title, 'Ideas "अध्ययन"');
      expect(decoded.folder, 'Projects/2026');
      expect(decoded.tags, <String>['flutter', 'offline', 'नोट्स']);
      expect(decoded.updatedAt, DateTime.utc(2026, 8, 19, 10, 30));
      expect(decoded.body, '# Body\n\n- [ ] नमस्ते\n\n--- inside body');
    });

    test('keeps ordinary Markdown unchanged with filename title fallback', () {
      const String markdown = '# Heading\n\nPlain body.';

      final MarkdownDocument decoded = MarkdownDocumentCodec.decode(
        markdown,
        fallbackTitle: 'imported-note',
      );

      expect(decoded.hasNoteNestMetadata, isFalse);
      expect(decoded.title, 'imported-note');
      expect(decoded.body, markdown);
      expect(decoded.folder, isEmpty);
      expect(decoded.tags, isEmpty);
    });

    test('does not consume unrelated YAML-style front matter', () {
      const String markdown = '---\nauthor: "Someone"\n---\n\n# Heading';

      final MarkdownDocument decoded = MarkdownDocumentCodec.decode(
        markdown,
        fallbackTitle: 'document',
      );

      expect(decoded.hasNoteNestMetadata, isFalse);
      expect(decoded.body, markdown);
    });

    test('rejects unsupported NoteNest metadata versions', () {
      const String markdown = '---\nnotenest: 99\n---\n\nBody';

      expect(
        () => MarkdownDocumentCodec.decode(markdown, fallbackTitle: 'document'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects malformed recognized NoteNest metadata', () {
      const String markdown =
          '---\nnotenest: 1\ntags: "not-a-list"\n---\n\nBody';

      expect(
        () => MarkdownDocumentCodec.decode(markdown, fallbackTitle: 'document'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
