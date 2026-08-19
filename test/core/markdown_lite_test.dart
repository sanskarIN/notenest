import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/utils/markdown_lite.dart';

void main() {
  group('MarkdownLite', () {
    test('turns a line into an unchecked checklist item', () {
      expect(
        MarkdownLite.toggleChecklist('Buy milk', checked: false),
        '- [ ] Buy milk',
      );
    });

    test('normalizes an existing checklist state', () {
      expect(
        MarkdownLite.toggleChecklist('- [x] Buy milk', checked: false),
        '- [ ] Buy milk',
      );
    });

    test('toggles a line prefix', () {
      expect(MarkdownLite.togglePrefix('Hello', '## '), '## Hello');
      expect(MarkdownLite.togglePrefix('## Hello', '## '), 'Hello');
    });

    test('creates a plain compact preview', () {
      expect(
        MarkdownLite.plainPreview('## Title\n- [ ] **Task**'),
        'Title Task',
      );
    });

    test('truncates previews without splitting Unicode scalar values', () {
      final String markdown = '${List<String>.filled(4, 'a').join()}😀tail';
      final String preview = MarkdownLite.plainPreview(markdown, maxLength: 5);

      expect(preview, 'aaaa😀…');
      expect(preview.runes.length, 6);
    });

    test('rejects a negative preview length', () {
      expect(
        () => MarkdownLite.plainPreview('text', maxLength: -1),
        throwsArgumentError,
      );
    });
  });
}
