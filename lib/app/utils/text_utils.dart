import 'dart:developer' as dev;

import '../../domain/entities/formatting.dart';

class TextUtils {
  /// Creates opening HTML tag based on Tag type and color
  static String createOpenTag(Tag tag, int color) {
    String colorHex =
        color.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2);

    String result;
    switch (tag) {
      case Tag.m:
        result = '<span style="background-color:#$colorHex;">';
        break;
      case Tag.u:
        result = '<u style="text-decoration-color:#$colorHex;">';
        break;
      case Tag.c:
        result = '';
        break;
    }

    dev.log('=== CREATE OPEN TAG ===');
    dev.log('Tag: $tag, Color: $color, ColorHex: $colorHex');
    dev.log('Result: $result');

    return result;
  }

  /// Creates closing HTML tag based on Tag type
  static String createCloseTag(Tag tag) {
    switch (tag) {
      case Tag.m:
        return '</span>';
      case Tag.u:
        return '</u>';
      case Tag.c:
        return '';
    }
  }

  /// Adds formatting tags to text at specified positions
  static String addFormatting(
      String originalText, Tag tag, int color, int start, int end) {
    dev.log('=== ADD FORMATTING ===');
    dev.log('Original: "$originalText"');
    dev.log('Tag: $tag, Color: $color, Start: $start, End: $end');

    if (start >= end || start < 0 || end > originalText.length) {
      dev.log('Invalid parameters, returning original text');
      return originalText;
    }

    String openTag = createOpenTag(tag, color);
    String closeTag = createCloseTag(tag);

    if (tag == Tag.c) {
      // For clear tag, remove all formatting
      String result = removeAllFormatting(originalText);
      dev.log('Clear formatting result: "$result"');
      return result;
    }

    String before = originalText.substring(0, start);
    String selected = originalText.substring(start, end);
    String after = originalText.substring(end);

    String result = before + openTag + selected + closeTag + after;
    dev.log('Formatted result: "$result"');
    return result;
  }

  /// Removes all formatting tags except links
  static String removeAllFormatting(String text) {
    // Remove span tags with style attributes
    text = text.replaceAll(RegExp(r'<span[^>]*style="[^"]*"[^>]*>'), '');
    text = text.replaceAll('</span>', '');

    // Remove underline tags with style attributes
    text = text.replaceAll(RegExp(r'<u[^>]*style="[^"]*"[^>]*>'), '');
    text = text.replaceAll('</u>', '');

    return text;
  }

  /// Extracts plain text from HTML
  static String parseHtmlString(String htmlString) {
    try {
      if (htmlString.isEmpty) {
        return '';
      }

      // First decode any HTML entities
      String decoded = htmlString
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ');

      // Then remove HTML tags while preserving text content
      String result = decoded.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      dev.log('parseHtmlString input: "$htmlString"');
      dev.log('parseHtmlString output: "$result"');

      return result;
    } catch (e) {
      dev.log('parseHtmlString error: $e');
      return htmlString; // Return original if parsing fails
    }
  }

  /// Gets text selection based on start and end positions
  static TextSelection getTextSelection(String text, int start, int end) {
    try {
      if (text.isEmpty || start >= end || start < 0 || end > text.length) {
        return TextSelection(start: 0, end: 0, selectedText: '');
      }

      String plainText = parseHtmlString(text);
      if (plainText.isEmpty ||
          end > plainText.length ||
          start >= plainText.length) {
        return TextSelection(start: 0, end: 0, selectedText: '');
      }

      return TextSelection(
          start: start,
          end: end,
          selectedText: plainText.substring(start, end));
    } catch (e) {
      dev.log('getTextSelection error: $e');
      return TextSelection(start: 0, end: 0, selectedText: '');
    }
  }

  /// Checks if text contains formatting
  static bool hasFormatting(String text) {
    return text.contains(RegExp(r'<span[^>]*style="[^"]*"[^>]*>')) ||
        text.contains(RegExp(r'<u[^>]*style="[^"]*"[^>]*>'));
  }
}
