import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../helpers/duckdb_provider.dart';
import 'dart:developer' as dev;

class DataNotesRepository implements NotesRepository {
  final DuckDBProvider _dbProvider = DuckDBProvider.instance;

  DataNotesRepository() {
    _dbProvider.initialize();
  }

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      dev.log('=== GET ALL NOTES ===');

      final conn = await _dbProvider.connection;
      dev.log('✅ Database connection established');

      const query = '''
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

      dev.log('Executing query: $query');
      final result = await conn.query(query);

      final paragraphMaps = result.fetchAll();
      dev.log(
          'Found ${paragraphMaps.length} paragraphs with notes or formatting');

      final List<Note> notes = [];

      for (int i = 0; i < paragraphMaps.length; i++) {
        try {
          final paragraphMap = paragraphMaps[i];
          dev.log(
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

          dev.log('Paragraph ID: $originalId');
          dev.log('Chapter ID: $chapterId');
          dev.log('Content length: ${editedContent?.length ?? 0}');
          dev.log('Note: "$noteText"');
          dev.log('Chapter details:');
          dev.log('  Title: $chapterName');
          dev.log('  Order num: $chapterOrderNum');

          // First check for formatted links
          final links = editedContent != null
              ? _extractEditedParagraphLinks(editedContent)
              : <EditedParagraphLink>[];

          dev.log('Found ${links.length} formatted links');

          // Add formatted links as notes
          for (int j = 0; j < links.length; j++) {
            try {
              final link = links[j];
              dev.log(
                  '\n--- CREATING NOTE FROM FORMATTED LINK ${j + 1}/${links.length} ---');
              dev.log('Link text: "${link.text}"');
              dev.log('Link color: ${link.color}');

              // Check for duplicates before creating note
              bool isDuplicate = notes.any((existingNote) =>
                  existingNote.link.text == link.text &&
                  existingNote.link.color.value == link.color.value &&
                  existingNote.chapterId == chapterId);

              if (isDuplicate) {
                dev.log('⚠️ Skipping duplicate note: "${link.text}"');
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
              dev.log('✅ Successfully created formatted note');
              notes.add(note);
              dev.log('Added note to list. Current count: ${notes.length}');
            } catch (e, stackTrace) {
              dev.log('❌ ERROR creating formatted note ${j + 1}:');
              dev.log('Error: $e');
              dev.log('Stack trace: $stackTrace');
              dev.log('Paragraph data: $originalId');
              dev.log('Link data: ${links[j]}');
            }
          }

          // Then check for plain text note
          final plainNote = noteText;
          if (plainNote != null && plainNote.isNotEmpty) {
            try {
              dev.log('\n--- CREATING NOTE FROM PLAIN TEXT ---');
              dev.log('Note text: "$plainNote"');

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
                dev.log('⚠️ Skipping duplicate plain note: "$plainNote"');
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
              dev.log('✅ Successfully created plain note');
              notes.add(note);
            } catch (e, stackTrace) {
              dev.log('❌ ERROR creating plain note:');
              dev.log('Error: $e');
              dev.log('Stack trace: $stackTrace');
              dev.log('Paragraph data: $originalId');
            }
          }
        } catch (e, stackTrace) {
          dev.log('❌ ERROR processing paragraph ${i + 1}:');
          dev.log('Error: $e');
          dev.log('Stack trace: $stackTrace');
          dev.log('Paragraph data: ${paragraphMaps[i]}');
        }
      }

      dev.log('\n=== NOTES SUMMARY ===');
      dev.log('Total notes found: ${notes.length}');
      for (var i = 0; i < notes.length; i++) {
        dev.log('Note $i:');
        dev.log('  Text: "${notes[i].link.text}"');
        dev.log('  Chapter: ${notes[i].chapterName}');
        dev.log('  Is edited: ${notes[i].isEdited}');
      }

      return notes;
    } catch (e, stackTrace) {
      dev.log('❌ ERROR getting all notes:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
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
      dev.log('=== DELETE NOTE ===');
      dev.log('Note ID: ${note.originalParagraphId}');
      dev.log('Note text: "${note.link.text}"');
      dev.log('Is edited: ${note.isEdited}');
      dev.log('Chapter ID: ${note.chapterId}');
      dev.log('Chapter name: ${note.chapterName}');

      final conn = await _dbProvider.connection;
      dev.log('✅ Database connection established');

      final result = await conn.query(
        'SELECT content, note FROM user_paragraph_edits WHERE original_id = ${note.originalParagraphId}',
      );
      final rows = result.fetchAll();
      dev.log(
          'Found ${rows.length} existing records for paragraph ${note.originalParagraphId}');

      if (rows.isNotEmpty) {
        final row = rows.first;
        final currentContent = row[0] as String?;
        final currentNote = row[1] as String?;

        dev.log('Current content length: ${currentContent?.length ?? 0}');
        dev.log('Current note: "$currentNote"');

        String? newContent = currentContent;
        String? newNote = currentNote;

        // Remove the specific formatting for this note's link
        if (note.isEdited && newContent != null) {
          dev.log('Removing formatting for edited note');
          newContent = _removeSpecificFormatting(newContent, note.link);
          dev.log(
              'Content after formatting removal length: ${newContent.length}');
        }

        // Check if this is a plain text note that needs to be removed
        if (!note.isEdited && newNote != null && newNote == note.link.text) {
          dev.log('Removing plain text note');
          newNote = null;
        }

        final hasFormatting =
            newContent != null && _hasAnyFormatting(newContent);
        dev.log('Has remaining formatting: $hasFormatting');
        dev.log(
            'Has remaining notes: ${newNote != null && newNote.isNotEmpty}');

        if (hasFormatting || (newNote != null && newNote.isNotEmpty)) {
          // Still has other formatting or other notes, just update
          dev.log('Updating existing record with remaining content/notes');
          final query = '''
            INSERT INTO user_paragraph_edits (original_id, content, note, updated_at)
            VALUES (${note.originalParagraphId}, '${newContent ?? ''}', '${newNote ?? ''}', NOW())
            ON CONFLICT (original_id) DO UPDATE SET
              content = EXCLUDED.content,
              note = EXCLUDED.note,
              updated_at = NOW();
          ''';
          dev.log('Executing query: $query');
          await conn.query(query);
          dev.log('✅ Note updated successfully');
        } else {
          // No formatting or notes left, remove the edit entry entirely
          dev.log('No remaining content/notes, deleting entire record');
          await conn.query(
            'DELETE FROM user_paragraph_edits WHERE original_id = ${note.originalParagraphId}',
          );
          dev.log('✅ Note record deleted successfully');
        }
      } else {
        dev.log(
            '⚠️ No existing record found for paragraph ${note.originalParagraphId}');
      }
    } catch (e, stackTrace) {
      dev.log('❌ ERROR deleting note:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Note ID: ${note.originalParagraphId}');
      dev.log('Note text: "${note.link.text}"');
      dev.log('Is edited: ${note.isEdited}');
      dev.log('Chapter ID: ${note.chapterId}');
      rethrow;
    }
  }

  @override
  Future<void> deleteNoteById(int paragraphId) async {
    try {
      dev.log('=== DELETE NOTE BY ID ===');
      dev.log('Paragraph ID: $paragraphId');

      final conn = await _dbProvider.connection;
      dev.log('✅ Database connection established');

      await conn.query(
        'DELETE FROM user_paragraph_edits WHERE original_id = $paragraphId',
      );

      dev.log('✅ Note deleted successfully for paragraph ID: $paragraphId');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR deleting note by ID:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Paragraph ID: $paragraphId');
      rethrow;
    }
  }

  // Helper methods for extracting and managing formatted links
  List<EditedParagraphLink> _extractEditedParagraphLinks(String content) {
    dev.log('=== EXTRACTING EDITED PARAGRAPH LINKS ===');
    dev.log('Content length: ${content.length}');
    dev.log(
        'Content preview: "${content.substring(0, content.length > 200 ? 200 : content.length)}..."');

    final links = <EditedParagraphLink>[];

    // Extract highlighted text (span tags with background-color)
    final spanRegex = RegExp(
        r'<span[^>]*style="[^"]*background-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</span>');
    final spanMatches = spanRegex.allMatches(content);
    dev.log('Found ${spanMatches.length} span matches');

    for (final match in spanMatches) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (colorHex != null && text != null && text.isNotEmpty) {
        try {
          final color = _parseColor(colorHex);
          links.add(EditedParagraphLink(text: text, color: color));
          dev.log('Found highlighted text: "$text" with color: $colorHex');
        } catch (e) {
          dev.log('Error parsing color: $colorHex');
        }
      }
    }

    // Extract underlined text (u tags with text-decoration-color)
    final underlineRegex = RegExp(
        r'<u[^>]*style="[^"]*text-decoration-color:\s*([^;"]+)[^"]*"[^>]*>([^<]+)</u>');
    final underlineMatches = underlineRegex.allMatches(content);
    dev.log('Found ${underlineMatches.length} underline matches');

    for (final match in underlineMatches) {
      final colorHex = match.group(1)?.trim();
      final text = match.group(2)?.trim();

      if (colorHex != null && text != null && text.isNotEmpty) {
        try {
          final color = _parseColor(colorHex);
          links.add(EditedParagraphLink(text: text, color: color));
          dev.log('Found underlined text: "$text" with color: $colorHex');
        } catch (e) {
          dev.log('Error parsing color: $colorHex');
        }
      }
    }

    dev.log('Total formatted links found: ${links.length}');
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
