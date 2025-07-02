import '../entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getAllNotes();
  Future<List<Note>> getNotesByChapter(int chapterId);
  Future<void> deleteNote(Note note);
  Future<void> deleteNoteById(int paragraphId);
}
