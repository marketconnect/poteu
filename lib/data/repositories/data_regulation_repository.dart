import "../../domain/entities/regulation.dart";
import "../../domain/entities/chapter.dart";
import "../../domain/entities/paragraph.dart";
import "../../domain/repositories/regulation_repository.dart";
import "../../domain/entities/search_result.dart";
import "../helpers/duckdb_provider.dart";
import 'dart:developer' as dev;
import "dart:async";

class DataRegulationRepository implements RegulationRepository {
  final DuckDBProvider _dbProvider = DuckDBProvider.instance;

  DataRegulationRepository();

  @override
  Future<List<Regulation>> getRegulations() async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<Regulation> getRegulation(int id) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<void> toggleFavorite(int regulationId) async {
    // This functionality might need to be re-evaluated with DuckDB.
    // For now, it's a no-op as it modifies the static data.
  }

  @override
  Future<List<Regulation>> getFavorites() async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<void> downloadRegulation(int regulationId) async {
    // This functionality might need to be re-evaluated with DuckDB.
    // For now, it's a no-op as it modifies the static data.
  }

  @override
  Future<void> deleteRegulation(int regulationId) async {
    // This functionality might need to be re-evaluated with DuckDB.
    // For now, it's a no-op as it modifies the static data.
  }

  @override
  Future<List<Regulation>> searchRegulations(String query) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<Map<String, dynamic>> getChapter(int id) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<List<Chapter>> getChapters(int regulationId) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<List<Chapter>> getChaptersByParentId(int parentId) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<List<Chapter>> getTableOfContents() async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<List<Map<String, dynamic>>> searchChapters(String query) async {
    throw UnimplementedError(
        "Read operations should be handled by StaticRegulationRepository");
  }

