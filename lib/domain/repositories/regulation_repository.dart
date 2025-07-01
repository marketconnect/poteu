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
}
