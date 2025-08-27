import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/pages/chapter/model/chapter_arguments.dart';
import 'package:poteu/config.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/usecases/get_notes_usecase.dart';
import '../../../domain/usecases/delete_note_usecase.dart';
import '../../../domain/repositories/notes_repository.dart';
import 'dart:developer' as dev;

class NotesController extends Controller {
  final NotesRepository _notesRepository;
  final SubscriptionRepository _subscriptionRepository;

  late GetNotesUseCase _getNotesUseCase;
  late DeleteNoteUseCase _deleteNoteUseCase;
  late CheckSubscriptionUseCase _checkSubscriptionUseCase;

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

  NotesController(this._notesRepository, this._subscriptionRepository) {
    dev.log('=== NOTES CONTROLLER INITIALIZATION ===');
    dev.log('Creating use cases...');
    _getNotesUseCase = GetNotesUseCase(_notesRepository);
    _deleteNoteUseCase = DeleteNoteUseCase(_notesRepository);
    _checkSubscriptionUseCase =
        CheckSubscriptionUseCase(_subscriptionRepository);
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
      _error = 'Произошла ошибка';
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
      _error = 'Ошибка удаления заметки';
      refreshUI();
    }
  }

  Future<void> refreshNotes() async {
    dev.log('=== REFRESH NOTES ===');
    await _loadNotes();
  }

  Future<void> handleNoteTap(Note note) async {
    // If the note is for the main document, navigate directly.
    if (note.regulationId == AppConfig.instance.regulationId) {
      _navigateToChapter(note);
      return;
    }

    // For other documents, check subscription.
    _isLoading = true;
    refreshUI();

    try {
      _checkSubscriptionUseCase.execute(
        _CheckSubscriptionObserver(this, note),
        null,
      );
    } catch (e) {
      _error = 'Ошибка проверки подписки';
    } finally {
      _isLoading = false;
      refreshUI();
    }
  }

  void _navigateToChapter(Note note) {
    dev.log('=== NAVIGATING TO CHAPTER ===');
    dev.log('Note chapterOrderNum: ${note.chapterOrderNum}');
    dev.log('Note originalParagraphId: ${note.originalParagraphId}');

    // Navigate to chapter with specific paragraph using ChapterArguments
    Navigator.pushNamed(
      getContext(),
      '/chapter',
      arguments: ChapterArguments(
        regulationId: note.regulationId,
        totalChapters: 6, // Would need to be dynamic in a real app
        chapterOrderNum:
            note.chapterOrderNum, // Use the correct chapter order number
        scrollTo:
            note.originalParagraphId, // Use originalParagraphId for scrolling
      ),
    );
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
    _error = 'Произошла ошибка';
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
    _error = 'Ошибка удаления';
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
    _checkSubscriptionUseCase.dispose();
    super.onDisposed();
  }
}

class _CheckSubscriptionObserver extends Observer<Subscription> {
  final NotesController _controller;
  final Note _note;
  _CheckSubscriptionObserver(this._controller, this._note);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _controller._error = 'Ошибка проверки подписки';
    // ignore: invalid_use_of_protected_member
    _controller.refreshUI();
  }

  @override
  void onNext(Subscription? response) {
    if (response != null && response.isActive) {
      _controller._navigateToChapter(_note);
    } else {
      // ignore: invalid_use_of_protected_member
      Navigator.pushNamed(_controller.getContext(), '/subscription');
    }
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
