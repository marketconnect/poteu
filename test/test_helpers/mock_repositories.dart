import 'dart:async';
import 'package:poteu/domain/repositories/regulation_repository.dart';
import 'package:poteu/domain/repositories/settings_repository.dart';
import 'package:poteu/domain/repositories/tts_repository.dart';
import 'package:poteu/domain/repositories/notes_repository.dart';
import 'package:poteu/domain/entities/regulation.dart';
import 'package:poteu/domain/entities/chapter.dart';
import 'package:poteu/domain/entities/paragraph.dart';
import 'package:poteu/domain/entities/note.dart';
import 'package:poteu/domain/entities/search_result.dart';
import 'package:poteu/domain/entities/settings.dart';
import 'package:poteu/domain/entities/tts_state.dart';
import 'test_data_helper.dart';
import 'package:flutter/foundation.dart';

/// Mock regulation repository for testing
@visibleForTesting
class MockRegulationRepository implements RegulationRepository {
  bool _shouldReturnError = false;
  bool _isLoading = false;

  // State
  List<Regulation> _regulations = [];
  Settings _currentSettings = TestDataHelper.createTestSettings();

  MockRegulationRepository() {
    _regulations = [TestDataHelper.createTestRegulation()];
  }

  void setShouldReturnError(bool shouldError) {
    _shouldReturnError = shouldError;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_shouldReturnError) {
      throw Exception(TestDataHelper.createErrorMessage('загрузка данных'));
    }
  }

  @override
  Future<List<Regulation>> getRegulations() async {
    await _simulateDelay();
    return _regulations;
  }

  @override
  Future<Regulation?> getRegulation(int id) async {
    await _simulateDelay();
    try {
      return _regulations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> toggleFavorite(int id) async {
    await _simulateDelay();
    final index = _regulations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _regulations[index] = _regulations[index].copyWith(
        isFavorite: !_regulations[index].isFavorite,
      );
    }
  }

  @override
  Future<List<Regulation>> getFavorites() async {
    await _simulateDelay();
    return _regulations.where((r) => r.isFavorite).toList();
  }

  @override
  Future<void> downloadRegulation(int id) async {
    await _simulateDelay();
    final index = _regulations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _regulations[index] = _regulations[index].copyWith(isDownloaded: true);
    }
  }

  @override
  Future<void> deleteRegulation(int id) async {
    await _simulateDelay();
    _regulations.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<Regulation>> searchRegulations(String query) async {
    await _simulateDelay();
    if (query.isEmpty) return _regulations;
    return _regulations
        .where((r) => r.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableOfContents() async {
    if (_shouldReturnError) {
      throw Exception('Ошибка при выполнении операции: оглавление');
    }
    return [
      {'id': 1, 'title': 'Общие положения'},
      {'id': 2, 'title': 'Требования к персоналу'},
      {'id': 3, 'title': 'Электроустановки'},
      {'id': 4, 'title': 'Средства защиты'},
      {'id': 5, 'title': 'Организация работ'},
      {'id': 6, 'title': 'Заключительные положения'},
    ];
  }

  @override
  Future<Map<String, dynamic>> getChapter(int chapterId) async {
    if (_shouldReturnError) {
      throw Exception('Ошибка при выполнении операции: глава');
    }
    return {
      'id': chapterId,
      'title': 'Общие положения',
      'paragraphs': [
        {
          'id': 1,
          'text':
              'Настоящие Правила устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
        }
      ],
    };
  }

  @override
  Future<List<Chapter>> getChapters(int regulationId) async {
    await _simulateDelay();
    return TestDataHelper.createTestChapters();
  }

  @override
  Future<List<Chapter>> getChaptersByParentId(int parentId) async {
    await _simulateDelay();
    return TestDataHelper.createTestChapters()
        .where((c) => c.level > 1)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> searchChapters(String query) async {
    await _simulateDelay();
    final chapters = TestDataHelper.createTestChapters();
    return chapters
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .map((c) => c.toMap())
        .toList();
  }

  @override
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum) async {
    await _simulateDelay();
    return TestDataHelper.createTestParagraphs(chapterId: chapterOrderNum);
  }

  @override
  Future<void> saveNote(int chapterId, String note) async {
    await _simulateDelay();
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes() async {
    await _simulateDelay();
    return TestDataHelper.createTestNotes()
        .map((note) => {
              'paragraphId': note.paragraphId,
              'originalParagraphId': note.originalParagraphId,
              'chapterId': note.chapterId,
              'chapterOrderNum': note.chapterOrderNum,
              'regulationTitle': note.regulationTitle,
              'chapterName': note.chapterName,
              'content': note.content,
              'lastTouched': note.lastTouched.toIso8601String(),
              'isEdited': note.isEdited,
              'link': {
                'color': note.link.color.value,
                'text': note.link.text,
              },
            })
        .toList();
  }

  @override
  Future<void> deleteNote(int noteId) async {
    await _simulateDelay();
  }

  @override
  Future<void> updateParagraph(
      int paragraphId, Map<String, dynamic> data) async {
    await _simulateDelay();
  }

  @override
  Future<void> saveParagraphEdit(int paragraphId, String editedContent) async {
    await _simulateDelay();
  }

  @override
  Future<void> saveParagraphNote(int paragraphId, String note) async {
    await _simulateDelay();
  }

  @override
  Future<void> updateParagraphHighlight(
      int paragraphId, String highlightData) async {
    await _simulateDelay();
  }

  @override
  Future<List<Paragraph>> applyParagraphEdits(
      List<Paragraph> originalParagraphs) async {
    await _simulateDelay();
    return originalParagraphs;
  }

  @override
  Future<bool> hasParagraphEdits(int originalParagraphId) async {
    await _simulateDelay();
    return false;
  }

  @override
  Future<Map<String, dynamic>?> getParagraphEdit(
      int originalParagraphId) async {
    await _simulateDelay();
    return null;
  }

  @override
  Future<void> saveParagraphEditByOriginalId(
      int originalId, String content, Paragraph originalParagraph) async {
    await _simulateDelay();
  }

  @override
  Future<List<SearchResult>> searchInRegulation({
    required int regulationId,
    required String query,
  }) async {
    await _simulateDelay();
    return TestDataHelper.createTestSearchResults(query);
  }

  @override
  Future<void> saveEditedParagraph(int paragraphId, String editedContent,
      Paragraph originalParagraph) async {
    await _simulateDelay();
  }

  @override
  Future<void> updateRegulation(Regulation regulation) async {
    await _simulateDelay();
    final index = _regulations.indexWhere((r) => r.id == regulation.id);
    if (index != -1) {
      _regulations[index] = regulation;
    }
  }

  @override
  Future<void> deleteNoteById(int noteId) async {
    await _simulateDelay();
  }

  @override
  Future<void> updateNote(Note note) async {
    await _simulateDelay();
  }
}

/// Mock settings repository for testing
@visibleForTesting
class MockSettingsRepository implements SettingsRepository {
  bool _shouldReturnError = false;
  Settings _currentSettings = TestDataHelper.createTestSettings();

  void setShouldReturnError(bool shouldError) {
    _shouldReturnError = shouldError;
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_shouldReturnError) {
      throw Exception(TestDataHelper.createErrorMessage('настройки'));
    }
  }

  @override
  Future<Settings> getSettings() async {
    await _simulateDelay();
    return _currentSettings;
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    await _simulateDelay();
    _currentSettings = settings;
  }

  @override
  Future<void> setTheme(bool isDarkMode) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(isDarkMode: isDarkMode);
  }

  @override
  Future<void> setFontSize(double fontSize) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(fontSize: fontSize);
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(isSoundEnabled: enabled);
  }

  @override
  Future<void> setHighlightColors(List<int> colors) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(highlightColors: colors);
  }

  @override
  Future<void> setLanguage(String language) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(language: language);
  }

  @override
  Future<void> setColors(Map<String, String> colors) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(
      highlightColors: colors.values.map((c) => int.parse(c)).toList(),
    );
  }

  @override
  Future<void> setDarkTheme(bool isDark) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(isDarkMode: isDark);
  }

  @override
  Future<void> setSpeechRate(double speechRate) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(speechRate: speechRate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(pitch: pitch);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(volume: volume);
  }

  @override
  Future<void> setVoiceId(String voiceId) async {
    await _simulateDelay();
    _currentSettings = _currentSettings.copyWith(voiceId: voiceId);
  }
}

