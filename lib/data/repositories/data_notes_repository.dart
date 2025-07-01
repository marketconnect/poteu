import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../helpers/database_helper.dart';

class DataNotesRepository implements NotesRepository {
  final DatabaseHelper _db;

  DataNotesRepository(this._db);

  @override
  Future<List<Note>> getNotes() async {
    final maps = await _db.query('notes');
    return maps
        .map((map) => Note(
              id: map['id'] as int,
              chapterId: map['chapter_id'] as int,
              title: map['title'] as String? ?? 'Note',
              content: map['note'] as String,
              createdAt: DateTime.parse(map['created_at'] as String),
            ))
        .toList()
        .cast<Note>();
  }

  @override
  Future<void> saveNote(int chapterId, String note) async {
    await _db.insert('notes', {
      'chapter_id': chapterId,
      'title': 'Note',
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteNote(int noteId) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  @override
  Future<void> updateNote(int noteId, String note) async {
    await _db.update(
      'notes',
      {'note': note, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  @override
  Future<Note> getNote(int id) async {
    // TODO: Implement getNote
    throw UnimplementedError();
  }

  @override
  Future<List<Note>> getNotesByChapter(int chapterId) async {
    // TODO: Implement getNotesByChapter
    return [];
  }

  @override
  Future<Note> createNote(int chapterId, String text) async {
    // TODO: Implement createNote
    throw UnimplementedError();
  }
}
