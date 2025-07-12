import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/usecases/get_notes_usecase.dart';
import '../../../domain/usecases/delete_note_usecase.dart';
import '../../../domain/repositories/notes_repository.dart';

class NotesController extends Controller {
  final NotesRepository _notesRepository;

  late GetNotesUseCase _getNotesUseCase;
  late DeleteNoteUseCase _deleteNoteUseCase;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  bool _sortByColor = false;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get sortByColor => _sortByColor;
  bool get hasNotes => _notes.isNotEmpty;

  NotesController(this._notesRepository) {
    print('=== NOTES CONTROLLER INITIALIZATION ===');
    print('Creating use cases...');
    _getNotesUseCase = GetNotesUseCase(_notesRepository);
    _deleteNoteUseCase = DeleteNoteUseCase(_notesRepository);
    print('Use cases created successfully');
    print('Starting initial notes load...');
    refreshNotes();
  }

  Future<void> _loadNotes() async {
    print('\n=== LOADING NOTES ===');
    print('Current state:');
    print('  Loading: $_isLoading');
    print('  Error: $_error');
    print('  Sort by color: $_sortByColor');
    print('  Current notes count: ${_notes.length}');

    _isLoading = true;
    _error = null;
    refreshUI();

    try {
      print('Executing GetNotesUseCase...');
      _getNotesUseCase.execute(
        _GetNotesObserver(this),
        GetNotesParams(sortByColor: _sortByColor),
      );
      print('GetNotesUseCase execution started');
    } catch (e, stack) {
      print('❌ Error loading notes:');
      print('Error: $e');
      print('Stack trace: $stack');
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    }
  }

  Future<void> toggleSortMode() async {
    print('=== TOGGLE SORT MODE ===');
    print('Before: sortByColor = $_sortByColor');
    _sortByColor = !_sortByColor;
    print('After: sortByColor = $_sortByColor');
    await _loadNotes();
  }

  Future<void> setSortByDate() async {
    print('=== SET SORT BY DATE ===');
    _sortByColor = false;
    await _loadNotes();
  }

  Future<void> setSortByColor() async {
    print('=== SET SORT BY COLOR ===');
    _sortByColor = true;
    await _loadNotes();
  }

  Future<void> deleteNote(Note note) async {
    print('=== DELETE NOTE ===');
    print('Deleting note: ${note.link.text}');

    try {
      _deleteNoteUseCase.execute(
        _DeleteNoteObserver(this),
        DeleteNoteParams(note: note),
      );
    } catch (e) {
      print('Error deleting note: $e');
      _error = 'Ошибка удаления заметки: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> refreshNotes() async {
    print('=== REFRESH NOTES ===');
    await _loadNotes();
  }

  void _onNotesLoaded(List<Note> notes) {
    print('=== NOTES LOADED ===');
    print('Loaded ${notes.length} notes');
    _notes = notes;
    _isLoading = false;
    _error = null;
    refreshUI();
  }

  void _onNotesError(dynamic error) {
    print('=== NOTES ERROR ===');
    print('Error: $error');
    _error = error.toString();
    _isLoading = false;
    refreshUI();
  }

  void _onNoteDeleted() {
    print('=== NOTE DELETED ===');
    // Reload notes after successful deletion
    _loadNotes();
  }

  void _onDeleteError(dynamic error) {
    print('=== DELETE ERROR ===');
    print('Error: $error');
    _error = 'Ошибка удаления: ${error.toString()}';
    refreshUI();
  }

  @override
  void initListeners() {
    // Initialize listeners
  }

  @override
  void onDisposed() {
    _getNotesUseCase.dispose();
    _deleteNoteUseCase.dispose();
    super.onDisposed();
  }
}

// Observer for GetNotesUseCase
class _GetNotesObserver extends Observer<List<Note>> {
  final NotesController _controller;

  _GetNotesObserver(this._controller);

  @override
  void onComplete() {
    // Notes loaded successfully
  }

  @override
  void onError(e) {
    _controller._onNotesError(e);
  }

  @override
  void onNext(List<Note>? response) {
    if (response != null) {
      _controller._onNotesLoaded(response);
    }
  }
}

// Observer for DeleteNoteUseCase
class _DeleteNoteObserver extends Observer<void> {
  final NotesController _controller;

  _DeleteNoteObserver(this._controller);

  @override
  void onComplete() {
    _controller._onNoteDeleted();
  }

  @override
  void onError(e) {
    _controller._onDeleteError(e);
  }

  @override
  void onNext(void response) {
    // Not used for CompletableUseCase
  }
}
