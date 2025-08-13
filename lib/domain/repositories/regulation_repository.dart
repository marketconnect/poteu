import '../entities/regulation.dart';
import '../entities/chapter.dart';
import '../entities/paragraph.dart';
import '../entities/search_result.dart';

abstract class RegulationRepository {
  Future<List<Regulation>> getRegulations();
  Future<Regulation?> getRegulation(int id);
  Future<void> toggleFavorite(int id);
  Future<List<Regulation>> getFavorites();
  Future<void> downloadRegulation(int id);
  Future<void> deleteRegulation(int id);
  Future<List<Regulation>> searchRegulations(String query);
  Future<Map<String, dynamic>> getChapter(int id);
  Future<List<Chapter>> getChapters(int regulationId);
  Future<List<Chapter>> getChaptersByParentId(int parentId);
  Future<List<ChapterInfo>> getChapterList(int regulationId);
  Future<Chapter> getChapterContent(int regulationId, int chapterId);
  Future<List<Map<String, dynamic>>> searchChapters(String query);
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum);
  Future<List<Chapter>> getTableOfContents();
  Future<void> saveNote(int chapterId, String note);
  Future<List<Map<String, dynamic>>> getNotes();
  Future<void> deleteNote(int noteId);

  // Add new methods for paragraph editing
  Future<void> updateParagraph(int paragraphId, Map<String, dynamic> data);
  Future<void> saveParagraphEdit(int paragraphId, String editedContent);
  Future<void> saveParagraphNote(int paragraphId, String note);
  Future<void> updateParagraphHighlight(int paragraphId, String highlightData);

  // Add new methods for loading saved edits
  Future<List<Paragraph>> applyParagraphEdits(
      List<Paragraph> originalParagraphs);
  Future<bool> hasParagraphEdits(int originalParagraphId);
  Future<Map<String, dynamic>?> getParagraphEdit(int originalParagraphId);
  Future<void> saveParagraphEditByOriginalId(
      int originalId, String content, Paragraph originalParagraph);

  Future<List<SearchResult>> searchInRegulation({
    required int regulationId,
    required String query,
  });

  Future<List<SearchResult>> searchInAllRegulations(
      {required String query});

  /// Saves edited paragraph content
  Future<void> saveEditedParagraph(
      int paragraphId, String editedContent, Paragraph originalParagraph);

  // Check if a regulation's data is cached locally
  Future<bool> isRegulationCached(int regulationId);

  // Deletes all content associated with premium documents
  Future<void> deletePremiumContent();

  // Saves a list of regulations (rules) to the local database
  Future<void> saveRegulations(List<Regulation> regulations);

  // Gets local rules with minimal metadata for sync purposes
  Future<List<Regulation>> getLocalRulesWithMetadata();

  // Deletes a single regulation and all its associated data (chapters, paragraphs)
  Future<void> deleteRegulationData(int regulationId);
}
