import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../helpers/database_helper.dart';
import '../../app/utils/text_utils.dart';

class DataNotesRepository implements NotesRepository {
  final DatabaseHelper _db;

  DataNotesRepository(this._db);

  @override
  Future<List<Note>> getAllNotes() async {
    final db = await _db.database;

    // Get all paragraphs that have been updated (either formatted or with notes)
    final List<Map<String, dynamic>> paragraphMaps = await db.query(
      'paragraphs',
      where:
          'updated_at IS NOT NULL AND (content LIKE ? OR content LIKE ? OR note IS NOT NULL)',
      whereArgs: ['%<span%', '%<u%'],
    );

    print('=== SEARCHING FOR NOTES ===');
    print('Found ${paragraphMaps.length} paragraphs with notes or formatting');

    final List<Note> notes = [];

    for (final paragraphMap in paragraphMaps) {
      print(
          'Processing paragraph ${paragraphMap['id']}: ${paragraphMap['content']}');

      // Get chapter info
      final chapterMaps = await db.query(
        'chapters',
        where: 'id = ?',
        whereArgs: [paragraphMap['chapter_id']],
      );

      if (chapterMaps.isNotEmpty) {
        final chapterMap = chapterMaps.first;

        // First check for formatted links
        final links =
            _extractEditedParagraphLinks(paragraphMap['content'] as String);
        print('Extracted ${links.length} formatted links from content');

        // Add formatted links as notes
        for (final link in links) {
          try {
            print('=== CREATING FORMATTED NOTE ===');
            print('Paragraph ID: ${paragraphMap['id']}');
            print('Original ID: ${paragraphMap['original_id']}');
            print('Chapter ID: ${paragraphMap['chapter_id']}');
            print('Chapter order num: ${chapterMap['order_num']}');
            print('Link text: "${link.text}"');
            print('Link color: ${link.color}');

            // Check for duplicates before creating note
            bool isDuplicate = notes.any((existingNote) =>
                existingNote.link.text == link.text &&
                existingNote.link.color.value == link.color.value &&
                existingNote.chapterId == paragraphMap['chapter_id']);

            if (isDuplicate) {
              print('⚠️ Skipping duplicate note: "${link.text}"');
              continue;
            }

            final note = Note(
              paragraphId: paragraphMap['id'] as int,
              originalParagraphId: paragraphMap['original_id'] as int,
              chapterId: paragraphMap['chapter_id'] as int,
              chapterOrderNum: chapterMap['order_num'] as int,
              regulationTitle: 'Правила по охране труда', // Could be dynamic
              chapterName: chapterMap['title'] as String? ??
                  'Глава ${chapterMap['order_num']}',
              content: paragraphMap['content'] as String,
              lastTouched: DateTime.tryParse(
                      paragraphMap['updated_at'] as String? ?? '') ??
                  DateTime.now(),
              isEdited: true,
              link: link,
            );
            notes.add(note);
            print(
                'Created formatted note successfully: ${note.link.text} with color ${note.link.color}');
          } catch (e) {
            print('ERROR creating formatted note: $e');
            print('Paragraph data: $paragraphMap');
            print('Chapter data: $chapterMap');
            print('Link data: $link');
          }
        }

        // Then check for plain text note
        final plainNote = paragraphMap['note'] as String?;
        if (plainNote != null && plainNote.isNotEmpty) {
          try {
            print('=== CREATING PLAIN NOTE ===');
            print('Paragraph ID: ${paragraphMap['id']}');
            print('Note text: "$plainNote"');

            // Create a default link for plain text note
            final link = EditedParagraphLink(
              text: plainNote,
              color: Colors.yellow, // Default color for plain notes
            );

            // Check for duplicates
            bool isDuplicate = notes.any((existingNote) =>
                existingNote.link.text == plainNote &&
                existingNote.chapterId == paragraphMap['chapter_id']);

            if (isDuplicate) {
              print('⚠️ Skipping duplicate plain note: "$plainNote"');
              continue;
            }

            final note = Note(
              paragraphId: paragraphMap['id'] as int,
              originalParagraphId: paragraphMap['original_id'] as int,
              chapterId: paragraphMap['chapter_id'] as int,
              chapterOrderNum: chapterMap['order_num'] as int,
              regulationTitle: 'Правила по охране труда',
              chapterName: chapterMap['title'] as String? ??
                  'Глава ${chapterMap['order_num']}',
              content: paragraphMap['content'] as String,
              lastTouched: DateTime.tryParse(
                      paragraphMap['updated_at'] as String? ?? '') ??
                  DateTime.now(),
              isEdited: false,
              link: link,
            );
            notes.add(note);
            print('Created plain note successfully: ${note.link.text}');
          } catch (e) {
            print('ERROR creating plain note: $e');
            print('Paragraph data: $paragraphMap');
            print('Chapter data: $chapterMap');
          }
        }
      }
    }

    print('=== TOTAL NOTES FOUND: ${notes.length} ===');
    return notes;
  }

