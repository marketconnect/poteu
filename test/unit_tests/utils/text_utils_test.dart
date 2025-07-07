import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/app/utils/text_utils.dart';
import 'package:poteu/domain/entities/formatting.dart';

void main() {
  group('TextUtils Tests', () {
    group('createOpenTag', () {
      test('creates span tag for mark (m) tag', () {
        final result = TextUtils.createOpenTag(Tag.m, 0xFF0000FF); // Blue
        expect(result, '<span style="background-color:#0000FF;">');
      });

      test('creates underline tag for underline (u) tag', () {
        final result = TextUtils.createOpenTag(Tag.u, 0xFFFF0000); // Red
        expect(result, '<u style="text-decoration-color:#FF0000;">');
      });

      test('creates empty string for clear (c) tag', () {
        final result = TextUtils.createOpenTag(Tag.c, 0xFF000000);
        expect(result, '');
      });

      test('handles different color values correctly', () {
        // Test various color values
        var result = TextUtils.createOpenTag(Tag.m, 0xFF123456);
        expect(result, '<span style="background-color:#123456;">');

        result = TextUtils.createOpenTag(Tag.u, 0xFFABCDEF);
        expect(result, '<u style="text-decoration-color:#ABCDEF;">');

        result = TextUtils.createOpenTag(Tag.m, 0xFF000000);
        expect(result, '<span style="background-color:#000000;">');

        result = TextUtils.createOpenTag(Tag.m, 0xFFFFFFFF);
        expect(result, '<span style="background-color:#FFFFFF;">');
      });

      test('pads color hex values correctly', () {
        // Test color that needs padding
        final result = TextUtils.createOpenTag(Tag.m, 0xFF00001A);
        expect(result, '<span style="background-color:#00001A;">');
      });
    });

    group('createCloseTag', () {
      test('creates closing span tag for mark (m) tag', () {
        final result = TextUtils.createCloseTag(Tag.m);
        expect(result, '</span>');
      });

      test('creates closing underline tag for underline (u) tag', () {
        final result = TextUtils.createCloseTag(Tag.u);
        expect(result, '</u>');
      });

      test('creates empty string for clear (c) tag', () {
        final result = TextUtils.createCloseTag(Tag.c);
        expect(result, '');
      });
    });

    group('addFormatting', () {
      test('adds mark formatting to text', () {
        const originalText = 'Hello world';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.m,
          0xFFFF0000,
          0,
          5, // 'Hello'
        );
        expect(result,
            '<span style="background-color:#FF0000;">Hello</span> world');
      });

      test('adds underline formatting to text', () {
        const originalText = 'Hello world';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.u,
          0xFF0000FF,
          6,
          11, // 'world'
        );
        expect(result,
            'Hello <u style="text-decoration-color:#0000FF;">world</u>');
      });

      test('adds formatting in the middle of text', () {
        const originalText = 'The quick brown fox';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.m,
          0xFF00FF00,
          4,
          9, // 'quick'
        );
        expect(result,
            'The <span style="background-color:#00FF00;">quick</span> brown fox');
      });

      test('handles clear tag by removing all formatting', () {
        const originalText =
            'Hello <span style="background-color:#FF0000;">world</span>';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.c,
          0xFF000000,
          0,
          5,
        );
        expect(result, 'Hello world');
      });

      test('returns original text for invalid start/end positions', () {
        const originalText = 'Hello world';

        // start >= end
        var result =
            TextUtils.addFormatting(originalText, Tag.m, 0xFF0000, 5, 5);
        expect(result, originalText);

        result = TextUtils.addFormatting(originalText, Tag.m, 0xFF0000, 7, 5);
        expect(result, originalText);

        // start < 0
        result = TextUtils.addFormatting(originalText, Tag.m, 0xFF0000, -1, 5);
        expect(result, originalText);

        // end > text.length
        result = TextUtils.addFormatting(originalText, Tag.m, 0xFF0000, 0, 100);
        expect(result, originalText);
      });

      test('handles empty text', () {
        const originalText = '';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.m,
          0xFF0000,
          0,
          0,
        );
        expect(result, originalText);
      });

      test('handles single character selection', () {
        const originalText = 'Hello';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.u,
          0xFF0000,
          0,
          1, // 'H'
        );
        expect(result, '<u style="text-decoration-color:#FF0000;">H</u>ello');
      });

      test('handles full text selection', () {
        const originalText = 'Hello';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.m,
          0xFF0000,
          0,
          5, // entire text
        );
        expect(result, '<span style="background-color:#FF0000;">Hello</span>');
      });
    });

    group('removeAllFormatting', () {
      test('removes span tags with style attributes', () {
        const text =
            'Hello <span style="background-color:#FF0000;">world</span> test';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, 'Hello world test');
      });

      test('removes underline tags with style attributes', () {
        const text =
            'Hello <u style="text-decoration-color:#0000FF;">world</u> test';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, 'Hello world test');
      });

      test('removes multiple formatting tags', () {
        const text =
            '<span style="background-color:#FF0000;">Hello</span> <u style="text-decoration-color:#0000FF;">world</u>';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, 'Hello world');
      });

      test('removes nested formatting tags', () {
        const text =
            '<span style="background-color:#FF0000;">Hello <u style="text-decoration-color:#0000FF;">nested</u> world</span>';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, 'Hello nested world');
      });

      test('handles text without formatting', () {
        const text = 'Plain text without formatting';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, text);
      });

      test('handles empty text', () {
        const text = '';
        final result = TextUtils.removeAllFormatting(text);
        expect(result, '');
      });

      test('preserves other HTML tags (does not remove links)', () {
        const text =
            'Hello <a href="http://example.com">link</a> and <span style="color: red;">formatted</span> text';
        final result = TextUtils.removeAllFormatting(text);
        expect(result,
            'Hello <a href="http://example.com">link</a> and formatted text');
      });
    });

    group('parseHtmlString', () {
      test('removes HTML tags and returns plain text', () {
        const html = '<p>Hello <strong>world</strong></p>';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Hello world');
      });

      test('decodes HTML entities', () {
        const html =
            'Hello &amp; goodbye &lt;test&gt; &quot;quoted&quot; &#39;single&#39; space&nbsp;here';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Hello & goodbye  "quoted" \'single\' space here');
      });

      test('handles complex HTML with nested tags', () {
        const html =
            '<div><p>Hello <span style="color: red;">world</span></p><ul><li>Item 1</li><li>Item 2</li></ul></div>';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Hello worldItem 1Item 2');
      });

      test('handles self-closing tags', () {
        const html = 'Line 1<br/>Line 2<hr/>Line 3';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Line 1Line 2Line 3');
      });

      test('handles empty HTML string', () {
        const html = '';
        final result = TextUtils.parseHtmlString(html);
        expect(result, '');
      });

      test('handles plain text (no HTML)', () {
        const text = 'Plain text without HTML';
        final result = TextUtils.parseHtmlString(text);
        expect(result, text);
      });

      test('handles malformed HTML gracefully', () {
        const html = '<p>Unclosed paragraph <span>nested without close';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Unclosed paragraph nested without close');
      });

      test('trims whitespace from result', () {
        const html = '  <p>  Hello world  </p>  ';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Hello world');
      });

      test('handles mixed content with entities and tags', () {
        const html =
            '<p>Price: &lt;span&gt;\$10 &amp; free shipping&lt;/span&gt;</p>';
        final result = TextUtils.parseHtmlString(html);
        expect(result, 'Price: \$10 & free shipping');
      });
    });

    group('getTextSelection', () {
      test('returns correct text selection for valid parameters', () {
        const text = 'Hello world';
        final selection = TextUtils.getTextSelection(text, 0, 5);

        expect(selection.start, 0);
        expect(selection.end, 5);
        expect(selection.selectedText, 'Hello');
      });

      test('handles text selection in the middle', () {
        const text = 'The quick brown fox';
        final selection = TextUtils.getTextSelection(text, 4, 9);

        expect(selection.start, 4);
        expect(selection.end, 9);
        expect(selection.selectedText, 'quick');
      });

      test('handles HTML text by parsing it first', () {
        const html = '<p>Hello <strong>world</strong></p>';
        final selection = TextUtils.getTextSelection(html, 0, 5);

        expect(selection.start, 0);
        expect(selection.end, 5);
        expect(selection.selectedText, 'Hello');
      });

      test('returns empty selection for invalid parameters', () {
        const text = 'Hello world';

        // start >= end
        var selection = TextUtils.getTextSelection(text, 5, 5);
        expect(selection.start, 0);
        expect(selection.end, 0);
        expect(selection.selectedText, '');

        selection = TextUtils.getTextSelection(text, 7, 5);
        expect(selection.start, 0);
        expect(selection.end, 0);
        expect(selection.selectedText, '');

        // start < 0
        selection = TextUtils.getTextSelection(text, -1, 5);
        expect(selection.start, 0);
        expect(selection.end, 0);
        expect(selection.selectedText, '');

        // end > text.length
        selection = TextUtils.getTextSelection(text, 0, 100);
        expect(selection.start, 0);
        expect(selection.end, 0);
        expect(selection.selectedText, '');
      });

      test('handles empty text', () {
        const text = '';
        final selection = TextUtils.getTextSelection(text, 0, 0);

        expect(selection.start, 0);
        expect(selection.end, 0);
        expect(selection.selectedText, '');
      });

      test('handles single character selection', () {
        const text = 'Hello';
        final selection = TextUtils.getTextSelection(text, 0, 1);

        expect(selection.start, 0);
        expect(selection.end, 1);
        expect(selection.selectedText, 'H');
      });

      test('handles full text selection', () {
        const text = 'Hello';
        final selection = TextUtils.getTextSelection(text, 0, 5);

        expect(selection.start, 0);
        expect(selection.end, 5);
        expect(selection.selectedText, 'Hello');
      });

      test('handles unicode characters correctly', () {
        const text = 'Привет мир 🌍';
        final selection = TextUtils.getTextSelection(text, 0, 6);

        expect(selection.start, 0);
        expect(selection.end, 6);
        expect(selection.selectedText, 'Привет');
      });
    });

    group('hasFormatting', () {
      test('detects span formatting', () {
        const text =
            'Hello <span style="background-color:#FF0000;">world</span>';
        expect(TextUtils.hasFormatting(text), true);
      });

      test('detects underline formatting', () {
        const text =
            'Hello <u style="text-decoration-color:#0000FF;">world</u>';
        expect(TextUtils.hasFormatting(text), true);
      });

      test('detects multiple formatting types', () {
        const text =
            '<span style="background-color:#FF0000;">Hello</span> <u style="text-decoration-color:#0000FF;">world</u>';
        expect(TextUtils.hasFormatting(text), true);
      });

      test('returns false for text without formatting', () {
        const text = 'Plain text without any formatting';
        expect(TextUtils.hasFormatting(text), false);
      });

      test('returns false for other HTML tags', () {
        const text =
            'Hello <a href="http://example.com">world</a> <p>paragraph</p>';
        expect(TextUtils.hasFormatting(text), false);
      });

      test('returns false for empty text', () {
        const text = '';
        expect(TextUtils.hasFormatting(text), false);
      });

      test('handles span tags without style attributes', () {
        const text = 'Hello <span>world</span>';
        expect(TextUtils.hasFormatting(text), false);
      });

      test('handles underline tags without style attributes', () {
        const text = 'Hello <u>world</u>';
        expect(TextUtils.hasFormatting(text), false);
      });

      test('detects complex formatting patterns', () {
        const text =
            'Text with <span style="background-color:#FF0000; font-weight: bold;">complex</span> formatting';
        expect(TextUtils.hasFormatting(text), true);
      });
    });

    group('Edge Cases and Integration', () {
      test('handles special characters in formatting', () {
        const originalText = 'Привет мир! 🌍 @#\$%^&*()';
        final result = TextUtils.addFormatting(
          originalText,
          Tag.m,
          0xFF0000,
          0,
          6, // 'Привет'
        );
        expect(result,
            '<span style="background-color:#FF0000;">Привет</span> мир! 🌍 @#\$%^&*()');
      });

      test('handles very long text', () {
        final longText = 'word ' * 1000;
        final result = TextUtils.addFormatting(
          longText,
          Tag.u,
          0xFF0000,
          0,
          4, // 'word'
        );
        expect(
            result.startsWith(
                '<u style="text-decoration-color:#FF0000;">word</u>'),
            true);
      });

      test('complex formatting workflow', () {
        var text = 'Hello world test';

        // Add mark formatting
        text = TextUtils.addFormatting(text, Tag.m, 0xFF0000, 0, 5);
        expect(text,
            '<span style="background-color:#FF0000;">Hello</span> world test');
        expect(TextUtils.hasFormatting(text), true);

        // Get plain text from formatted text
        final plainText = TextUtils.parseHtmlString(text);
        expect(plainText, 'Hello world test');

        // Remove all formatting
        final cleanText = TextUtils.removeAllFormatting(text);
        expect(cleanText, 'Hello world test');
        expect(TextUtils.hasFormatting(cleanText), false);

        // Test formatting on clean text again
        final freshFormatted = TextUtils.addFormatting(
            cleanText, Tag.u, 0x0000FF, 12, 16); // 'test'
        expect(freshFormatted,
            contains('<u style="text-decoration-color:#0000FF;">test</u>'));
      });

      test('handles malformed input gracefully', () {
        // Test with null-like scenarios that might occur
        expect(() => TextUtils.parseHtmlString(''), returnsNormally);
        expect(() => TextUtils.hasFormatting(''), returnsNormally);
        expect(() => TextUtils.removeAllFormatting(''), returnsNormally);

        // Test with only HTML tags
        const onlyTags = '<span></span><u></u>';
        expect(TextUtils.parseHtmlString(onlyTags), '');
        expect(TextUtils.hasFormatting(onlyTags), false);
      });
    });
  });
}
