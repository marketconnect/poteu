import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/formatting.dart';
import '../../../domain/entities/tts_state.dart';
import '../../../domain/usecases/tts_usecase.dart';
import '../../../data/repositories/static_regulation_repository.dart';
import '../../../data/repositories/data_regulation_repository.dart';
import '../../../data/helpers/database_helper.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../utils/text_utils.dart';
import 'search_presenter.dart';
import '../../../domain/entities/search_result.dart';
import 'dart:async';

class ChapterController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final int? _scrollToParagraphId;
  final StaticRegulationRepository _repository = StaticRegulationRepository();
  final DataRegulationRepository _dataRepository = DataRegulationRepository(
    DatabaseHelper(),
  );
  final TTSUseCase _ttsUseCase;
  late SearchPresenter _searchPresenter;

  // PageView управление как в оригинале
  late PageController pageController;
  late TextEditingController pageTextController;

  // ScrollController for each chapter
  Map<int, ScrollController> _chapterScrollControllers = {};

  // ItemScrollController for precise scrolling (like original implementation)
  Map<int, ItemScrollController> _itemScrollControllers = {};

  // GlobalKeys for precise scrolling to paragraphs
  Map<int, Map<int, GlobalKey>> _paragraphKeys =
      {}; // chapterOrderNum -> paragraphIndex -> GlobalKey

  Map<int, Map<String, dynamic>> _chaptersData = {};
  int _currentChapterOrderNum = 1;
  int _totalChapters = 0;
  bool _isLoading = true;
  String? _error;
  String? _loadingError; // <--- NEW: for loading errors only
  bool _isBottomBarExpanded = false;
  bool _isBottomBarWhiteMode = false;
  Paragraph? _selectedParagraph;
  int _selectionStart = 0;
  int _selectionEnd = 0;
  String _lastSelectedText = '';
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
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  String _searchQuery = '';
  TtsState _ttsState = TtsState.stopped;
  StreamSubscription<TtsState>? _ttsStateSubscription;
  bool _stopRequested = false; // Флаг для остановки воспроизведения
  bool _isPlayingChapter = false; // Флаг для отслеживания воспроизведения главы

  // Getters
  Map<int, Map<String, dynamic>> get chaptersData => _chaptersData;
  int get currentChapterOrderNum => _currentChapterOrderNum;
  int get totalChapters => _totalChapters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get loadingError => _loadingError; // <--- NEW getter
  bool get isTTSPlaying => _ttsState == TtsState.playing;
  bool get isTTSPaused => _ttsState == TtsState.paused;
  bool get isTTSActive =>
      _ttsState == TtsState.playing || _ttsState == TtsState.paused;

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

  // Search getters
  bool get isSearching => _isSearching;
  List<SearchResult> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;

  // Getter for TTS state
  TtsState get ttsState => _ttsState;

  // ScrollController methods
  ScrollController getScrollControllerForChapter(int chapterOrderNum) {
    if (!_chapterScrollControllers.containsKey(chapterOrderNum)) {
      // Ограничиваем количество контроллеров для экономии памяти
      if (_chapterScrollControllers.length > 5) {
        // Удаляем самый старый контроллер
        final oldestKey = _chapterScrollControllers.keys.first;
        _chapterScrollControllers[oldestKey]?.dispose();
        _chapterScrollControllers.remove(oldestKey);
      }
      _chapterScrollControllers[chapterOrderNum] = ScrollController();
    }
    return _chapterScrollControllers[chapterOrderNum]!;
  }

  ScrollController get currentChapterScrollController {
    return getScrollControllerForChapter(_currentChapterOrderNum);
  }

  // ItemScrollController methods for precise scrolling (like original)
  ItemScrollController getItemScrollControllerForChapter(int chapterOrderNum) {
    if (!_itemScrollControllers.containsKey(chapterOrderNum)) {
      // Ограничиваем количество контроллеров для экономии памяти
      if (_itemScrollControllers.length > 5) {
        // Удаляем самый старый контроллер
        final oldestKey = _itemScrollControllers.keys.first;
        _itemScrollControllers.remove(oldestKey);
      }
      _itemScrollControllers[chapterOrderNum] = ItemScrollController();
    }
    return _itemScrollControllers[chapterOrderNum]!;
  }

  ItemScrollController get currentChapterItemScrollController {
    return getItemScrollControllerForChapter(_currentChapterOrderNum);
  }

  // GlobalKey methods for precise scrolling
  GlobalKey getParagraphKey(int chapterOrderNum, int paragraphIndex) {
    if (!_paragraphKeys.containsKey(chapterOrderNum)) {
      _paragraphKeys[chapterOrderNum] = {};
    }
    if (!_paragraphKeys[chapterOrderNum]!.containsKey(paragraphIndex)) {
      _paragraphKeys[chapterOrderNum]![paragraphIndex] = GlobalKey();
    }
    return _paragraphKeys[chapterOrderNum]![paragraphIndex]!;
  }

  void clearParagraphKeys(int chapterOrderNum) {
    _paragraphKeys[chapterOrderNum]?.clear();
  }

  ChapterController({
    required int regulationId,
    required int initialChapterOrderNum,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required RegulationRepository regulationRepository,
    int? scrollToParagraphId,
  })  : _regulationId = regulationId,
        _initialChapterOrderNum = initialChapterOrderNum,
        _scrollToParagraphId = scrollToParagraphId,
        _currentChapterOrderNum = initialChapterOrderNum,
        _ttsUseCase = TTSUseCase(ttsRepository) {
    pageController = PageController(initialPage: initialChapterOrderNum - 1);
    pageTextController = TextEditingController(
      text: initialChapterOrderNum.toString(),
    );

    loadAllChapters();

    // Subscribe to TTS state changes
    _searchPresenter = SearchPresenter(_repository);

    _searchPresenter.onSearchComplete = (List<SearchResult> results) {
      _searchResults = results;
      _isSearching = false;
      refreshUI();
    };

    _searchPresenter.onSearchError = (e) {
      _loadingError = e.toString(); // <--- set loading error for search
      _isSearching = false;
      refreshUI();
    };

    // Initialize TTS state subscription
    _ttsStateSubscription = _ttsUseCase.stateStream.listen(
      (TtsState state) {
        _ttsState = state;
        print('🎵 TTS state changed to: $state');

        // Сбрасываем флаг остановки только когда воспроизведение главы завершено
        if ((state == TtsState.stopped || state == TtsState.error) &&
            !_isPlayingChapter) {
          _stopRequested = false;
          print(
              '🎵 TTS state changed to $state - resetting stop flag (chapter playback finished)');
        }

        refreshUI();
      },
      onError: (error) {
        _loadingError =
            'TTS Error:  {error.toString()}'; // <--- set loading error for TTS
        _ttsState = TtsState.error;
        _stopRequested = false; // Сбрасываем флаг при ошибке
        _isPlayingChapter = false; // Сбрасываем флаг воспроизведения главы
        refreshUI();
      },
    );
  }

  @override
  void initListeners() {
    // Initialize search presenter with the same repository used for loading chapters
    _searchPresenter = SearchPresenter(_repository);

    _searchPresenter.onSearchComplete = (List<SearchResult> results) {
      _searchResults = results;
      _isSearching = false;
      refreshUI();
    };

    _searchPresenter.onSearchError = (e) {
      _loadingError = e.toString(); // <--- set loading error for search
      _isSearching = false;
      refreshUI();
    };

    // Initialize TTS state subscription
    _ttsStateSubscription = _ttsUseCase.stateStream.listen(
      (TtsState state) {
        _ttsState = state;
        print('🎵 TTS state changed to: $state');

        // Сбрасываем флаг остановки только когда воспроизведение главы завершено
        if ((state == TtsState.stopped || state == TtsState.error) &&
            !_isPlayingChapter) {
          _stopRequested = false;
          print(
              '🎵 TTS state changed to $state - resetting stop flag (chapter playback finished)');
        }

        refreshUI();
      },
      onError: (error) {
        _loadingError =
            'TTS Error:  {error.toString()}'; // <--- set loading error for TTS
        _ttsState = TtsState.error;
        _stopRequested = false; // Сбрасываем флаг при ошибке
        _isPlayingChapter = false; // Сбрасываем флаг воспроизведения главы
        refreshUI();
      },
    );
  }

  Future<void> loadAllChapters() async {
    final stopwatch = Stopwatch()..start();
    print('🔄 Начало загрузки глав...');

    _isLoading = true;
    _loadingError = null; // <--- clear loading error
    refreshUI();

    try {
      final chapters = await _repository.getChapters(_regulationId);
      _totalChapters = chapters.length;
      print('📚 Найдено глав: $_totalChapters');

      // Загружаем только текущую главу и соседние для быстрой загрузки
      await _loadChapterWithNeighbors(_initialChapterOrderNum);

      _isLoading = false;
      _loadingError = null; // <--- clear loading error
      refreshUI();

      stopwatch.stop();
      print('✅ Загрузка завершена за ${stopwatch.elapsedMilliseconds}ms');

      // Delay navigation until after the PageView is built
      if (_scrollToParagraphId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToParagraph(_scrollToParagraphId!);
        });
      }
    } catch (e) {
      stopwatch.stop();
      print('❌ Ошибка загрузки за ${stopwatch.elapsedMilliseconds}ms: $e');
      _isLoading = false;
      _loadingError =
          'Ошибка загрузки: ${e.toString()}'; // <--- set loading error
      refreshUI();
    }
  }

  // Загружает главу и соседние главы
  Future<void> _loadChapterWithNeighbors(int chapterOrderNum) async {
    final stopwatch = Stopwatch()..start();
    print('🔄 Загрузка главы $chapterOrderNum и соседних...');

    final chapters = await _repository.getChapters(_regulationId);

    // Загружаем текущую главу
    await _loadChapterData(chapters[chapterOrderNum - 1]);

    // Загружаем предыдущую главу если есть
    if (chapterOrderNum > 1) {
      await _loadChapterData(chapters[chapterOrderNum - 2]);
    }

    // Загружаем следующую главу если есть
    if (chapterOrderNum < chapters.length) {
      await _loadChapterData(chapters[chapterOrderNum]);
    }

    stopwatch.stop();
    print(
        '✅ Загрузка соседних глав завершена за ${stopwatch.elapsedMilliseconds}ms');
  }

  // Загружает данные конкретной главы
  Future<void> _loadChapterData(Chapter chapter) async {
    if (_chaptersData.containsKey(chapter.level)) {
      return; // Уже загружена
    }

    final stopwatch = Stopwatch()..start();
    print('📖 Загрузка главы ${chapter.level}: ${chapter.title}');

    // Применяем форматирование только для текущей главы
    List<Paragraph> updatedParagraphs;
    if (chapter.level == _currentChapterOrderNum) {
      updatedParagraphs =
          await _dataRepository.applyParagraphEdits(chapter.paragraphs);
      print(
          '🎨 Применено форматирование для ${updatedParagraphs.length} параграфов');
    } else {
      // Для соседних глав пока используем оригинальные параграфы
      updatedParagraphs = chapter.paragraphs;
    }

    _chaptersData[chapter.level] = {
      'id': chapter.id,
      'title': chapter.title,
      'content': chapter.content,
      'paragraphs': updatedParagraphs,
    };

    stopwatch.stop();
    print(
        '✅ Глава ${chapter.level} загружена за ${stopwatch.elapsedMilliseconds}ms');
  }

  // Загружает главу по требованию при переключении
  Future<void> _ensureChapterLoaded(int chapterOrderNum) async {
    if (_chaptersData.containsKey(chapterOrderNum)) {
      return; // Уже загружена
    }

    final chapters = await _repository.getChapters(_regulationId);
    if (chapterOrderNum > 0 && chapterOrderNum <= chapters.length) {
      await _loadChapterData(chapters[chapterOrderNum - 1]);
    }
  }

  Map<String, dynamic>? getChapterData(int chapterOrderNum) {
    return _chaptersData[chapterOrderNum];
  }

  void onPageChanged(int newChapterOrderNum) async {
    _currentChapterOrderNum = newChapterOrderNum;
    pageTextController.text = newChapterOrderNum.toString();

    // Лениво загружаем главу если она еще не загружена
    await _ensureChapterLoaded(newChapterOrderNum);

    // Загружаем соседние главы в фоне
    _loadNeighborChaptersInBackground(newChapterOrderNum);

    refreshUI();
  }

  // Загружает соседние главы в фоне
  void _loadNeighborChaptersInBackground(int chapterOrderNum) {
    Future.microtask(() async {
      final chapters = await _repository.getChapters(_regulationId);

      // Загружаем предыдущую главу если есть
      if (chapterOrderNum > 1) {
        await _loadChapterData(chapters[chapterOrderNum - 2]);
      }

      // Загружаем следующую главу если есть
      if (chapterOrderNum < chapters.length) {
        await _loadChapterData(chapters[chapterOrderNum]);
      }
    });
  }

  void goToChapter(int chapterOrderNum) {
    if (chapterOrderNum >= 1 && chapterOrderNum <= _totalChapters) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          chapterOrderNum - 1,
          duration: const Duration(seconds: 1),
          curve: Curves.ease,
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pageController.hasClients) {
            pageController.animateToPage(
              chapterOrderNum - 1,
              duration: const Duration(seconds: 1),
              curve: Curves.ease,
            );
          } else {}
        });
      }
    } else {}
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

  void goToParagraph(int paragraphId) {
    // First, try to find the paragraph by ID to get its order number
    int? targetChapterOrderNum;
    int?
        paragraphOrderNum; // This will be the order number in the chapter (1-based)

    for (final MapEntry<int, Map<String, dynamic>> entry
        in _chaptersData.entries) {
      final chapterOrderNum = entry.key;
      final chapterData = entry.value;

      final paragraphs = chapterData['paragraphs'] as List<Paragraph>;

      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i];

        // Try matching by different ID types
        bool found = false;

        // Check database IDs
        if (paragraph.originalId == paragraphId ||
            paragraph.id == paragraphId ||
            paragraph.num == paragraphId) {
          found = true;
          paragraphOrderNum = i + 1; // 1-based order number in chapter
        }

        // Also check HTML anchor IDs in content
        if (!found && paragraph.content.isNotEmpty) {
          // Look for anchor tags with matching ID
          final anchorRegex = RegExp('<a\\s+id=["\']([0-9]+)["\']');
          final matches = anchorRegex.allMatches(paragraph.content);

          for (final match in matches) {
            final anchorId = int.tryParse(match.group(1) ?? '');
            if (anchorId == paragraphId) {
              found = true;
              paragraphOrderNum = i + 1; // 1-based order number in chapter
              break;
            }
          }

          // Also try matching paragraph numbers in content (like "1.1", "2.3", etc.)
          if (!found) {
            final numberRegex = RegExp(r'(\d+)\.(\d+)');
            final numberMatches = numberRegex.allMatches(paragraph.content);
            for (final match in numberMatches) {
              final fullNumber = '${match.group(1)}${match.group(2)}';
              if (int.tryParse(fullNumber) == paragraphId) {
                found = true;
                paragraphOrderNum = i + 1; // 1-based order number in chapter
                break;
              }
            }
          }

          // Try matching formatted paragraph numbers like "6.14" directly
          if (!found) {
            // Look for patterns like "6.14" in the content after anchor tags
            final simpleNumberRegex = RegExp(r'(\d+)\.(\d+)');
            final numberMatches =
                simpleNumberRegex.allMatches(paragraph.content);
            for (final match in numberMatches) {
              final chapterNum = int.tryParse(match.group(1) ?? '');
              final paragraphNum = int.tryParse(match.group(2) ?? '');

              // Create combined number like 614 from "6.14"
              if (chapterNum != null && paragraphNum != null) {
                final combinedNumber = int.tryParse('$chapterNum$paragraphNum');
                if (combinedNumber == paragraphId) {
                  found = true;
                  paragraphOrderNum = i + 1; // 1-based order number in chapter
                  break;
                }
              }
            }
          }
        }

        if (found) {
          targetChapterOrderNum = chapterOrderNum;
          break;
        }
      }

      if (targetChapterOrderNum != null) break;
    }

    if (targetChapterOrderNum == null || paragraphOrderNum == null) {
      final currentChapterData = _chaptersData[_currentChapterOrderNum];
      if (currentChapterData != null) {
        final paragraphs = currentChapterData['paragraphs'] as List<Paragraph>;
        for (int i = 0; i < paragraphs.length && i < 10; i++) {
          // Show first 10
          final p = paragraphs[i];

          // Also show anchor IDs
          final anchorRegex = RegExp('<a\\s+id=["\']([0-9]+)["\']');
          final matches = anchorRegex.allMatches(p.content);
          final anchorIds = matches.map((m) => m.group(1)).toList();
          if (anchorIds.isNotEmpty) {}
        }
        if (paragraphs.length > 10) {}
      }
      return;
    }

    // Save final values after null check
    final finalTargetChapter = targetChapterOrderNum;
    final finalParagraphOrderNum = paragraphOrderNum;

    // Check if we're already on the target chapter
    if (_currentChapterOrderNum == finalTargetChapter) {
      _scrollToParagraphInCurrentChapter(
          finalTargetChapter, finalParagraphOrderNum);
    } else {
      // Navigate to the chapter first
      goToChapter(finalTargetChapter);

      // Then scroll to the paragraph after the page transition completes
      Future.delayed(const Duration(milliseconds: 1200), () {
        // Double-check we're on the right chapter before scrolling
        if (_currentChapterOrderNum == finalTargetChapter) {
          _scrollToParagraphInCurrentChapter(
              finalTargetChapter, finalParagraphOrderNum);
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_currentChapterOrderNum == finalTargetChapter) {
              _scrollToParagraphInCurrentChapter(
                  finalTargetChapter, finalParagraphOrderNum);
            } else {}
          });
        }
      });
    }
  }

  void _scrollToParagraphInCurrentChapter(
      int chapterOrderNum, int paragraphOrderNum) {
    // First try using ItemScrollController for precise navigation (like original)
    final itemScrollController =
        getItemScrollControllerForChapter(chapterOrderNum);

    if (itemScrollController.isAttached) {
      // Get paragraphs to validate order number
      final paragraphs =
          _chaptersData[chapterOrderNum]?['paragraphs'] as List<Paragraph>?;
      if (paragraphs == null) {
        return;
      }

      // Convert 1-based order number to 0-based index
      final paragraphIndex = paragraphOrderNum - 1;

      if (paragraphIndex < 0 || paragraphIndex >= paragraphs.length) {
        return;
      }

      // In the list, index 0 is title, so paragraph order N is at index N
      // But in ItemScrollController, we jump directly to the item index
      // Since our ListView has title at index 0, paragraph order 1 is at index 1
      final targetItemIndex =
          paragraphOrderNum; // Direct mapping: order 1 -> index 1, order 2 -> index 2, etc.

      try {
        itemScrollController.jumpTo(index: targetItemIndex);
        return;
      } catch (e) {}
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphOrderNum);
      });
      return;
    }

    // Fallback to ScrollController method if ItemScrollController fails
    final scrollController = getScrollControllerForChapter(chapterOrderNum);

    if (!scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphOrderNum);
      });
      return;
    }

    try {
      // Get paragraphs to understand total count
      final paragraphs =
          _chaptersData[chapterOrderNum]?['paragraphs'] as List<Paragraph>?;
      if (paragraphs == null) {
        return;
      }

      // Convert 1-based order number to 0-based index
      final paragraphIndex = paragraphOrderNum - 1;

      if (paragraphIndex < 0 || paragraphIndex >= paragraphs.length) {
        return;
      }

      // Use a more accurate calculation based on paragraph types and content
      double targetPosition =
          _calculatePositionForParagraphIndex(paragraphs, paragraphIndex);

      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final finalPosition = targetPosition.clamp(0.0, maxScrollExtent);

      // Scroll to the calculated position
      scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      _scrollToParagraphFallback(chapterOrderNum,
          paragraphOrderNum - 1); // Convert to 0-based for fallback
    }
  }

  /// Calculate position for a paragraph index using more accurate height estimation
  double _calculatePositionForParagraphIndex(
      List<Paragraph> paragraphs, int targetParagraphIndex) {
    // Title section height (fixed)
    const double titleHeight = 70.0; // title height + padding
    double totalHeight = titleHeight;

    // Calculate height for all paragraphs before the target
    for (int i = 0; i < targetParagraphIndex && i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final paragraphHeight = _calculateParagraphHeight(paragraph);
      totalHeight += paragraphHeight;
    }

    return totalHeight;
  }

  /// Calculate estimated height for a single paragraph
  double _calculateParagraphHeight(Paragraph paragraph) {
    // Handle special paragraph classes
    switch (paragraph.paragraphClass?.toLowerCase()) {
      case 'indent':
        return 15.0; // Just a spacer
      default:
        break;
    }

    // Base padding for different alignment types
    double padding;
    switch (paragraph.paragraphClass?.toLowerCase()) {
      case 'align_right':
      case 'align_right no-indent':
      case 'align_center':
        padding = 4.0; // vertical padding
        break;
      default:
        padding = 32.0; // default vertical padding (16 * 2)
    }

    // Special content types
    if (paragraph.isTable) {
      return 120.0 + padding; // Tables are typically larger
    }

    if (paragraph.isNft) {
      return 80.0 + padding; // NFT content with special styling
    }

    // Regular text content
    final plainText = TextUtils.parseHtmlString(paragraph.content);
    if (plainText.isEmpty) {
      return 20.0 + padding; // Minimal height for empty content
    }

    // Estimate based on content length
    const double baseLineHeight = 22.0; // Estimated line height at 16px font
    const int avgCharsPerLine = 60; // Estimated characters per line

    final estimatedLines = (plainText.length / avgCharsPerLine).ceil();
    final contentHeight = estimatedLines * baseLineHeight;

    // Add some buffer for word wrapping variations
    final adjustedHeight = contentHeight * 1.2;

    return adjustedHeight + padding;
  }

  // Fallback method using the old calculation approach
  void _scrollToParagraphFallback(int chapterOrderNum, int paragraphIndex) {
    final scrollController = getScrollControllerForChapter(chapterOrderNum);

    if (scrollController.hasClients) {
      // Simplified fallback calculation - much more conservative
      const titleHeight = 100.0; // Title section height
      const averageParagraphHeight = 80.0; // Average paragraph height

      double targetPosition =
          titleHeight + (paragraphIndex * averageParagraphHeight);

      // Add some extra offset to ensure target paragraph is visible
      targetPosition += 20.0;

      // Get max scroll extent to avoid over-scrolling
      final maxScroll = scrollController.position.maxScrollExtent;
      final finalPosition =
          targetPosition > maxScroll ? maxScroll : targetPosition;

      scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Try again after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphIndex);
      });
    }
  }

  /// Debug function to print information about paragraphs in current chapter
  void debugPrintChapterParagraphs() {
    final chapterData = getChapterData(currentChapterOrderNum);
    if (chapterData == null) {
      return;
    }

    final paragraphs = chapterData['paragraphs'] as List<Paragraph>;

    for (int i = 0; i < paragraphs.length && i < 20; i++) {
      // Show first 20
      final p = paragraphs[i];

      final plainText = TextUtils.parseHtmlString(p.content);
      final preview = plainText.length > 50
          ? '${plainText.substring(0, 50)}...'
          : plainText;

      // Look for anchor IDs
      final anchorRegex = RegExp('<a\\s+id=["\']([0-9]+)["\']');
      final matches = anchorRegex.allMatches(p.content);
      final anchorIds = matches.map((m) => m.group(1)).toList();
      if (anchorIds.isNotEmpty) {}

      // Look for number patterns
      final numberRegex = RegExp(r'(\d+)\.(\d+)');
      final numberMatches = numberRegex.allMatches(p.content);
      if (numberMatches.isNotEmpty) {
        final numbers =
            numberMatches.map((m) => '${m.group(1)}.${m.group(2)}').toList();
      }
    }

    if (paragraphs.length > 20) {}
  }

  // ========== BOTTOM BAR MANAGEMENT (like BottomBarCubit) ==========

  void toggleBottomBar() {
    _isBottomBarExpanded = !_isBottomBarExpanded;
    refreshUI();
  }

  void expandBottomBar() {
    _isBottomBarExpanded = true;
    refreshUI();
  }

  void collapseBottomBar() {
    _isBottomBarExpanded = false;
    _isBottomBarWhiteMode = false;
    _selectedParagraph = null;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
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
            _lastSelectedText = '';
            _error = 'Ошибка выделения текста';
          }
        } else {
          _lastSelectedText = '';
        }
      } else {
        _lastSelectedText = '';
      }

      _error = null; // Clear any previous errors
      refreshUI();
    } catch (e) {
      _lastSelectedText = '';
      _error = 'Ошибка при обработке выделения';
      refreshUI();
    }
  }

  void selectParagraphForFormatting(Paragraph paragraph) {
    _selectedParagraph = paragraph;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
    _isBottomBarExpanded = true;
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
      if (_selectedParagraph == null) {
        _error = 'Параграф не выбран';
        refreshUI();
        return;
      }

      if (_selectionStart == _selectionEnd && tag != Tag.c) {
        _error = tag == Tag.m
            ? 'Вы не выделили участок параграфа, который собираетесь выделить.'
            : 'Вы не выделили участок параграфа, который собираетесь подчеркнуть.';
        refreshUI();
        return;
      }

      String content = _selectedParagraph!.content;

      if (tag == Tag.c) {
        // Clear all formatting - this is safe
        content = TextUtils.removeAllFormatting(content);
      } else {
        // For text formatting, we need to be more careful about HTML vs plain text
        String plainText = TextUtils.parseHtmlString(content);

        if (plainText.isEmpty) {
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

        if (start >= 0 &&
            end > start &&
            start < plainText.length &&
            end <= plainText.length) {
          try {
            // Get the selected text from plain text
            String selectedText = plainText.substring(start, end);

            // Create formatting tags
            String openTag =
                TextUtils.createOpenTag(tag, _colorsList[_activeColorIndex]);
            String closeTag = TextUtils.createCloseTag(tag);

            // If original content has no HTML tags, work with plain text
            if (content == plainText) {
              String before = plainText.substring(0, start);
              String after = plainText.substring(end);
              content = before + openTag + selectedText + closeTag + after;
            } else {
              // If content has HTML, we need to be more careful
              // For now, let's append the formatting to the existing content
              // This is a simplified approach - in a real app you'd want more sophisticated HTML manipulation
              String before = plainText.substring(0, start);
              String after = plainText.substring(end);
              content = before + openTag + selectedText + closeTag + after;
            }
          } catch (substringError) {
            _error = 'Ошибка при форматировании: ${substringError.toString()}';
            refreshUI();
            return;
          }
        } else {
          _error = 'Неверные границы выделения';
          refreshUI();
          return;
        }
      }

      // Save to database using originalId
      try {
        await _dataRepository.saveParagraphEditByOriginalId(
            _selectedParagraph!.originalId, content, _selectedParagraph!);
      } catch (saveError) {
        _error = 'Ошибка сохранения: ${saveError.toString()}';
        refreshUI();
        return;
      }

      // Update local data
      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final paragraphs = List<Paragraph>.from(chapterData['paragraphs']);
        final index =
            paragraphs.indexWhere((p) => p.id == _selectedParagraph!.id);
        if (index != -1) {
          paragraphs[index] = _selectedParagraph!.copyWith(content: content);
          _chaptersData[_currentChapterOrderNum] = {
            ...chapterData,
            'paragraphs': paragraphs,
          };
          _selectedParagraph = paragraphs[index];
        } else {}
      }

      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка форматирования: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> markText() async {
    await applyFormatting(Tag.m);
  }

  Future<void> underlineText() async {
    await applyFormatting(Tag.u);
  }

  Future<void> clearFormatting() async {
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

  // Maximum text length for TTS (in characters) - very conservative limit
  static const int _maxTtsTextLength =
      1500; // Reduced from 3000 to be much more conservative

  Future<void> playTTS(Paragraph paragraph) async {
    try {
      // Сбрасываем флаг остановки в начале воспроизведения
      _stopRequested = false;

      String textToSpeak = '';

      // First try to use the dedicated textToSpeech field if available
      if (paragraph.textToSpeech != null &&
          paragraph.textToSpeech!.isNotEmpty) {
        textToSpeak = paragraph.textToSpeech!;
      } else {
        // Fallback to parsing HTML content
        textToSpeak = TextUtils.parseHtmlString(paragraph.content);
      }

      // Additional processing for complex content
      if (textToSpeak.trim().isEmpty && paragraph.isTable) {
        // For tables, try to extract more meaningful text
        textToSpeak = _extractTableText(paragraph.content);
      }

      if (textToSpeak.trim().isNotEmpty) {
        _ttsUseCase.execute(_TTSUseCaseObserver(this),
            TTSUseCaseParams.speak(textToSpeak.trim()));
      }
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> playChapterTTS() async {
    try {
      // Сбрасываем флаг остановки в начале воспроизведения
      _stopRequested = false;
      _isPlayingChapter = true; // Устанавливаем флаг воспроизведения главы

      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final paragraphs = chapterData['paragraphs'] as List<Paragraph>;

        print(
            '🎵 Starting TTS for chapter $_currentChapterOrderNum with ${paragraphs.length} paragraphs');

        // Extract all text from paragraphs with better handling
        final allTexts = <String>[];

        for (int i = 0; i < paragraphs.length; i++) {
          final paragraph = paragraphs[i];
          String textToSpeak = '';

          print(
              '📝 Processing paragraph ${i + 1}/${paragraphs.length} (ID: ${paragraph.id})');

          // First try to use the dedicated textToSpeech field if available
          if (paragraph.textToSpeech != null &&
              paragraph.textToSpeech!.isNotEmpty) {
            textToSpeak = paragraph.textToSpeech!;
            print(
                '  ✅ Using textToSpeech field: "${textToSpeak.substring(0, textToSpeak.length > 50 ? 50 : textToSpeak.length)}..."');
          } else {
            // Fallback to parsing HTML content
            textToSpeak = TextUtils.parseHtmlString(paragraph.content);
            print(
                '  🔄 Using parsed HTML: "${textToSpeak.substring(0, textToSpeak.length > 50 ? 50 : textToSpeak.length)}..."');
          }

          // Additional processing for complex content
          if (textToSpeak.trim().isEmpty && paragraph.isTable) {
            // For tables, try to extract more meaningful text
            textToSpeak = _extractTableText(paragraph.content);
            print(
                '  📊 Using extracted table text: "${textToSpeak.substring(0, textToSpeak.length > 50 ? 50 : textToSpeak.length)}..."');
          }

          // Only add non-empty texts
          if (textToSpeak.trim().isNotEmpty) {
            allTexts.add(textToSpeak.trim());
            print(
                '  ✅ Added to TTS queue (${textToSpeak.trim().length} chars)');
          } else {
            print('  ⚠️ Skipped - no readable text found');
          }
        }

        print('🎵 Total texts to speak: ${allTexts.length}');

        // If no text, return early
        if (allTexts.isEmpty) {
          print('❌ No text to speak');
          return;
        }

        // If total text is short enough, speak it all at once
        final totalLength = allTexts.join('. ').length;
        if (totalLength <= _maxTtsTextLength) {
          final fullText = allTexts.join('. ');
          print('🎵 Speaking all text at once (${totalLength} chars)');
          _ttsUseCase.execute(
              _TTSUseCaseObserver(this), TTSUseCaseParams.speak(fullText));
          return;
        }

        // Otherwise, chunk the text into smaller pieces
        print('🎵 Text too long (${totalLength} chars), chunking into pieces');
        await _playChapterInChunks(allTexts);
      }
    } catch (e) {
      print('❌ Error in playChapterTTS: $e');
      _error = e.toString();
      refreshUI();
    }
  }

  /// Extracts readable text from table HTML content
  String _extractTableText(String htmlContent) {
    try {
      print('📊 Extracting table text from HTML (${htmlContent.length} chars)');

      // Remove complex table structure but preserve cell content
      String text = htmlContent;

      // Remove table tags but keep content
      text = text.replaceAll(RegExp(r'<table[^>]*>'), '');
      text = text.replaceAll('</table>', '');
      text = text.replaceAll(RegExp(r'<tbody[^>]*>'), '');
      text = text.replaceAll('</tbody>', '');
      text = text.replaceAll(RegExp(r'<colgroup[^>]*>'), '');
      text = text.replaceAll('</colgroup>', '');
      text = text.replaceAll(RegExp(r'<col[^>]*>'), '');

      // Replace row and cell tags with spaces
      text = text.replaceAll(RegExp(r'<tr[^>]*>'), ' ');
      text = text.replaceAll('</tr>', ' ');
      text = text.replaceAll(RegExp(r'<td[^>]*>'), ' ');
      text = text.replaceAll('</td>', ' ');
      text = text.replaceAll(RegExp(r'<th[^>]*>'), ' ');
      text = text.replaceAll('</th>', ' ');

      // Remove other HTML tags but preserve their content
      text = text.replaceAll(RegExp(r'<[^>]*>'), '');

      // Clean up whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      // If we still have no meaningful text, try a more aggressive approach
      if (text.isEmpty || text.length < 10) {
        print('📊 Table text too short, trying aggressive extraction');

        // Try to extract text from anchor tags and other elements
        final anchorRegex = RegExp(r'<a[^>]*>([^<]*)</a>');
        final anchorMatches = anchorRegex.allMatches(htmlContent);
        final anchorTexts = anchorMatches
            .map((m) => m.group(1)?.trim() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();

        if (anchorTexts.isNotEmpty) {
          text = anchorTexts.join(' ');
          print('📊 Extracted text from anchors: "$text"');
        }
      }

      print(
          '📊 Final extracted table text: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
      return text;
    } catch (e) {
      print('📊 Error extracting table text: $e');
      // Fallback to simple HTML parsing
      return TextUtils.parseHtmlString(htmlContent);
    }
  }

  /// Plays chapter text in chunks to avoid TTS text length limits
  Future<void> _playChapterInChunks(List<String> texts) async {
    try {
      print('🎵 _playChapterInChunks: Starting chapter playback');

      // Проверяем, не была ли запрошена остановка перед началом
      if (_stopRequested || !_isPlayingChapter) {
        print('🎵 _playChapterInChunks: Playback stopped before starting');
        return;
      }

      final chunks = _createTextChunks(texts);
      print('🎵 Created ${chunks.length} chunks for TTS playback');

      for (int i = 0; i < chunks.length; i++) {
        // Проверяем остановку в начале каждого цикла
        if (_stopRequested || !_isPlayingChapter) {
          print('🎵 _playChapterInChunks: Playback stopped at chunk ${i + 1}');
          return;
        }

        final chunk = chunks[i];
        print(
            '🎵 Playing chunk ${i + 1}/${chunks.length} (${chunk.length} chars)');

        // Останавливаем предыдущий TTS если он еще играет
        if (_ttsState == TtsState.playing) {
          print('🎵 Stopping previous TTS before starting new chunk');
          await stopTTS();
          await Future.delayed(const Duration(milliseconds: 500));

          // Проверяем остановку после остановки предыдущего TTS
          if (_stopRequested || !_isPlayingChapter) {
            print(
                '🎵 _playChapterInChunks: Playback stopped after stopping previous TTS');
            return;
          }
        }

        // Отправляем новый чанк в TTS
        print('🎵 Sending chunk ${i + 1} to TTS');
        _ttsUseCase.execute(
            _TTSUseCaseObserver(this), TTSUseCaseParams.speak(chunk));

        // Ждем завершения TTS
        print('🎵 Waiting for TTS completion...');
        await _waitForTTSCompletion();

        // Проверяем остановку после завершения TTS
        if (_stopRequested || !_isPlayingChapter) {
          print(
              '🎵 _playChapterInChunks: Playback stopped after TTS completion');
          return;
        }

        // Проверяем ошибку TTS
        if (_ttsState == TtsState.error) {
          print('❌ TTS chunk ${i + 1} failed with error');
          _error = 'Ошибка воспроизведения TTS';
          _isPlayingChapter = false;
          refreshUI();
          return;
        }

        print('🎵 TTS chunk ${i + 1} completed successfully');

        // Пауза между чанками (кроме последнего)
        if (i < chunks.length - 1) {
          print('🎵 Adding pause between chunks...');
          await Future.delayed(const Duration(milliseconds: 300));

          // Проверяем остановку после паузы
          if (_stopRequested || !_isPlayingChapter) {
            print('🎵 _playChapterInChunks: Playback stopped after pause');
            return;
          }
        }
      }

      print('🎵 All chunks completed successfully');
    } catch (e) {
      print('❌ Error in _playChapterInChunks: $e');
      _error = 'Ошибка воспроизведения главы: ${e.toString()}';
      _isPlayingChapter = false;
      refreshUI();
    }
  }

  /// Waits for TTS to complete by monitoring the state stream
  Future<void> _waitForTTSCompletion() async {
    try {
      print('🎵 _waitForTTSCompletion: Starting wait for TTS completion');

      // Проверяем остановку перед началом ожидания
      if (_stopRequested || !_isPlayingChapter) {
        print('🎵 _waitForTTSCompletion: Playback stopped before waiting');
        return;
      }

      // Ждем начала воспроизведения
      print('🎵 _waitForTTSCompletion: Waiting for TTS to start playing...');
      final startedPlaying = await _waitForTTSState([TtsState.playing]);
      if (!startedPlaying) {
        print('❌ _waitForTTSCompletion: TTS failed to start playing');
        return;
      }
      print('🎵 _waitForTTSCompletion: TTS started playing');

      // Проверяем остановку после начала воспроизведения
      if (_stopRequested || !_isPlayingChapter) {
        print('🎵 _waitForTTSCompletion: Playback stopped after TTS started');
        return;
      }

      // Ждем завершения TTS
      print('🎵 _waitForTTSCompletion: Waiting for TTS to complete...');
      final completed =
          await _waitForTTSState([TtsState.stopped, TtsState.error]);
      print('🎵 _waitForTTSCompletion: TTS completed, result: $completed');

      // Проверяем остановку после завершения
      if (_stopRequested || !_isPlayingChapter) {
        print(
            '🎵 _waitForTTSCompletion: Playback stopped after TTS completion');
        return;
      }

      // Проверяем ошибку
      if (_ttsState == TtsState.error) {
        print('❌ _waitForTTSCompletion: TTS ended with error');
      } else {
        print('🎵 _waitForTTSCompletion: TTS completed successfully');
      }
    } catch (e) {
      print('⚠️ _waitForTTSCompletion: Error or timeout: $e');
    }
  }

  /// Waits for TTS to reach any of the target states
  Future<bool> _waitForTTSState(List<TtsState> targetStates) async {
    print('🎵 _waitForTTSState: Waiting for states: $targetStates');
    final completer = Completer<bool>();
    StreamSubscription<TtsState>? subscription;

    subscription = _ttsUseCase.stateStream.listen((state) {
      print('🎵 _waitForTTSState: Received state: $state');

      // Проверяем остановку
      if (_stopRequested || !_isPlayingChapter) {
        print('🎵 _waitForTTSState: Playback stopped, completing with false');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return;
      }

      // Проверяем достижение целевого состояния
      if (targetStates.contains(state)) {
        print('🎵 _waitForTTSState: Target state reached: $state');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    final result = await completer.future;
    print('🎵 _waitForTTSState: Wait completed with result: $result');
    return result;
  }

  /// Creates text chunks that fit within TTS limits
  List<String> _createTextChunks(List<String> texts) {
    print('🎵 _createTextChunks: Creating chunks from ${texts.length} texts');
    final chunks = <String>[];
    String currentChunk = '';

    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      print(
          '🎵 _createTextChunks: Processing text ${i + 1}/${texts.length} (${text.length} chars)');
      print('🎵 _createTextChunks: Text content: "${text}"');

      final potentialChunk =
          currentChunk.isEmpty ? text : '$currentChunk. $text';

      print(
          '🎵 _createTextChunks: Potential chunk length: ${potentialChunk.length} (max: $_maxTtsTextLength)');
      print(
          '🎵 _createTextChunks: Potential chunk content: "${potentialChunk}"');

      if (potentialChunk.length <= _maxTtsTextLength) {
        currentChunk = potentialChunk;
        print('🎵 _createTextChunks: Added to current chunk');
      } else {
        // Current chunk is full, save it and start a new one
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
          print(
              '🎵 _createTextChunks: Saved chunk ${chunks.length} (${currentChunk.length} chars)');
          print('🎵 _createTextChunks: Saved chunk content: "${currentChunk}"');
        }

        // Check if the current text is too long to fit in a single chunk
        if (text.length > _maxTtsTextLength) {
          print(
              '🎵 _createTextChunks: Text ${i + 1} is too long (${text.length} chars), will be split');
          // Split the long text into smaller pieces
          final textChunks = _splitLongText(text);
          for (final textChunk in textChunks) {
            chunks.add(textChunk);
            print(
                '🎵 _createTextChunks: Saved split chunk ${chunks.length} (${textChunk.length} chars)');
            print('🎵 _createTextChunks: Split chunk content: "${textChunk}"');
          }
          currentChunk = '';
        } else {
          // Start a new chunk with the current text
          currentChunk = text;
          print('🎵 _createTextChunks: Started new chunk with text ${i + 1}');
        }
      }
    }

    // Add the last chunk if it's not empty
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
      print(
          '🎵 _createTextChunks: Saved final chunk ${chunks.length} (${currentChunk.length} chars)');
      print('🎵 _createTextChunks: Final chunk content: "${currentChunk}"');
    }

    print('🎵 _createTextChunks: Created ${chunks.length} total chunks');
    return chunks;
  }

  /// Splits a long text into smaller chunks that fit within TTS limits
  List<String> _splitLongText(String text) {
    final chunks = <String>[];
    int startIndex = 0;

    while (startIndex < text.length) {
      int endIndex = startIndex + _maxTtsTextLength;

      // If we're not at the end, try to find a good break point
      if (endIndex < text.length) {
        // Look for sentence endings (., !, ?) or paragraph breaks
        int lastGoodBreak = startIndex;
        for (int i = startIndex; i < endIndex; i++) {
          if (text[i] == '.' ||
              text[i] == '!' ||
              text[i] == '?' ||
              text[i] == '\n') {
            lastGoodBreak = i + 1;
          }
        }

        // If we found a good break point, use it
        if (lastGoodBreak > startIndex) {
          endIndex = lastGoodBreak;
        }
      } else {
        endIndex = text.length;
      }

      final chunk = text.substring(startIndex, endIndex).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      startIndex = endIndex;
    }

    return chunks;
  }

  Future<void> stopTTS() async {
    try {
      print(
          '🎵 STOP TTS CALLED - Setting stop flag and stopping chapter playback');
      _stopRequested = true; // Устанавливаем флаг остановки
      _isPlayingChapter = false; // Останавливаем воспроизведение главы
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.stop());
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> pauseTTS() async {
    try {
      print('🎵 PAUSE TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.pause());
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> resumeTTS() async {
    try {
      print('🎵 RESUME TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.resume());
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  @override
  void refreshUI() {
    super.refreshUI();
  }

  @override
  void onDisposed() {
    pageController.dispose();
    pageTextController.dispose();

    // Dispose all scroll controllers
    for (final controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    _chapterScrollControllers.clear();

    // Clear all item scroll controllers (they don't need explicit disposal)
    _itemScrollControllers.clear();

    // Clear all paragraph keys
    _paragraphKeys.clear();

    // Cancel TTS state subscription and reset stop flag
    _ttsStateSubscription?.cancel();
    _stopRequested = false;
    _isPlayingChapter = false;

    _searchPresenter.dispose();
    super.onDisposed();
  }

  void search(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      refreshUI();
      return;
    }

    _isSearching = true;
    refreshUI();
    _searchPresenter.search(_regulationId, query);
  }

  void goToSearchResult(SearchResult result) {
    // Scroll to the paragraph
    goToParagraph(result.paragraphId);

    // Clear search results
    _searchResults = [];
    _searchQuery = '';
    refreshUI();
  }

  Future<void> saveEditedParagraph(
      Paragraph paragraph, String editedContent) async {
    try {
      // Save to database
      await _dataRepository.saveEditedParagraph(
        paragraph.originalId,
        editedContent,
        paragraph,
      );

      // Update local data
      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final paragraphs = List<Paragraph>.from(chapterData['paragraphs']);
        final index = paragraphs.indexWhere((p) => p.id == paragraph.id);
        if (index != -1) {
          paragraphs[index] = paragraph.copyWith(content: editedContent);
          _chaptersData[_currentChapterOrderNum] = {
            ...chapterData,
            'paragraphs': paragraphs,
          };
        }
      }

      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка сохранения: ${e.toString()}';
      refreshUI();
    }
  }
}

class _TTSUseCaseObserver extends Observer<void> {
  final ChapterController _controller;

  _TTSUseCaseObserver(this._controller);

  @override
  void onComplete() {
    print('🎵 TTS Observer: onComplete called');
  }

  @override
  void onError(e) {
    print('❌ TTS Observer: onError called with: $e');
    _controller._error = e.toString();
    _controller.refreshUI();
  }

  @override
  void onNext(_) {
    print('🎵 TTS Observer: onNext called');
  }
}
