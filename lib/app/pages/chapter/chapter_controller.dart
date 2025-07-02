import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../domain/entities/formatting.dart';
import '../../../data/repositories/static_regulation_repository.dart';
import '../../../data/repositories/data_regulation_repository.dart';
import '../../../data/helpers/database_helper.dart';
import '../../utils/text_utils.dart';

class ChapterController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final StaticRegulationRepository _repository = StaticRegulationRepository();
  final DataRegulationRepository _dataRepository = DataRegulationRepository(
    DatabaseHelper(),
  );

  // PageView управление как в оригинале
  late PageController pageController;
  late TextEditingController pageTextController;

  Map<int, Map<String, dynamic>> _chaptersData = {};
  int _currentChapterOrderNum = 1;
  int _totalChapters = 0;
  bool _isLoading = false;
  String? _error;
  bool _isTTSPlaying = false;

  // Bottom Bar state management (like BottomBarCubit)
  bool _isBottomBarExpanded = false;
  bool _isBottomBarWhiteMode = false;

  // Text selection state (like SaveParagraphCubit)
  Paragraph? _selectedParagraph;
  int _selectionStart = 0;
  int _selectionEnd = 0;
  String _lastSelectedText = '';

  // Colors state management (like ColorsCubit)
  List<int> _colorsList = [
    0xFFFFFF00, // Yellow
    0xFFFF8C00, // Orange
    0xFF00FF00, // Green
    0xFF0000FF, // Blue
    0xFFFF1493, // Pink
    0xFF800080, // Purple
    0xFFFF0000, // Red
    0xFF00FFFF, // Cyan
  ];
  int _activeColorIndex = 0;

  // Getters
  Map<int, Map<String, dynamic>> get chaptersData => _chaptersData;
  int get currentChapterOrderNum => _currentChapterOrderNum;
  int get totalChapters => _totalChapters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTTSPlaying => _isTTSPlaying;

  // Bottom Bar getters
  bool get isBottomBarExpanded => _isBottomBarExpanded;
  bool get isBottomBarWhiteMode => _isBottomBarWhiteMode;

  // Selection getters
  Paragraph? get selectedParagraph => _selectedParagraph;
  int get selectionStart => _selectionStart;
  int get selectionEnd => _selectionEnd;
  String get lastSelectedText => _lastSelectedText;

  // Color getters
  List<int> get colorsList => _colorsList;
  int get activeColorIndex => _activeColorIndex;
  int get activeColor => _colorsList[_activeColorIndex];

  // Navigation getters
  bool get canGoPreviousChapter => _currentChapterOrderNum > 1;
  bool get canGoNextChapter => _currentChapterOrderNum < _totalChapters;

  ChapterController({
    required int regulationId,
    required int initialChapterOrderNum,
  })  : _regulationId = regulationId,
        _initialChapterOrderNum = initialChapterOrderNum,
        _currentChapterOrderNum = initialChapterOrderNum {
    print('=== CHAPTER CONTROLLER CONSTRUCTOR ===');
    print('regulationId: $regulationId');
    print('initialChapterOrderNum: $initialChapterOrderNum');

    pageController = PageController(initialPage: initialChapterOrderNum - 1);
    pageTextController = TextEditingController(
      text: initialChapterOrderNum.toString(),
    );

    print('PageController and TextController initialized');
    print('Calling loadAllChapters...');
    loadAllChapters();
  }

  Future<void> loadAllChapters() async {
    print('=== LOAD ALL CHAPTERS ===');
    print('Setting loading state...');
    _isLoading = true;
    refreshUI();

    try {
      print('Getting chapters from repository...');
      final chapters = await _repository.getChapters(_regulationId);
      _totalChapters = chapters.length;
      print('Got ${chapters.length} chapters');

      for (final chapter in chapters) {
        print('Processing chapter ${chapter.level}: ${chapter.title}');

        // Apply saved edits/formatting to paragraphs
        final updatedParagraphs =
            await _dataRepository.applyParagraphEdits(chapter.paragraphs);
        print(
            'Applied formatting to ${updatedParagraphs.length} paragraphs in chapter ${chapter.level}');

        _chaptersData[chapter.level] = {
          'id': chapter.id,
          'title': chapter.title,
          'content': chapter.content,
          'paragraphs':
              updatedParagraphs, // Use updated paragraphs with formatting
        };
      }

      print('Chapters data loaded successfully with formatting applied');
      _isLoading = false;
      refreshUI();
    } catch (e) {
      print('Error loading chapters: $e');
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    }
  }

  Map<String, dynamic>? getChapterData(int chapterOrderNum) {
    return _chaptersData[chapterOrderNum];
  }

  void onPageChanged(int newChapterOrderNum) {
    _currentChapterOrderNum = newChapterOrderNum;
    pageTextController.text = newChapterOrderNum.toString();
    refreshUI();
  }

  void goToChapter(int chapterOrderNum) {
    if (chapterOrderNum >= 1 && chapterOrderNum <= _totalChapters) {
      pageController.animateToPage(
        chapterOrderNum - 1,
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void goToPreviousChapter() {
    if (_currentChapterOrderNum > 1) {
      pageController.previousPage(
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void goToNextChapter() {
    if (_currentChapterOrderNum < _totalChapters) {
      pageController.nextPage(
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    }
  }

  // ========== BOTTOM BAR MANAGEMENT (like BottomBarCubit) ==========

  void toggleBottomBar() {
    print('=== TOGGLE BOTTOM BAR ===');
    print('Before: isBottomBarExpanded = $_isBottomBarExpanded');
    _isBottomBarExpanded = !_isBottomBarExpanded;
    print('After: isBottomBarExpanded = $_isBottomBarExpanded');
    refreshUI();
  }

  void expandBottomBar() {
    print('=== EXPAND BOTTOM BAR ===');
    print('Before: isBottomBarExpanded = $_isBottomBarExpanded');
    _isBottomBarExpanded = true;
    print('After: isBottomBarExpanded = $_isBottomBarExpanded');
    refreshUI();
  }

  void collapseBottomBar() {
    print('=== COLLAPSE BOTTOM BAR ===');
    print('Before: isBottomBarExpanded = $_isBottomBarExpanded');
    _isBottomBarExpanded = false;
    _isBottomBarWhiteMode = false;
    _selectedParagraph = null;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
    print('After: isBottomBarExpanded = $_isBottomBarExpanded');
    print('Cleared selection and text');
    refreshUI();
  }

  void switchToWhiteMode() {
    _isBottomBarWhiteMode = true;
    refreshUI();
  }

  void switchToBlackMode() {
    _isBottomBarWhiteMode = false;
    refreshUI();
  }

  // ========== TEXT SELECTION MANAGEMENT (like SaveParagraphCubit) ==========

  void setTextSelection(Paragraph paragraph, int start, int end) {
    try {
      _selectedParagraph = paragraph;

      // Ensure start is always less than end
      if (start > end) {
        int temp = start;
        start = end;
        end = temp;
      }

      _selectionStart = start;
      _selectionEnd = end;

      if (start < end && start >= 0) {
        String plainText = TextUtils.parseHtmlString(paragraph.content);

        // Enhanced validation for safety
        if (plainText.isNotEmpty &&
            start >= 0 &&
            start < plainText.length &&
            end > start &&
            end <= plainText.length) {
          try {
            _lastSelectedText = plainText.substring(start, end);
          } catch (e) {
            print(
                'Substring error: start=$start, end=$end, length=${plainText.length}');
            _lastSelectedText = '';
            _error = 'Ошибка выделения текста';
          }
        } else {
          print(
              'Invalid selection bounds: start=$start, end=$end, length=${plainText.length}');
          _lastSelectedText = '';
        }
      } else {
        _lastSelectedText = '';
      }

      _error = null; // Clear any previous errors
      refreshUI();
    } catch (e) {
      print('SetTextSelection error: $e');
      _lastSelectedText = '';
      _error = 'Ошибка при обработке выделения';
      refreshUI();
    }
  }

  void selectParagraphForFormatting(Paragraph paragraph) {
    print('=== SELECT PARAGRAPH FOR FORMATTING ===');
    print('Paragraph ID: ${paragraph.id}');
    print('Paragraph content: "${paragraph.content}"');
    _selectedParagraph = paragraph;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
    _isBottomBarExpanded = true;
    print('Paragraph selected, bottom bar expanded');
    refreshUI();
  }

  void clearSelection() {
    _selectedParagraph = null;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
    refreshUI();
  }

  // ========== FORMATTING ACTIONS (like SaveParagraphCubit) ==========

  Future<void> applyFormatting(Tag tag) async {
    try {
      print('=== APPLY FORMATTING START ===');
      print('Tag: $tag');

      if (_selectedParagraph == null) {
        print('ERROR: No paragraph selected');
        _error = 'Параграф не выбран';
        refreshUI();
        return;
      }

      print('Selected paragraph ID: ${_selectedParagraph!.id}');
      print('Original content: "${_selectedParagraph!.content}"');

      if (_selectionStart == _selectionEnd && tag != Tag.c) {
        print('ERROR: No text selected for formatting');
        _error = tag == Tag.m
            ? 'Вы не выделили участок параграфа, который собираетесь выделить.'
            : 'Вы не выделили участок параграфа, который собираетесь подчеркнуть.';
        refreshUI();
        return;
      }

      String content = _selectedParagraph!.content;

      if (tag == Tag.c) {
        // Clear all formatting - this is safe
        print('Clearing all formatting');
        content = TextUtils.removeAllFormatting(content);
        print('Content after clearing: "$content"');
      } else {
        // For text formatting, we need to be more careful about HTML vs plain text
        String plainText = TextUtils.parseHtmlString(content);
        print('Plain text extracted: "$plainText"');
        print('Plain text length: ${plainText.length}');

        if (plainText.isEmpty) {
          print('ERROR: Empty plain text');
          _error = 'Пустой текст параграфа';
          refreshUI();
          return;
        }

        // Validate selection bounds very carefully
        int start = _selectionStart;
        int end = _selectionEnd;

        if (start > end) {
          int temp = start;
          start = end;
          end = temp;
        }

        print('Final selection bounds: start=$start, end=$end');

        if (start >= 0 &&
            end > start &&
            start < plainText.length &&
            end <= plainText.length) {
          try {
            // Get the selected text from plain text
            String selectedText = plainText.substring(start, end);
            print('Selected text for formatting: "$selectedText"');

            // Create formatting tags
            String openTag =
                TextUtils.createOpenTag(tag, _colorsList[_activeColorIndex]);
            String closeTag = TextUtils.createCloseTag(tag);
            print('Open tag: "$openTag"');
            print('Close tag: "$closeTag"');

            // If original content has no HTML tags, work with plain text
            if (content == plainText) {
              print('Working with plain text (no HTML)');
              String before = plainText.substring(0, start);
              String after = plainText.substring(end);
              content = before + openTag + selectedText + closeTag + after;
            } else {
              // If content has HTML, we need to be more careful
              print(
                  'Working with HTML content - adding formatting to existing content');
              // For now, let's append the formatting to the existing content
              // This is a simplified approach - in a real app you'd want more sophisticated HTML manipulation
              String before = plainText.substring(0, start);
              String after = plainText.substring(end);
              content = before + openTag + selectedText + closeTag + after;
            }

            print('Final formatted content: "$content"');
          } catch (substringError) {
            print('Substring error during formatting: $substringError');
            _error = 'Ошибка при форматировании: ${substringError.toString()}';
            refreshUI();
            return;
          }
        } else {
          print(
              'Invalid bounds for formatting: start=$start, end=$end, length=${plainText.length}');
          _error = 'Неверные границы выделения';
          refreshUI();
          return;
        }
      }

      print('Saving formatted content to database...');
      // Save to database using originalId
      await _dataRepository.saveParagraphEditByOriginalId(
          _selectedParagraph!.originalId, content, _selectedParagraph!);

      // Update local data
      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        print('Updating local chapter data...');
        final paragraphs = List<Paragraph>.from(chapterData['paragraphs']);
        final index =
            paragraphs.indexWhere((p) => p.id == _selectedParagraph!.id);
        if (index != -1) {
          print('Found paragraph at index $index, updating...');
          paragraphs[index] = _selectedParagraph!.copyWith(content: content);
          _chaptersData[_currentChapterOrderNum] = {
            ...chapterData,
            'paragraphs': paragraphs,
          };
          _selectedParagraph = paragraphs[index];
          print('Paragraph updated successfully');
        } else {
          print('ERROR: Could not find paragraph in chapter data');
        }
      }

      _error = null;
      print('=== FORMATTING APPLIED SUCCESSFULLY ===');
      refreshUI();
    } catch (e) {
      print('Apply formatting error: $e');
      _error = 'Ошибка форматирования: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> markText() async {
    print('=== MARK TEXT BUTTON PRESSED ===');
    print('Selected paragraph: ${_selectedParagraph?.id}');
    print('Selection: start=$_selectionStart, end=$_selectionEnd');
    print('Selected text: "$_lastSelectedText"');
    await applyFormatting(Tag.m);
  }

  Future<void> underlineText() async {
    print('=== UNDERLINE TEXT BUTTON PRESSED ===');
    print('Selected paragraph: ${_selectedParagraph?.id}');
    print('Selection: start=$_selectionStart, end=$_selectionEnd');
    print('Selected text: "$_lastSelectedText"');
    await applyFormatting(Tag.u);
  }

  Future<void> clearFormatting() async {
    print('=== CLEAR FORMATTING BUTTON PRESSED ===');
    print('Selected paragraph: ${_selectedParagraph?.id}');
    await applyFormatting(Tag.c);
  }

  // ========== COLOR MANAGEMENT (like ColorsCubit) ==========

  void setActiveColorIndex(int index) {
    if (index >= 0 && index < _colorsList.length) {
      _activeColorIndex = index;
      refreshUI();
    }
  }

  void setActiveColor(int color) {
    _colorsList[_activeColorIndex] = color;
    refreshUI();
  }

  void addColor() {
    _colorsList.add(0xFF525965); // Default gray color
    _activeColorIndex = _colorsList.length - 1;
    refreshUI();
  }

  void deleteColor(int index) {
    if (_colorsList.length > 1 && index >= 0 && index < _colorsList.length) {
      _colorsList.removeAt(index);
      if (_activeColorIndex >= _colorsList.length) {
        _activeColorIndex = _colorsList.length - 1;
      }
      refreshUI();
    }
  }

  Future<void> saveColors() async {
    try {
      // Save colors to repository/preferences
      // In original this was: await _regulationRepository.setColorPickerColors(_colorsList);
      // For now, we'll implement a simple version
      print('Saving colors: $_colorsList');

      // You can implement actual persistence here later
      // For example: await _dataRepository.saveColorsList(_colorsList);
    } catch (e) {
      _error = 'Ошибка сохранения цветов: ${e.toString()}';
      refreshUI();
    }
  }

  // ========== UTILITY METHODS ==========

  bool isTextSelected() {
    return _selectedParagraph != null && _selectionStart < _selectionEnd;
  }

  bool hasFormatting(Paragraph paragraph) {
    return TextUtils.hasFormatting(paragraph.content);
  }

  List<Paragraph> searchInCurrentChapter(String query) {
    if (query.isEmpty) return [];

    final currentChapterData = getChapterData(_currentChapterOrderNum);
    if (currentChapterData == null) return [];

    final paragraphs = currentChapterData['paragraphs'] as List<Paragraph>;
    return paragraphs
        .where(
          (paragraph) =>
              paragraph.content.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // ========== TTS METHODS ==========

  Future<void> playTTS(Paragraph paragraph) async {
    try {
      final textToSpeak = paragraph.textToSpeech ??
          TextUtils.parseHtmlString(paragraph.content);
      print('TTS: Playing - $textToSpeak');
      _isTTSPlaying = true;
      refreshUI();

      await Future.delayed(const Duration(seconds: 3));
      _isTTSPlaying = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> playChapterTTS() async {
    try {
      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final paragraphs = chapterData['paragraphs'] as List<Paragraph>;
        final textToSpeak = paragraphs
            .map((p) => p.textToSpeech ?? TextUtils.parseHtmlString(p.content))
            .join(' ');
        print('TTS: Playing chapter - $textToSpeak');
        _isTTSPlaying = true;
        refreshUI();

        await Future.delayed(const Duration(seconds: 10));
        _isTTSPlaying = false;
        refreshUI();
      }
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void stopTTS() async {
    try {
      print('TTS: Stopped');
      _isTTSPlaying = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  @override
  void initListeners() {
    print('=== INIT LISTENERS ===');
    // Initialize listeners here
  }

  @override
  void refreshUI() {
    print('=== REFRESH UI CALLED ===');
    print('Current state:');
    print('  isBottomBarExpanded: $_isBottomBarExpanded');
    print('  selectedParagraph: ${_selectedParagraph?.id}');
    print('  lastSelectedText: "$_lastSelectedText"');
    print('  selectionStart: $_selectionStart, selectionEnd: $_selectionEnd');
    super.refreshUI();
  }

  @override
  void onDisposed() {
    print('=== CONTROLLER DISPOSED ===');
    pageController.dispose();
    pageTextController.dispose();
    super.onDisposed();
  }
}
