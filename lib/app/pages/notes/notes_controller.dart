import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poteu/app/utils/text_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:poteu/app/pages/chapter/model/chapter_arguments.dart';
import 'package:poteu/config.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  bool _isSelectionMode = false;
  final Set<Note> _selectedNotes = {};

  Note? _lastDeletedNote;
  int? _lastDeletedNoteIndex;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get sortByColor => _sortByColor;
  bool get hasNotes => _notes.isNotEmpty;
  bool get isSelectionMode => _isSelectionMode;
  Set<Note> get selectedNotes => _selectedNotes;

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
      Sentry.captureException(e, stackTrace: stack);
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

  void deleteNote(Note note) {
    _lastDeletedNoteIndex = _notes.indexOf(note);
    if (_lastDeletedNoteIndex == -1) return;

    _lastDeletedNote = _notes.removeAt(_lastDeletedNoteIndex!);
    refreshUI();
  }

  void undoDelete() {
    if (_lastDeletedNote != null && _lastDeletedNoteIndex != null) {
      _notes.insert(_lastDeletedNoteIndex!, _lastDeletedNote!);
      _lastDeletedNote = null;
      _lastDeletedNoteIndex = null;
      refreshUI();
    }
  }

  void confirmDelete() {
    if (_lastDeletedNote == null) return;

    dev.log('=== DELETE NOTE ===');
    dev.log('Deleting note: ${_lastDeletedNote!.link.text}');

    try {
      _deleteNoteUseCase.execute(
        _DeleteNoteObserver(this),
        DeleteNoteParams(note: _lastDeletedNote!),
      );
      _lastDeletedNote = null;
      _lastDeletedNoteIndex = null;
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
    _navigateToChapter(note);
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
    // The note is already removed from the UI. No need to reload.
  }

  void _onDeleteError(dynamic error) {
    dev.log('=== DELETE ERROR ===');
    dev.log('Error: $error');
    _error = 'Ошибка удаления';
    refreshUI();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedNotes.clear();
    }
    refreshUI();
  }

  void toggleNoteSelection(Note note) {
    if (_selectedNotes.contains(note)) {
      _selectedNotes.remove(note);
    } else {
      _selectedNotes.add(note);
    }
    // If no notes are selected, exit selection mode
    if (_selectedNotes.isEmpty) {
      _isSelectionMode = false;
    }
    refreshUI();
  }

  Future<void> exportAndShareSelectedNotes() async {
    if (_selectedNotes.isEmpty) {
      return;
    }
    _isLoading = true;
    refreshUI();
    try {
      final pdf = pw.Document();
      final fontData =
          await rootBundle.load('assets/fonts/YandexSansText-Regular.ttf');
      final ttfFont = pw.Font.ttf(fontData);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _selectedNotes.map((note) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      TextUtils.parseHtmlString(note.content),
                      style: pw.TextStyle(font: ttfFont, fontSize: 14),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400, height: 15),
                    pw.Text(
                      'Документ: ${note.regulationTitle}',
                      style: pw.TextStyle(
                          font: ttfFont,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Глава: ${note.chapterName}',
                      style: pw.TextStyle(
                          font: ttfFont,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      );
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/notes_export.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: "Мои заметки");
      toggleSelectionMode();
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      _error =
          "Ошибка при создании PDF файла. Убедитесь, что шрифт 'assets/fonts/YandexSansText-Regular.ttf' существует.";
    } finally {
      _isLoading = false;
      refreshUI();
    }
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
