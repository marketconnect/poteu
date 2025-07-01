import '../entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<void> saveNote(int chapterId, String note);
  Future<void> deleteNote(int noteId);
  Future<void> updateNote(int noteId, String note);
}
