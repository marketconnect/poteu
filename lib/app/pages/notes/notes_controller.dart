import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/usecases/get_notes_usecase.dart';
import '../../../domain/usecases/delete_note_usecase.dart';
import '../../../domain/repositories/notes_repository.dart';
import 'dart:developer' as dev;

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
    dev.log('=== NOTES CONTROLLER INITIALIZATION ===');
    dev.log('Creating use cases...');
    _getNotesUseCase = GetNotesUseCase(_notesRepository);
    _deleteNoteUseCase = DeleteNoteUseCase(_notesRepository);
    dev.log('Use cases created successfully');
    dev.log('Starting initial notes load...');
    refreshNotes();
  }

  Future<void> _loadNotes() async {
    dev.log('\n=== LOADING NOTES ===');
    dev.log('Current state:');
    dev.log('  Loading: $_isLoading');
    dev.log('  Error: $_error');
    dev.log('  Sort by color: $_sortByColor');
    dev.log('  Current notes count: ${_notes.length}');

    _isLoading = true;
    _error = null;
    refreshUI();

    try {
      dev.log('Executing GetNotesUseCase...');
      _getNotesUseCase.execute(
        _GetNotesObserver(this),
        GetNotesParams(sortByColor: _sortByColor),
      );
      dev.log('GetNotesUseCase execution started');
    } catch (e, stack) {
      dev.log('❌ Error loading notes:');
      dev.log('Error: $e');
      dev.log('Stack trace: $stack');
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    }
  }

  Future<void> toggleSortMode() async {
    dev.log('=== TOGGLE SORT MODE ===');
    dev.log('Before: sortByColor = $_sortByColor');
    _sortByColor = !_sortByColor;
    dev.log('After: sortByColor = $_sortByColor');
    await _loadNotes();
  }

  Future<void> setSortByDate() async {
    dev.log('=== SET SORT BY DATE ===');
    _sortByColor = false;
    await _loadNotes();
  }

  Future<void> setSortByColor() async {
    dev.log('=== SET SORT BY COLOR ===');
    _sortByColor = true;
    await _loadNotes();
  }

  Future<void> deleteNote(Note note) async {
    dev.log('=== DELETE NOTE ===');
    dev.log('Deleting note: ${note.link.text}');

    try {
      _deleteNoteUseCase.execute(
        _DeleteNoteObserver(this),
        DeleteNoteParams(note: note),
      );
    } catch (e) {
      dev.log('Error deleting note: $e');
      _error = 'Ошибка удаления заметки: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> refreshNotes() async {
    dev.log('=== REFRESH NOTES ===');
    await _loadNotes();
  }

  void _onNotesLoaded(List<Note> notes) {
    dev.log('=== NOTES LOADED ===');
    dev.log('Loaded ${notes.length} notes');
    _notes = notes;
    _isLoading = false;
    _error = null;
    refreshUI();
  }

  void _onNotesError(dynamic error) {
    dev.log('=== NOTES ERROR ===');
    dev.log('Error: $error');
    _error = error.toString();
    _isLoading = false;
    refreshUI();
  }

  void _onNoteDeleted() {
    dev.log('=== NOTE DELETED ===');
    // Reload notes after successful deletion
    _loadNotes();
  }

  void _onDeleteError(dynamic error) {
    dev.log('=== DELETE ERROR ===');
    dev.log('Error: $error');
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
