import '../entities/regulation.dart';
import '../entities/chapter.dart';
import '../entities/paragraph.dart';

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
  Future<List<Map<String, dynamic>>> searchChapters(String query);
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum);
  Future<List<Map<String, dynamic>>> getTableOfContents();
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
}
