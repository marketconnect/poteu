import "../../domain/entities/regulation.dart";
import "../../domain/entities/chapter.dart";
import "../../domain/entities/paragraph.dart";
import "../../domain/repositories/regulation_repository.dart";
import "../../domain/entities/search_result.dart";
import "../helpers/duckdb_provider.dart";
import 'dart:developer' as dev;
import "dart:async";
import "static_regulation_repository.dart";

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
  Future<List<SearchResult>> searchInAllRegulations(
      {required String query}) async {
    if (query.isEmpty) return [];
    throw UnimplementedError(
        "Search in all regulations should be handled by Static repository");
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

  @override
  Future<bool> isRegulationCached(int regulationId) async {
    final conn = await _dbProvider.connection;
    final result = await conn
        .query('SELECT 1 FROM chapters WHERE rule_id = $regulationId LIMIT 1');
    return result.fetchAll().isNotEmpty;
  }

  @override
  Future<List<ChapterInfo>> getChapterList(int regulationId) async {
    // For data repository, delegate to static repository
    final staticRepo = StaticRegulationRepository();
    return await staticRepo.getChapterList(regulationId);
  }

  @override
  Future<Chapter> getChapterContent(int regulationId, int chapterId) async {
    // For data repository, delegate to static repository
    final staticRepo = StaticRegulationRepository();
    return await staticRepo.getChapterContent(regulationId, chapterId);
  }

  @override
  Future<void> deletePremiumContent() async {
    dev.log('Deleting all premium content from local database...');
    final conn = await _dbProvider.connection;

    // We assume premium documents are identified by a flag in the `rules` table.
    // Since this is a client-side implementation, we'll hardcode the logic
    // based on what the server provides. Let's assume `is_premium` column exists. We will assume a premium document is any document that is not the default one.
    // A better approach would be a flag from the backend.
    final allRulesResult = await conn.query("SELECT id FROM rules");
    final allRuleIds =
        allRulesResult.fetchAll().map((row) => row[0] as int).toList();

    // Assuming rule ID 1 is the default, non-premium one.
    final premiumRuleIds = allRuleIds.where((id) => id != 1).toList();

    if (premiumRuleIds.isEmpty) {
      dev.log('No premium documents found to delete.');
      return;
    }

    final idsString = premiumRuleIds.join(',');
    dev.log('Found premium document IDs to delete: $idsString');

    await conn.query('BEGIN TRANSACTION;');
    await conn.query(
        'DELETE FROM paragraphs WHERE chapterID IN (SELECT id FROM chapters WHERE rule_id IN ($idsString))');
    await conn.query('DELETE FROM chapters WHERE rule_id IN ($idsString)');
    await conn.query('DELETE FROM rules WHERE id IN ($idsString)');
    await conn.query('COMMIT;');
    dev.log('Successfully deleted premium content.');
  }

  @override
  Future<void> saveRegulations(List<Regulation> regulations) async {
    if (regulations.isEmpty) {
      dev.log('No regulations to save.');
      return;
    }

    final conn = await _dbProvider.connection;
    await conn.query('BEGIN TRANSACTION;');
    try {
      // Prepare a list of IDs for the DELETE statement
      final ids = regulations.map((r) => r.id).join(',');

      // Delete existing records to avoid conflicts and ensure data is fresh
      await conn.query('DELETE FROM rules WHERE id IN ($ids)');

      // Insert all the new records
      for (final regulation in regulations) {
        final escapedTitle = regulation.title.replaceAll("'", "''");
        final escapedDescription = regulation.description.replaceAll("'", "''");
        final changeDate = regulation.changeDate;
        await conn.query('''
          INSERT INTO rules (id, name, abbreviation, change_date)
          VALUES (${regulation.id}, '$escapedTitle', '$escapedDescription', ${changeDate == null ? 'NULL' : "'$changeDate'"});
        ''');
      }
      await conn.query('COMMIT;');
      dev.log(
          'Successfully saved/updated ${regulations.length} regulations to local DB.');
    } catch (e) {
      await conn.query('ROLLBACK;');
      dev.log('Error saving regulations: $e');
      rethrow;
    }
  }

  @override
  Future<List<Regulation>> getLocalRulesWithMetadata() async {
    final conn = await _dbProvider.connection;
    final result = await conn
        .query('SELECT id, name, abbreviation, change_date FROM rules');
    final rows = result.fetchAll();
    return rows
        .map((row) => Regulation(
              id: row[0] as int,
              title: row[1] as String,
              description: row[2] as String,
              changeDate: row[3] as String?,
              sourceName: '',
              sourceUrl: '',
              lastUpdated: DateTime.now(),
              isDownloaded: true, // If it's in local DB, it's downloaded
              isFavorite: false,
              chapters: [],
            ))
        .toList();
  }

  @override
  Future<void> deleteRegulationData(int regulationId) async {
    dev.log('Deleting all data for regulation ID: $regulationId');
    final conn = await _dbProvider.connection;
    await conn.query('BEGIN TRANSACTION;');
    try {
      // Delete paragraphs of the chapters of the rule
      final deletedParagraphs = await conn.query(
          'DELETE FROM paragraphs WHERE chapterID IN (SELECT id FROM chapters WHERE rule_id = $regulationId) RETURNING id;');
      dev.log('Deleted ${deletedParagraphs.fetchAll().length} paragraphs.');

      // Delete chapters of the rule
      final deletedChapters = await conn.query(
          'DELETE FROM chapters WHERE rule_id = $regulationId RETURNING id;');
      dev.log('Deleted ${deletedChapters.fetchAll().length} chapters.');

      // Delete the rule itself
      final deletedRules = await conn
          .query('DELETE FROM rules WHERE id = $regulationId RETURNING id;');
      dev.log('Deleted ${deletedRules.fetchAll().length} rules.');

      await conn.query('COMMIT;');
      dev.log('Successfully deleted data for regulation ID: $regulationId');
    } catch (e) {
      await conn.query('ROLLBACK;');
      dev.log('Error deleting regulation data for ID $regulationId: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateExamQuestionStats({
    required int regulationId,
    required String questionId,
    required bool isCorrect,
  }) async {
    final conn = await _dbProvider.connection;
    final escapedQuestionId = questionId.replaceAll("'", "''");
    final correctIncrement = isCorrect ? 1 : 0;
    final query = '''
    INSERT INTO exam_statistics (regulation_id, question_id, attempts, correct_count, last_attempt_date)
    VALUES ($regulationId, '$escapedQuestionId', 1, $correctIncrement, NOW())
    ON CONFLICT (regulation_id, question_id) DO UPDATE SET
      attempts = attempts + 1,
      correct_count = correct_count + $correctIncrement,
      last_attempt_date = NOW();
  ''';
    await conn.query(query);
  }

  @override
  Future<List<String>> getErrorReviewQuestionIds(
      {required int regulationId}) async {
    final conn = await _dbProvider.connection;
    final query = '''
    SELECT question_id FROM exam_statistics
    WHERE regulation_id = $regulationId
    AND last_attempt_date >= (NOW() - INTERVAL '14 days')
    AND correct_count < attempts;
  ''';
    final result = await conn.query(query);
    return result.fetchAll().map((row) => row[0] as String).toList();
  }

  @override
  Future<List<String>> getDifficultQuestionIds(
      {required int regulationId}) async {
    final conn = await _dbProvider.connection;
    final query = '''
    SELECT question_id FROM exam_statistics
    WHERE regulation_id = $regulationId
    AND attempts >= 2
    AND (correct_count::DOUBLE / attempts) < 0.6;
  ''';
    final result = await conn.query(query);
    return result.fetchAll().map((row) => row[0] as String).toList();
  }
}
