import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/repositories/notes_repository.dart';
import '../../../data/repositories/data_notes_repository.dart';
import '../../../data/helpers/database_helper.dart';

class NotesController extends Controller {
  final NotesRepository _notesRepository;

  bool _isLoading = true;
  String? _error;
  List<Note> _notes = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Note> get notes => _notes;

  NotesController(this._notesRepository) {
    loadNotes();
  }

  @override
  void initListeners() {}

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    _notes = [];
    refreshUI();

    try {
      _notes = await _notesRepository.getNotes();
      _isLoading = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _notesRepository.deleteNote(id);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void editNote(Note note) {
    // TODO: Implement note editing
  }
}