/// Mock TTS repository for testing
@visibleForTesting
class MockTTSRepository implements TTSRepository {
  bool _shouldReturnError = false;
  final _stateController = StreamController<TtsState>.broadcast();
  TtsState _currentState = TtsState.stopped;

  void setShouldReturnError(bool shouldError) {
    _shouldReturnError = shouldError;
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_shouldReturnError) {
      throw Exception(TestDataHelper.createErrorMessage('TTS'));
    }
  }

  void _updateState(TtsState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> speak(String text) async {
    await _simulateDelay();
    _updateState(TtsState.playing);
    // Simulate speaking duration
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> stop() async {
    await _simulateDelay();
    _updateState(TtsState.stopped);
  }

  @override
  Future<void> pause() async {
    await _simulateDelay();
    _updateState(TtsState.paused);
  }

  @override
  Future<void> resume() async {
    await _simulateDelay();
    _updateState(TtsState.playing);
  }

  @override
  Future<void> setLanguage(String language) async {
    await _simulateDelay();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _simulateDelay();
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _simulateDelay();
  }

  @override
  Future<void> setRate(double rate) async {
    await _simulateDelay();
  }

  @override
  Future<List<String>> getLanguages() async {
    await _simulateDelay();
    return ['ru-RU', 'en-US'];
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    await _simulateDelay();
    return ['ru-RU', 'en-US'].contains(language);
  }

  @override
  Future<List<dynamic>> getVoices() async {
    await _simulateDelay();
    return [
      {'name': 'Russian Voice', 'locale': 'ru-RU'},
      {'name': 'English Voice', 'locale': 'en-US'}
    ];
  }

  @override
  Future<void> setVoice(String voice) async {
    await _simulateDelay();
  }

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }
}