  @override
  Future<void> saveNote(int chapterId, String note) async {
    throw UnimplementedError("Use saveParagraphNote instead");
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes() async {
    throw UnimplementedError("Handled by DataNotesRepository");
  }

  @override
  Future<void> deleteNote(int noteId) async {
    throw UnimplementedError("Handled by DataNotesRepository");
  }

  @override
  Future<void> updateParagraph(
      int paragraphId, Map<String, dynamic> data) async {
    try {
      dev.log('=== UPDATE PARAGRAPH ===');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Data: $data');

      // This is a generic update, let's implement it for DuckDB
      final conn = await _dbProvider.connection;
      // This is risky without knowing what's in `data`.
      // A better approach is specific methods like saveParagraphNote.
      // For now, we assume it contains 'content' or 'note'.
      final content = data['content'];
      final note = data['note'];

      dev.log('Content: $content');
      dev.log('Note: $note');

      await conn.query(
        '''
        INSERT INTO user_paragraph_edits (original_id, content, note, updated_at)
        VALUES ($paragraphId, '$content', '$note', NOW())
        ON CONFLICT (original_id) DO UPDATE SET
          content = EXCLUDED.content,
          note = EXCLUDED.note,
          updated_at = NOW();
        ''',
      );

      dev.log('✅ Paragraph updated successfully');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR updating paragraph:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Data: $data');
      rethrow;
    }
  }

  @override
  Future<void> saveParagraphEdit(int paragraphId, String editedContent) async {
    try {
      dev.log('=== SAVE PARAGRAPH EDIT ===');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Edited content length: ${editedContent.length}');
      dev.log(
          'Content preview: "${editedContent.substring(0, editedContent.length > 100 ? 100 : editedContent.length)}..."');

      await saveEditedParagraph(paragraphId, editedContent,
          Paragraph(id: 0, originalId: 0, chapterId: 0, num: 0, content: ''));

      dev.log('✅ Paragraph edit saved successfully');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR saving paragraph edit:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Content length: ${editedContent.length}');
      rethrow;
    }
  }

  @override
  Future<void> saveParagraphNote(int paragraphId, String note) async {
    try {
      dev.log('=== SAVE PARAGRAPH NOTE ===');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Note: "$note"');
      dev.log('Note length: ${note.length}');

      final conn = await _dbProvider.connection;
      await conn.query(
        '''
        INSERT INTO user_paragraph_edits (original_id, note, updated_at)
        VALUES ($paragraphId, '$note', NOW())
        ON CONFLICT (original_id) DO UPDATE SET
          note = EXCLUDED.note,
          updated_at = NOW();
        ''',
      );

      dev.log('✅ Paragraph note saved successfully');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR saving paragraph note:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Note: "$note"');
      rethrow;
    }
  }

  @override
  Future<void> updateParagraphHighlight(
      int paragraphId, String highlightData) async {
    try {
      dev.log('=== UPDATE PARAGRAPH HIGHLIGHT ===');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Highlight data: "$highlightData"');
      dev.log('Highlight data length: ${highlightData.length}');

      // The `highlight_data` column can be used for this.
      // This method seems to be from an older implementation.
      // We will assume it saves the highlight data as a string.
      final conn = await _dbProvider.connection;
      await conn.query(
        '''
        INSERT INTO user_paragraph_edits (original_id, highlight_data, updated_at)
        VALUES ($paragraphId, '$highlightData', NOW())
        ON CONFLICT (original_id) DO UPDATE SET
          highlight_data = EXCLUDED.highlight_data,
          updated_at = NOW();
        ''',
      );

      dev.log('✅ Paragraph highlight updated successfully');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR updating paragraph highlight:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Paragraph ID: $paragraphId');
      dev.log('Highlight data: "$highlightData"');
      rethrow;
    }
  }

  // Method to get saved paragraph edits and apply them to original paragraphs
  @override
  Future<List<Paragraph>> applyParagraphEdits(
      List<Paragraph> originalParagraphs) async {
    dev.log(
        '🔄 Применение форматирования для ${originalParagraphs.length} параграфов...');

    final conn = await _dbProvider.connection;
    final List<Paragraph> updatedParagraphs = [];

    // Получаем все original_id для одного запроса
    final originalIds = originalParagraphs.map((p) => p.originalId).toList();

    // Делаем один запрос для всех параграфов
    final result = await conn.query(
      'SELECT original_id, content, note FROM user_paragraph_edits WHERE original_id IN (${originalIds.join(',')})',
    );
    final savedEdits = result.fetchAll();

    dev.log(
        '📊 Найдено ${savedEdits.length} сохраненных форматирований в DuckDB');

    // Создаем Map для быстрого поиска
    final Map<int, Map<String, dynamic>> editsMap = {};
    for (final row in savedEdits) {
      editsMap[row[0] as int] = {'content': row[1], 'note': row[2]};
    }

    // Применяем форматирование
    for (final paragraph in originalParagraphs) {
      final savedEdit = editsMap[paragraph.originalId];

      if (savedEdit != null) {
        // Apply the saved formatting/content
        updatedParagraphs.add(paragraph.copyWith(
          content: savedEdit['content'] ?? paragraph.content,
          note: savedEdit['note'] ?? paragraph.note,
        ));
      } else {
        // No saved edits, use original
        updatedParagraphs.add(paragraph);
      }
    }

    dev.log(
        '✅ Форматирование применено к ${updatedParagraphs.length} параграфам');
    return updatedParagraphs;
  }

  // Method to check if a paragraph has saved edits
  @override
  Future<bool> hasParagraphEdits(int originalParagraphId) async {
    final conn = await _dbProvider.connection;
    final result = await conn.query(
        'SELECT 1 FROM user_paragraph_edits WHERE original_id = $originalParagraphId');
    return result.fetchAll().isNotEmpty;
  }

  // Method to get saved edit for a specific paragraph
  @override
  Future<Map<String, dynamic>?> getParagraphEdit(
      int originalParagraphId) async {
    final conn = await _dbProvider.connection;
    final result = await conn.query(
        'SELECT original_id, content, note, updated_at FROM user_paragraph_edits WHERE original_id = $originalParagraphId');
    final rows = result.fetchAll();
    if (rows.isNotEmpty) {
      final row = rows.first;
      return {
        'original_id': row[0],
        'content': row[1],
        'note': row[2],
        'updated_at': row[3],
      };
    }
    return null;
  }

  @override
  Future<List<SearchResult>> searchInRegulation({
    required int regulationId,
    required String query,
  }) async {
    if (query.isEmpty) return [];
    throw UnimplementedError("Search should be handled by Static repository");
  }

  @override
  Future<void> saveEditedParagraph(int paragraphId, String editedContent,
      Paragraph originalParagraph) async {
    await saveParagraphEditByOriginalId(
        paragraphId, editedContent, originalParagraph);
  }

  // Save paragraph edit by originalId, handling both create and update cases
  @override
  Future<void> saveParagraphEditByOriginalId(
      int originalId, String content, Paragraph originalParagraph) async {
    try {
      dev.log('=== SAVE PARAGRAPH EDIT BY ORIGINAL ID ===');
      dev.log('Original ID: $originalId');
      dev.log('Content length: ${content.length}');
      dev.log(
          'Content preview: "${content.substring(0, content.length > 200 ? 200 : content.length)}..."');
      dev.log('Chapter ID: ${originalParagraph.chapterId}');
      dev.log('Paragraph ID: ${originalParagraph.id}');

      final conn = await _dbProvider.connection;
      dev.log('✅ Database connection established');

      final query = '''
        INSERT INTO user_paragraph_edits (original_id, content, updated_at)
        VALUES ($originalId, '$content', NOW())
        ON CONFLICT (original_id) DO UPDATE SET
          content = EXCLUDED.content,
          updated_at = NOW();
      ''';

      dev.log('Executing query: $query');
      await conn.query(query);

      dev.log('✅ Сохранено в DuckDB для originalId: $originalId');
    } catch (e, stackTrace) {
      dev.log('❌ ERROR saving paragraph edit by original ID:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      dev.log('Original ID: $originalId');
      dev.log('Content length: ${content.length}');
      dev.log(
          'Content preview: "${content.substring(0, content.length > 200 ? 200 : content.length)}..."');
      dev.log('Chapter ID: ${originalParagraph.chapterId}');
      dev.log('Paragraph ID: ${originalParagraph.id}');
      rethrow;
    }
  }
}