  @override
  Future<List<Note>> getNotesByChapter(int chapterId) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.chapterId == chapterId).toList();
  }

  @override
  Future<void> deleteNote(Note note) async {
    final db = await _db.database;

    // Get the paragraph content
    final paragraphMaps = await db.query(
      'paragraphs',
      where: 'id = ?',
      whereArgs: [note.paragraphId],
    );

    if (paragraphMaps.isNotEmpty) {
      final paragraphMap = paragraphMaps.first;
      final currentContent = paragraphMap['content'] as String;
      final currentNote = paragraphMap['note'] as String?;

      // Remove the specific formatting for this note's link
      final cleanedContent =
          _removeSpecificFormatting(currentContent, note.link);

      // Check if this is a plain text note that needs to be removed
      final isPlainTextNote =
          currentNote != null && currentNote == note.link.text;

      if (_hasAnyFormatting(cleanedContent) ||
          (currentNote != null && !isPlainTextNote)) {
        // Still has other formatting or other notes, just update
        await db.update(
          'paragraphs',
          {
            'content': cleanedContent,
            'note': isPlainTextNote ? null : currentNote,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [note.paragraphId],
        );
      } else {
        // No formatting or notes left, remove the edit entry entirely
        await db.delete(
          'paragraphs',
          where: 'id = ?',
          whereArgs: [note.paragraphId],
        );
      }
    }
  }

  @override
  Future<void> deleteNoteById(int paragraphId) async {
    final db = await _db.database;
    await db.delete(
      'paragraphs',
      where: 'id = ?',
      whereArgs: [paragraphId],
    );
  }

  // Helper method to extract formatted links from content (similar to original)
  List<EditedParagraphLink> _extractEditedParagraphLinks(String content) {
    final List<EditedParagraphLink> result = [];
    print('Extracting links from content: $content');

    // Extract span tags with background-color
    final spanRegex = RegExp(
        r'<span[^>]*background-color:#([0-9A-Fa-f]+)[^>]*>(.*?)</span>',
        dotAll: true);
    final spanMatches = spanRegex.allMatches(content);

    print('Found ${spanMatches.length} span matches');
    for (final match in spanMatches) {
      final colorHex = match.group(1);
      final text = match.group(2);
      print('Processing span match: colorHex=$colorHex, text="$text"');
      if (colorHex != null && text != null) {
        try {
          final color = _parseHexColor(colorHex);
          final cleanText = TextUtils.parseHtmlString(text);
          if (cleanText.isNotEmpty) {
            result.add(EditedParagraphLink(
              color: color,
              text: cleanText,
            ));
            print('Found span link: "$cleanText" with color #$colorHex');
          }
        } catch (e) {
          print('Error parsing span color $colorHex: $e');
        }
      }
    }

    // Extract u tags with text-decoration-color
    final uRegex = RegExp(
        r'<u[^>]*text-decoration-color:#([0-9A-Fa-f]+)[^>]*>(.*?)</u>',
        dotAll: true);
    final uMatches = uRegex.allMatches(content);

    print('Found ${uMatches.length} u matches');
    for (final match in uMatches) {
      final colorHex = match.group(1);
      final text = match.group(2);
      print('Processing u match: colorHex=$colorHex, text="$text"');
      if (colorHex != null && text != null) {
        try {
          final color = _parseHexColor(colorHex);
          final cleanText = TextUtils.parseHtmlString(text);
          if (cleanText.isNotEmpty) {
            result.add(EditedParagraphLink(
              color: color,
              text: cleanText,
            ));
            print('Found u link: "$cleanText" with color #$colorHex');
          }
        } catch (e) {
          print('Error parsing u color $colorHex: $e');
        }
      }
    }

    print('Total extracted links: ${result.length}');
    return result;
  }

  // Helper method to parse hex color from string
  Color _parseHexColor(String hexString) {
    try {
      final hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return Colors.yellow; // Default color
    } catch (e) {
      return Colors.yellow; // Default color
    }
  }

  // Helper method to remove specific formatting
  String _removeSpecificFormatting(String content, EditedParagraphLink link) {
    // This is a simplified version - in a real app you'd want more sophisticated HTML manipulation
    final linkText = link.text;
    final colorHex = link.color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();

    // Remove the specific span tag for this text and color
    final spanPattern =
        '<span style="background-color:#$colorHex;">$linkText</span>';
    final spanPattern2 =
        '<span[^>]*background-color:#$colorHex[^>]*>$linkText</span>';

    // Remove the specific u tag for this text and color
    final underlinePattern =
        '<u style="text-decoration-color:#$colorHex;">$linkText</u>';
    final underlinePattern2 =
        '<u[^>]*text-decoration-color:#$colorHex[^>]*>$linkText</u>';

    String result = content.replaceAll(spanPattern, linkText);
    result = result.replaceAll(RegExp(spanPattern2), linkText);
    result = result.replaceAll(underlinePattern, linkText);
    result = result.replaceAll(RegExp(underlinePattern2), linkText);

    return result;
  }

  // Helper method to check if content still has formatting
  bool _hasAnyFormatting(String content) {
    return content.contains(RegExp(r'<span[^>]*background-color:[^>]*>')) ||
        content.contains(RegExp(r'<u[^>]*text-decoration-color:[^>]*>')) ||
        content.contains('<span') ||
        content.contains('<u') ||
        content.contains('<mark');
  }
}