/// Mock notes repository for testing
@visibleForTesting
class MockNotesRepository implements NotesRepository {
  bool _shouldReturnError = false;
  List<Note> _notes = [];

  MockNotesRepository() {
    _notes = TestDataHelper.createTestNotes();
  }

  void setShouldReturnError(bool shouldError) {
    _shouldReturnError = shouldError;
  }

  void clearNotes() {
    _notes.clear();
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_shouldReturnError) {
      throw Exception(TestDataHelper.createErrorMessage('заметки'));
    }
  }

  @override
  Future<List<Note>> getAllNotes() async {
    await _simulateDelay();
    return _notes;
  }

  @override
  Future<List<Note>> getNotesByChapter(int chapterId) async {
    await _simulateDelay();
    return _notes.where((n) => n.chapterId == chapterId).toList();
  }

  @override
  Future<void> addNote(Note note) async {
    await _simulateDelay();
    _notes.add(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    await _simulateDelay();
    final index = _notes.indexWhere((n) => n.paragraphId == note.paragraphId);
    if (index != -1) {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(Note note) async {
    await _simulateDelay();
    _notes.removeWhere((n) => n.paragraphId == note.paragraphId);
  }

  @override
  Future<void> deleteNoteById(int paragraphId) async {
    await _simulateDelay();
    _notes.removeWhere((n) => n.paragraphId == paragraphId);
  }
}

/// Container class for all mock repositories
class MockRepositories {
  final MockRegulationRepository regulationRepository;
  final MockSettingsRepository settingsRepository;
  final MockTTSRepository ttsRepository;
  final MockNotesRepository notesRepository;

  MockRepositories()
      : regulationRepository = MockRegulationRepository(),
        settingsRepository = MockSettingsRepository(),
        ttsRepository = MockTTSRepository(),
        notesRepository = MockNotesRepository();

  /// Sets all repositories to return errors for error testing
  void setAllShouldReturnError(bool shouldError) {
    (regulationRepository as MockRegulationRepository)
        .setShouldReturnError(shouldError);
    (settingsRepository as MockSettingsRepository)
        .setShouldReturnError(shouldError);
    (ttsRepository as MockTTSRepository).setShouldReturnError(shouldError);
    (notesRepository as MockNotesRepository).setShouldReturnError(shouldError);
  }

  /// Disposes of all resources
  Future<void> dispose() async {
    await ttsRepository.dispose();
  }
}
