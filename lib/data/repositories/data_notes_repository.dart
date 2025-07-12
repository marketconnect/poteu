import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../helpers/duckdb_provider.dart';

class DataNotesRepository implements NotesRepository {
  final DuckDBProvider _dbProvider = DuckDBProvider.instance;

  DataNotesRepository() {
    _dbProvider.initialize();
  }

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      print('=== GET ALL NOTES ===');

      final conn = await _dbProvider.connection;
      print('✅ Database connection established');

      final query = '''
        SELECT
          p.original_id,
          p.content,
          p.note,
          p.updated_at,
          c.id as chapter_id,
          c.orderNum as chapter_order_num,
          c.name as chapter_name,
          r.name as regulation_title,
          orig_p.content as original_content
        FROM user_paragraph_edits p
        JOIN paragraphs orig_p ON p.original_id = orig_p.id
        JOIN chapters c ON orig_p.chapterID = c.id
        JOIN rules r ON c.rule_id = r.id
      ''';

      print('Executing query: $query');
      final result = await conn.query(query);

      final paragraphMaps = result.fetchAll();
      print(
          'Found ${paragraphMaps.length} paragraphs with notes or formatting');

      final List<Note> notes = [];

      for (int i = 0; i < paragraphMaps.length; i++) {
        try {
          final paragraphMap = paragraphMaps[i];
          print(
              '\n=== PROCESSING PARAGRAPH ${i + 1}/${paragraphMaps.length} ===');

          final originalId = paragraphMap[0] as int;
          final editedContent = paragraphMap[1] as String?;
          final noteText = paragraphMap[2] as String?;
          final updatedAt = paragraphMap[3] as DateTime?;
          final chapterId = paragraphMap[4] as int;
          final chapterOrderNum = paragraphMap[5] as int;
          final chapterName = paragraphMap[6] as String;
          final regulationTitle = paragraphMap[7] as String;
          final originalContent = paragraphMap[8] as String;

          print('Paragraph ID: $originalId');
          print('Chapter ID: $chapterId');
          print('Content length: ${editedContent?.length ?? 0}');
          print('Note: "$noteText"');
          print('Chapter details:');
          print('  Title: $chapterName');
          print('  Order num: $chapterOrderNum');

          // First check for formatted links
          final links = editedContent != null
              ? _extractEditedParagraphLinks(editedContent)
              : <EditedParagraphLink>[];

          print('Found ${links.length} formatted links');

          // Add formatted links as notes
          for (int j = 0; j < links.length; j++) {
            try {
              final link = links[j];
              print(
                  '\n--- CREATING NOTE FROM FORMATTED LINK ${j + 1}/${links.length} ---');
              print('Link text: "${link.text}"');
              print('Link color: ${link.color}');

              // Check for duplicates before creating note
              bool isDuplicate = notes.any((existingNote) =>
                  existingNote.link.text == link.text &&
                  existingNote.link.color.value == link.color.value &&
                  existingNote.chapterId == chapterId);

              if (isDuplicate) {
                print('⚠️ Skipping duplicate note: "${link.text}"');
                continue;
              }

              final note = Note(
                paragraphId: originalId,
                originalParagraphId: originalId,
                chapterId: chapterId,
                chapterOrderNum: chapterOrderNum,
                regulationTitle: regulationTitle,
                chapterName: chapterName,
                content: editedContent ?? '',
                lastTouched: updatedAt ?? DateTime.now(),
                isEdited: true,
                link: link,
              );
              print('✅ Successfully created formatted note');
              notes.add(note);
              print('Added note to list. Current count: ${notes.length}');
            } catch (e, stackTrace) {
              print('❌ ERROR creating formatted note ${j + 1}:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
              print('Paragraph data: $originalId');
              print('Link data: ${links[j]}');
            }
          }

          // Then check for plain text note
          final plainNote = noteText;
          if (plainNote != null && plainNote.isNotEmpty) {
            try {
              print('\n--- CREATING NOTE FROM PLAIN TEXT ---');
              print('Note text: "$plainNote"');

              // Create a default link for plain text note
              final link = EditedParagraphLink(
                text: plainNote,
                color: Colors.yellow, // Default color for plain notes
              );

              // Check for duplicates
              bool isDuplicate = notes.any((existingNote) =>
                  existingNote.link.text == plainNote &&
                  existingNote.chapterId == chapterId);

              if (isDuplicate) {
                print('⚠️ Skipping duplicate plain note: "$plainNote"');
                continue;
              }

              final note = Note(
                paragraphId: originalId,
                originalParagraphId: originalId,
                chapterId: chapterId,
                chapterOrderNum: chapterOrderNum,
                regulationTitle: regulationTitle,
                chapterName: chapterName,
                content: originalContent,
                lastTouched: updatedAt ?? DateTime.now(),
                isEdited: false,
                link: link,
              );
              print('✅ Successfully created plain note');
              notes.add(note);
            } catch (e, stackTrace) {
              print('❌ ERROR creating plain note:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
              print('Paragraph data: $originalId');
            }
          }
        } catch (e, stackTrace) {
          print('❌ ERROR processing paragraph ${i + 1}:');
          print('Error: $e');
          print('Stack trace: $stackTrace');
          print('Paragraph data: ${paragraphMaps[i]}');
        }
      }

      print('\n=== NOTES SUMMARY ===');
      print('Total notes found: ${notes.length}');
      for (var i = 0; i < notes.length; i++) {
        print('Note $i:');
        print('  Text: "${notes[i].link.text}"');
        print('  Chapter: ${notes[i].chapterName}');
        print('  Is edited: ${notes[i].isEdited}');
      }

      return notes;
    } catch (e, stackTrace) {
      print('❌ ERROR getting all notes:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Note>> getNotesByChapter(int chapterId) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.chapterId == chapterId).toList();
  }

  @override
  Future<void> deleteNote(Note note) async {
    try {
      print('=== DELETE NOTE ===');
      print('Note ID: ${note.originalParagraphId}');
      print('Note text: "${note.link.text}"');
      print('Is edited: ${note.isEdited}');
      print('Chapter ID: ${note.chapterId}');
      print('Chapter name: ${note.chapterName}');

      final conn = await _dbProvider.connection;
      print('✅ Database connection established');

      final result = await conn.query(
        'SELECT content, note FROM user_paragraph_edits WHERE original_id = ${note.originalParagraphId}',
      );
      final rows = result.fetchAll();
      print(
          'Found ${rows.length} existing records for paragraph ${note.originalParagraphId}');

      if (rows.isNotEmpty) {
        final row = rows.first;
        final currentContent = row[0] as String?;
        final currentNote = row[1] as String?;

        print('Current content length: ${currentContent?.length ?? 0}');
        print('Current note: "$currentNote"');

        String? newContent = currentContent;
        String? newNote = currentNote;

        // Remove the specific formatting for this note's link
        if (note.isEdited && newContent != null) {
          print('Removing formatting for edited note');
          newContent = _removeSpecificFormatting(newContent, note.link);
          print(
              'Content after formatting removal length: ${newContent.length}');
        }

        // Check if this is a plain text note that needs to be removed
        if (!note.isEdited && newNote != null && newNote == note.link.text) {
          print('Removing plain text note');
          newNote = null;
        }

        final hasFormatting =
            newContent != null && _hasAnyFormatting(newContent);
        print('Has remaining formatting: $hasFormatting');
        print('Has remaining notes: ${newNote != null && newNote.isNotEmpty}');

        if (hasFormatting || (newNote != null && newNote.isNotEmpty)) {
          // Still has other formatting or other notes, just update
          print('Updating existing record with remaining content/notes');
          final query = '''
            INSERT INTO user_paragraph_edits (original_id, content, note, updated_at)
            VALUES (${note.originalParagraphId}, '${newContent ?? ''}', '${newNote ?? ''}', NOW())
            ON CONFLICT (original_id) DO UPDATE SET
              content = EXCLUDED.content,
              note = EXCLUDED.note,
              updated_at = NOW();
          ''';
          print('Executing query: $query');
          await conn.query(query);
          print('✅ Note updated successfully');
        } else {
          // No formatting or notes left, remove the edit entry entirely
          print('No remaining content/notes, deleting entire record');
          await conn.query(
            'DELETE FROM user_paragraph_edits WHERE original_id = ${note.originalParagraphId}',
          );
          print('✅ Note record deleted successfully');
        }
      } else {
        print(
            '⚠️ No existing record found for paragraph ${note.originalParagraphId}');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR deleting note:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('Note ID: ${note.originalParagraphId}');
      print('Note text: "${note.link.text}"');
      print('Is edited: ${note.isEdited}');
      print('Chapter ID: ${note.chapterId}');
      rethrow;
    }
  }

  @override
  Future<void> deleteNoteById(int paragraphId) async {
    try {
      print('=== DELETE NOTE BY ID ===');
      print('Paragraph ID: $paragraphId');

      final conn = await _dbProvider.connection;
      print('✅ Database connection established');

      await conn.query(
        'DELETE FROM user_paragraph_edits WHERE original_id = $paragraphId',
      );

      print('✅ Note deleted successfully for paragraph ID: $paragraphId');
    } catch (e, stackTrace) {
      print('❌ ERROR deleting note by ID:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('Paragraph ID: $paragraphId');
      rethrow;
    }
  }

  // Helper methods for extracting and managing formatted links
  List<EditedParagraphLink> _extractEditedParagraphLinks(String content) {
    print('=== EXTRACTING EDITED PARAGRAPH LINKS ===');
    print('Content length: ${content.length}');
    print(
        'Content preview: "${content.substring(0, content.length > 200 ? 200 : content.length)}..."');

    final links = <EditedParagraphLink>[];

    // Extract highlighted text (span tags with background-color)
    final spanRegex = RegExp(
        r'<span[^>]*style="[^"]*background-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</span>');
    final spanMatches = spanRegex.allMatches(content);
    print('Found ${spanMatches.length} span matches');

    for (final match in spanMatches) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (colorHex != null && text != null && text.isNotEmpty) {
        try {
          final color = _parseColor(colorHex);
          links.add(EditedParagraphLink(text: text, color: color));
          print('Found highlighted text: "$text" with color: $colorHex');
        } catch (e) {
          print('Error parsing color: $colorHex');
        }
      }
    }

    // Extract underlined text (u tags with text-decoration-color)
    final underlineRegex = RegExp(
        r'<u[^>]*style="[^"]*text-decoration-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</u>');
    final underlineMatches = underlineRegex.allMatches(content);
    print('Found ${underlineMatches.length} underline matches');

    for (final match in underlineMatches) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (colorHex != null && text != null && text.isNotEmpty) {
        try {
          final color = _parseColor(colorHex);
          links.add(EditedParagraphLink(text: text, color: color));
          print('Found underlined text: "$text" with color: $colorHex');
        } catch (e) {
          print('Error parsing color: $colorHex');
        }
      }
    }

    print('Total formatted links found: ${links.length}');
    return links;
  }

  Color _parseColor(String colorHex) {
    if (colorHex.startsWith('#')) {
      colorHex = colorHex.substring(1);
    }
    if (colorHex.length == 6) {
      return Color(int.parse('FF$colorHex', radix: 16));
    }
    throw FormatException('Invalid color format: $colorHex');
  }

  String _removeSpecificFormatting(String content, EditedParagraphLink link) {
    // Remove highlighted text (span tags)
    final spanRegex = RegExp(
        r'<span[^>]*style="[^"]*background-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</span>');
    content = content.replaceAllMapped(spanRegex, (match) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (text == link.text) {
        try {
          final color = _parseColor(colorHex!);
          if (color.value == link.color.value) {
            return text ?? ''; // Remove the span, keep only the text
          }
        } catch (e) {
          // If color parsing fails, keep the original
        }
      }
      return match.group(0) ?? ''; // Keep the original span
    });

    // Remove underlined text (u tags)
    final underlineRegex = RegExp(
        r'<u[^>]*style="[^"]*text-decoration-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</u>');
    content = content.replaceAllMapped(underlineRegex, (match) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (text == link.text) {
        try {
          final color = _parseColor(colorHex!);
          if (color.value == link.color.value) {
            return text ?? ''; // Remove the u tag, keep only the text
          }
        } catch (e) {
          // If color parsing fails, keep the original
        }
      }
      return match.group(0) ?? ''; // Keep the original u tag
    });

    return content;
  }

  bool _hasAnyFormatting(String content) {
    return content.contains('<span') || content.contains('<u>');
  }
}
