import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/data/repositories/data_subscription_repository.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';
import 'package:poteu/domain/usecases/download_regulation_data_usecase.dart';
import 'package:poteu/data/repositories/cloud_regulation_repository.dart';

import 'package:poteu/app/pages/library/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:poteu/app/services/user_id_service.dart';
import 'chapter_view.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../domain/entities/formatting.dart';
import '../../../domain/entities/tts_state.dart';
import '../../../domain/usecases/tts_usecase.dart';
import '../../../data/repositories/data_regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../utils/text_utils.dart';
import 'search_presenter.dart';
import '../../../domain/entities/search_result.dart';
import 'dart:async';
import 'dart:developer' as dev;

class ChapterController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final int? _scrollToParagraphId;
  final RegulationRepository _repository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final DataRegulationRepository _dataRepository =
      DataRegulationRepository(); // No longer needs DatabaseHelper
  final TTSUseCase _ttsUseCase;
  late final SubscriptionRepository _subscriptionRepository;
  late final CheckSubscriptionUseCase _checkSubscriptionUseCase;
  late final DownloadRegulationDataUseCase _downloadRegulationDataUseCase;
  late SearchPresenter _searchPresenter;

  // PageView управление как в оригинале
  late PageController pageController;
  late TextEditingController pageTextController;

  // ScrollController for each chapter
  final Map<int, ScrollController> _chapterScrollControllers = {};

  // ItemScrollController for precise scrolling (like original implementation)
  final Map<int, ItemScrollController> _itemScrollControllers = {};

  // GlobalKeys for precise scrolling to paragraphs
  final Map<int, Map<int, GlobalKey>> _paragraphKeys =
      {}; // chapterOrderNum -> paragraphIndex -> GlobalKey

  final Map<int, Map<String, dynamic>> _chaptersData = {};
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
  final List<int> _colorsList = [
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
  Paragraph? _currentTTSParagraph; // Текущий читаемый параграф для TTS

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

  // Getter for current TTS paragraph
  Paragraph? get currentTTSParagraph => _currentTTSParagraph;

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
        _repository = regulationRepository,
        _ttsUseCase = TTSUseCase(ttsRepository),
        _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository {
    _subscriptionRepository =
        DataSubscriptionRepository(http.Client(), UserIdService());
    _checkSubscriptionUseCase =
        CheckSubscriptionUseCase(_subscriptionRepository);
    _downloadRegulationDataUseCase =
        DownloadRegulationDataUseCase(DataCloudRegulationRepository());
    pageController = PageController(initialPage: initialChapterOrderNum - 1);
    pageTextController = TextEditingController(
      text: initialChapterOrderNum.toString(),
    );

    // Загружаем главы при создании контроллера
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
        dev.log('🎵 TTS state changed to: $state');

        // Обрабатываем переходы состояний
        switch (state) {
          case TtsState.stopped:
            // Очищаем параграф только если это была запрошенная остановка
            if (_stopRequested) {
              dev.log(
                  '🎵 TTS stopped as requested - clearing current paragraph');
              _currentTTSParagraph = null;
            } else {
              dev.log(
                  '🎵 TTS stopped naturally - keeping current paragraph highlighted for 3 seconds');
              // Автоматически очищаем выделение через 3 секунды после естественного завершения
              Future.delayed(const Duration(seconds: 3), () {
                if (_currentTTSParagraph != null &&
                    !_isPlayingChapter &&
                    _ttsState == TtsState.stopped) {
                  dev.log(
                      '🎵 Auto-clearing paragraph highlight after natural completion');
                  _currentTTSParagraph = null;
                  refreshUI();
                }
              });
            }

            // Сбрасываем флаг остановки когда воспроизведение главы завершено
            if (!_isPlayingChapter) {
              _stopRequested = false;
              dev.log(
                  '🎵 TTS state changed to $state - resetting stop flag (chapter playback finished)');
            }
            break;
          case TtsState.error:
            // При ошибке всегда очищаем
            dev.log('🎵 TTS error - clearing current paragraph');
            _currentTTSParagraph = null;
            break;
          case TtsState.paused:
            // Если запрошена остановка во время паузы, принудительно останавливаем
            if (_stopRequested) {
              dev.log('🎵 Stop requested while paused, forcing stop...');
              stopTTS();
            }
            break;
          default:
            break;
        }

        refreshUI();
      },
      onError: (error) {
        _handleError('TTS Error:  ${error.toString()}');
        _ttsState = TtsState.error;
        _stopRequested = false; // Сбрасываем флаг при ошибке
        _isPlayingChapter = false; // Сбрасываем флаг воспроизведения главы
        _currentTTSParagraph = null; // Очищаем при ошибке
        dev.log('🎵 TTS error in stream - clearing current paragraph');
      },
    );
  }
  void _handleError(dynamic e, {StackTrace? stackTrace}) {
    final errorMessage = e.toString();
    const silentErrorMessages = [
      'Вы не выделили участок параграфа, который собираетесь выделить.',
      'Вы не выделили участок параграфа, который собираетесь подчеркнуть.',
      'В параграфе нет заметок, которые можно было бы очистить.'
    ];
    if (silentErrorMessages.contains(errorMessage)) {
      _error = errorMessage;
    } else {
      Sentry.captureException(e, stackTrace: stackTrace);
      // For the user, always show a generic message for unexpected errors.
      _error = 'Что-то пошло не так';
    }

    refreshUI();
  }

  void clearError() {
    _error = null;
    refreshUI();
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

    // TTS state subscription уже инициализирована в конструкторе
    // Не дублируем её здесь
  }

  Future<void> loadAllChapters() async {
    final stopwatch = Stopwatch()..start();
    dev.log('🔄 Начало загрузки глав...');

    _isLoading = true;
    _loadingError = null; // <--- clear loading error
    refreshUI();

    try {
      // Use the new optimized method to get chapter list
      final chapterList = await _repository.getChapterList(_regulationId);
      _totalChapters = chapterList.length;
      dev.log('📚 Найдено глав: $_totalChapters');

      // Загружаем только текущую главу и соседние для быстрой загрузки
      await _loadChapterWithNeighbors(_initialChapterOrderNum);

      _isLoading = false;
      _loadingError = null; // <--- clear loading error
      refreshUI();

      stopwatch.stop();
      dev.log('✅ Загрузка завершена за ${stopwatch.elapsedMilliseconds}ms');

      // Delay navigation until after the PageView is built
      if (_scrollToParagraphId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToParagraph(_scrollToParagraphId!);
        });
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      stopwatch.stop();
      dev.log('❌ Ошибка загрузки за ${stopwatch.elapsedMilliseconds}ms: $e');
      _isLoading = false;
      _loadingError =
          'Ошибка загрузки: ${e.toString()}'; // <--- set loading error
      refreshUI();
    }
  }

  // Загружает главу и соседние главы
  Future<void> _loadChapterWithNeighbors(int chapterOrderNum) async {
    final stopwatch = Stopwatch()..start();
    dev.log('🔄 Загрузка главы $chapterOrderNum и соседних...');

    // Get chapter list to find chapter IDs
    final chapterList = await _repository.getChapterList(_regulationId);

    // Подготавливаем список задач для параллельной загрузки
    final List<Future<void>> loadTasks = [];

    // Добавляем задачу загрузки текущей главы
    final targetChapterInfo = chapterList.firstWhere(
      (ch) => ch.orderNum == chapterOrderNum,
      orElse: () => throw Exception('Chapter $chapterOrderNum not found'),
    );
    loadTasks.add(_loadChapterDataById(targetChapterInfo.id, chapterOrderNum));

    // Добавляем задачу загрузки предыдущей главы если есть
    if (chapterOrderNum > 1) {
      // final prevChapterInfo = chapterList.firstWhere(
      //   (ch) => ch.orderNum == chapterOrderNum - 1,
      //   orElse: () => throw Exception('Previous chapter not found'),
      // );
      // loadTasks
      //     .add(_loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
      try {
        final prevChapterInfo =
            chapterList.firstWhere((ch) => ch.orderNum == chapterOrderNum - 1);
        loadTasks
            .add(_loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
      } catch (e) {
        // ignore
      }
    }

    // Добавляем задачу загрузки следующей главы если есть
    // if (chapterOrderNum < chapterList.length) {
    //   final nextChapterInfo = chapterList.firstWhere(
    //     (ch) => ch.orderNum == chapterOrderNum + 1,
    //     orElse: () => throw Exception('Next chapter not found'),
    //   );
    //   loadTasks
    //       .add(_loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
    if (chapterOrderNum < chapterList.length) {
      try {
        final nextChapterInfo =
            chapterList.firstWhere((ch) => ch.orderNum == chapterOrderNum + 1);
        loadTasks
            .add(_loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
      } catch (e) {
        // ignore
      }
    }

    // Выполняем все задачи параллельно
    await Future.wait(loadTasks);

    stopwatch.stop();
    dev.log(
        '✅ Загрузка соседних глав завершена за ${stopwatch.elapsedMilliseconds}ms (параллельно)');
  }

  // Загружает данные конкретной главы по ID
  Future<void> _loadChapterDataById(int chapterId, int chapterOrderNum) async {
    if (_chaptersData.containsKey(chapterOrderNum)) {
      return; // Уже загружена
    }

    final stopwatch = Stopwatch()..start();
    dev.log('📖 Загрузка главы $chapterOrderNum (ID: $chapterId)...');

    // Use the new optimized method to get chapter content
    final chapter =
        await _repository.getChapterContent(_regulationId, chapterId);

    // Применяем форматирование ко всем главам
    List<Paragraph> updatedParagraphs =
        await _dataRepository.applyParagraphEdits(chapter.paragraphs);
    dev.log(
        '🎨 Применено форматирование для ${updatedParagraphs.length} параграфов в главе $chapterOrderNum');

    _chaptersData[chapterOrderNum] = {
      'id': chapter.id,
      'num': chapter.num,
      'title': chapter.title,
      'content': chapter.content,
      'paragraphs': updatedParagraphs,
    };

    stopwatch.stop();
    dev.log(
        '✅ Глава $chapterOrderNum загружена за ${stopwatch.elapsedMilliseconds}ms');
  }

  // Загружает главу по требованию при переключении
  Future<void> _ensureChapterLoaded(int chapterOrderNum) async {
    if (_chaptersData.containsKey(chapterOrderNum)) {
      return; // Уже загружена
    }

    try {
      // Get chapter list to find chapter ID
      final chapterList = await _repository.getChapterList(_regulationId);
      final chapterInfo = chapterList.firstWhere(
        (ch) => ch.orderNum == chapterOrderNum,
        orElse: () => throw Exception('Chapter $chapterOrderNum not found'),
      );

      await _loadChapterDataById(chapterInfo.id, chapterOrderNum);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      dev.log('❌ Error loading chapter $chapterOrderNum: $e');
    }
  }

  Map<String, dynamic>? getChapterData(int chapterOrderNum) {
    return _chaptersData[chapterOrderNum];
  }

  void onPageChanged(int newChapterOrderNum) async {
    if (_isBottomBarExpanded) {
      collapseBottomBar();
    }

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
      try {
        // Get chapter list to find chapter IDs
        final chapterList = await _repository.getChapterList(_regulationId);

        // Подготавливаем список задач для параллельной загрузки
        final List<Future<void>> loadTasks = [];

        // Добавляем задачу загрузки предыдущей главы если есть
        if (chapterOrderNum > 1) {
          // final prevChapterInfo = chapterList.firstWhere(
          //   (ch) => ch.orderNum == chapterOrderNum - 1,
          //   orElse: () => throw Exception('Previous chapter not found'),
          // );
          // loadTasks.add(
          //     _loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
          try {
            final prevChapterInfo = chapterList
                .firstWhere((ch) => ch.orderNum == chapterOrderNum - 1);
            loadTasks.add(
                _loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
          } catch (e) {
            // ignore
          }
        }

        // Добавляем задачу загрузки следующей главы если есть
        // if (chapterOrderNum < chapterList.length) {
        //   final nextChapterInfo = chapterList.firstWhere(
        //     (ch) => ch.orderNum == chapterOrderNum + 1,
        //     orElse: () => throw Exception('Next chapter not found'),
        //   );
        //   loadTasks.add(
        //       _loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
        if (chapterOrderNum < _totalChapters) {
          try {
            final nextChapterInfo = chapterList
                .firstWhere((ch) => ch.orderNum == chapterOrderNum + 1);
            loadTasks.add(
                _loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
          } catch (e) {
            // ignore
          }
        }

        // Выполняем все задачи параллельно
        if (loadTasks.isNotEmpty) {
          await Future.wait(loadTasks);
          dev.log('🔄 Соседние главы загружены в фоне (параллельно)');
        }
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        dev.log('❌ Error loading neighbor chapters: $e');
      }
    });
  }

  void goToChapter(int chapterOrderNum) {
    dev.log('goToChapter: $chapterOrderNum');
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
    if (pageController.hasClients && _currentChapterOrderNum > 1) {
      pageController.previousPage(
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void goToNextChapter() {
    if (pageController.hasClients && _currentChapterOrderNum < _totalChapters) {
      pageController.nextPage(
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void goToParagraph(int paragraphNum) {
    // Ищем параграф только в текущей главе
    final result =
        _findParagraphInChapter(_currentChapterOrderNum, paragraphNum);

    if (result != null) {
      // Параграф найден в текущей главе
      _scrollToParagraphInCurrentChapter(_currentChapterOrderNum, result);
      return;
    }
  }

  /// Ищет параграф в конкретной главе
  int? _findParagraphInChapter(int chapterOrderNum, int paragraphOrderNum) {
    final chapterData = _chaptersData[chapterOrderNum];
    if (chapterData == null) return null;

    final paragraphs = chapterData['paragraphs'] as List<Paragraph>;

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];

      // Try matching by different ID types
      bool found = false;

      // Check database IDs
      if (
          // paragraph.originalId == paragraphId ||
          paragraph.id == paragraphOrderNum ||
              paragraph.num == paragraphOrderNum) {
        found = true;
      }

      // Also check HTML anchor IDs in content
      if (!found && paragraph.content.isNotEmpty) {
        // Look for anchor tags with matching ID
        final anchorRegex = RegExp('<a\s+id=["\']([0-9]+)["\']');
        final matches = anchorRegex.allMatches(paragraph.content);

        for (final match in matches) {
          final anchorId = int.tryParse(match.group(1) ?? '');
          if (anchorId == paragraphOrderNum) {
            found = true;
            break;
          }
        }

        // Also try matching paragraph numbers in content (like "1.1", "2.3", etc.)
        if (!found) {
          final numberRegex = RegExp(r'(\d+)\.(\d+)');
          final numberMatches = numberRegex.allMatches(paragraph.content);
          for (final match in numberMatches) {
            final fullNumber = '${match.group(1)}${match.group(2)}';
            if (int.tryParse(fullNumber) == paragraphOrderNum) {
              found = true;
              break;
            }
          }
        }

        // Try matching formatted paragraph numbers like "6.14" directly
        if (!found) {
          final simpleNumberRegex = RegExp(r'(\d+)\.(\d+)');
          final numberMatches = simpleNumberRegex.allMatches(paragraph.content);
          for (final match in numberMatches) {
            final chapterNum = int.tryParse(match.group(1) ?? '');
            final paragraphNum = int.tryParse(match.group(2) ?? '');

            if (chapterNum != null && paragraphNum != null) {
              final combinedNumber = int.tryParse('$chapterNum$paragraphNum');
              if (combinedNumber == paragraphOrderNum) {
                found = true;
                break;
              }
            }
          }
        }
      }

      if (found) {
        return i + 1; // 1-based order number in chapter
      }
    }

    return null;
  }

  Future<void> _scrollToParagraphInCurrentChapter(
      int chapterOrderNum, int paragraphOrderNum) async {
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
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        dev.log('❌ Error jumping to paragraph: $e');
      }
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
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
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

      // Look for anchor IDs
      final anchorRegex = RegExp('<a\s+id=["\']([0-9]+)["\']');
      final matches = anchorRegex.allMatches(p.content);
      final anchorIds = matches.map((m) => m.group(1)).toList();
      if (anchorIds.isNotEmpty) {}
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

  Future<void> setTextSelection(Paragraph paragraph, int start, int end) async {
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
          } catch (e, stackTrace) {
            _handleError('Ошибка выделения текста', stackTrace: stackTrace);
          }
        } else {
          _lastSelectedText = '';
        }
      } else {
        _lastSelectedText = '';
      }

      _error = null; // Clear any previous errors
      refreshUI();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
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
        _handleError('Параграф не выбран');
        return;
      }

      if (_selectionStart == _selectionEnd && tag != Tag.c) {
        final errorMsg = tag == Tag.m
            ? 'Вы не выделили участок параграфа, который собираетесь выделить.'
            : 'Вы не выделили участок параграфа, который собираетесь подчеркнуть.';
        _handleError(errorMsg);
        return;
      }

      String content = _selectedParagraph!.content;

      if (tag == Tag.c) {
        if (!TextUtils.hasFormatting(content)) {
          _handleError(
              'В параграфе нет заметок, которые можно было бы очистить.');
          return;
        }
        // Clear all formatting - this is safe
        content = TextUtils.removeAllFormatting(content);
      } else {
        // For text formatting, we need to be more careful about HTML vs plain text
        String plainText = TextUtils.parseHtmlString(content);

        if (plainText.isEmpty) {
          _handleError('Пустой текст параграфа');
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
          } catch (substringError, stackTrace) {
            _handleError(substringError, stackTrace: stackTrace);
            return;
          }
        } else {
          _handleError('Неверные границы выделения');
          return;
        }
      }

      // Save to database using originalId
      try {
        await _dataRepository.saveParagraphEditByOriginalId(
            _selectedParagraph!.originalId, content, _selectedParagraph!);
      } catch (saveError, stackTrace) {
        _handleError(saveError, stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
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
  // static const int _maxTtsTextLength =
  //     1500; // Reduced from 3000 to be much more conservative

  Future<void> playTTS(Paragraph paragraph) async {
    try {
      // Сбрасываем флаг остановки в начале воспроизведения
      _stopRequested = false;

      // Убираем установку текущего параграфа для одиночного воспроизведения
      dev.log('🎵 TTS: Playing single paragraph ID: ${paragraph.id}');

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
        textToSpeak = await _extractTableText(paragraph.content);
      }

      if (textToSpeak.trim().isNotEmpty) {
        _ttsUseCase.execute(_TTSUseCaseObserver(this),
            TTSUseCaseParams.speak(textToSpeak.trim()));
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
      _currentTTSParagraph = null; // Очищаем при ошибке
      dev.log('🎵 TTS: Error occurred, clearing current paragraph');
    }
  }

  Future<void> playChapterTTS() async {
    try {
      _stopRequested = false;
      _isPlayingChapter = true;

      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final paragraphs = (chapterData['paragraphs'] as List<Paragraph>)
            .where((p) => !p.isTable)
            .toList();

        dev.log(
            '🎵 Starting TTS for chapter $_currentChapterOrderNum with ${paragraphs.length} paragraphs');

        // Создаем структуру для хранения информации о чанках
        List<Map<String, dynamic>> chunksInfo = [];

        for (int i = 0; i < paragraphs.length; i++) {
          final paragraph = paragraphs[i];
          String textToSpeak = '';

          dev.log(
              '📝 Processing paragraph ${i + 1}/${paragraphs.length} (ID: ${paragraph.id})');

          if (paragraph.textToSpeech != null &&
              paragraph.textToSpeech!.isNotEmpty) {
            textToSpeak = paragraph.textToSpeech!;
          } else {
            textToSpeak = TextUtils.parseHtmlString(paragraph.content);
          }

          if (textToSpeak.trim().isEmpty && paragraph.isTable) {
            textToSpeak = await _extractTableText(paragraph.content);
          }

          if (textToSpeak.trim().isNotEmpty) {
            chunksInfo.add({
              'text': textToSpeak.trim(),
              'paragraph': paragraph,
            });
          }
        }

        if (chunksInfo.isEmpty) {
          dev.log('❌ No text to speak');
          return;
        }

        // Воспроизводим чанки
        await _playChapterInChunks(chunksInfo);
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
      dev.log('❌ Error in playChapterTTS: $e');
    }
  }

  /// Extracts readable text from table HTML content
  Future<String> _extractTableText(String htmlContent) async {
    try {
      dev.log(
          '📊 Extracting table text from HTML (${htmlContent.length} chars)');

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
        dev.log('📊 Table text too short, trying aggressive extraction');

        // Try to extract text from anchor tags and other elements
        final anchorRegex = RegExp(r'<a[^>]*>([^<]*)</a>');
        final anchorMatches = anchorRegex.allMatches(htmlContent);
        final anchorTexts = anchorMatches
            .map((m) => m.group(1)?.trim() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();

        if (anchorTexts.isNotEmpty) {
          text = anchorTexts.join(' ');
          dev.log('📊 Extracted text from anchors: "$text"');
        }
      }

      dev.log(
          '📊 Final extracted table text: "${text.substring(0, text.length > 100 ? 100 : text.length)}"');
      return text;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      dev.log('📊 Error extracting table text: $e');
      // Fallback to simple HTML parsing
      return TextUtils.parseHtmlString(htmlContent);
    }
  }

  Future<void> _playChapterInChunks(
      List<Map<String, dynamic>> chunksInfo) async {
    try {
      dev.log('🎵 _playChapterInChunks: Starting chapter playback');

      if (_stopRequested || !_isPlayingChapter) {
        dev.log('🎵 _playChapterInChunks: Playback stopped before starting');
        return;
      }

      for (int i = 0; i < chunksInfo.length; i++) {
        if (_stopRequested || !_isPlayingChapter) {
          dev.log(
              '🎵 _playChapterInChunks: Playback stopped at chunk ${i + 1}');
          return;
        }

        final chunkInfo = chunksInfo[i];
        final text = chunkInfo['text'] as String;
        final paragraph = chunkInfo['paragraph'] as Paragraph;

        dev.log(
            '🎵 Playing chunk ${i + 1}/${chunksInfo.length} for paragraph ID: ${paragraph.id}');

        // Устанавливаем текущий параграф для выделения
        _currentTTSParagraph = paragraph;
        refreshUI();

        // Останавливаем предыдущий TTS если он еще играет
        if (_ttsState == TtsState.playing) {
          dev.log('🎵 Stopping previous TTS before starting new chunk');
          await stopTTS();
          await Future.delayed(const Duration(milliseconds: 500));

          if (_stopRequested || !_isPlayingChapter) {
            dev.log(
                '🎵 _playChapterInChunks: Playback stopped after stopping previous TTS');
            return;
          }
        }

        // Отправляем текст в TTS
        _ttsUseCase.execute(
            _TTSUseCaseObserver(this), TTSUseCaseParams.speak(text));

        // Ждем завершения TTS
        await _waitForTTSCompletion();

        if (_stopRequested || !_isPlayingChapter) {
          dev.log(
              '🎵 _playChapterInChunks: Playback stopped after TTS completion');
          return;
        }

        if (_ttsState == TtsState.error) {
          dev.log('❌ TTS chunk ${i + 1} failed with error');
          _handleError('Ошибка воспроизведения TTS');
          _isPlayingChapter = false;

          return;
        }

        // Пауза между параграфами
        if (i < chunksInfo.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      dev.log('🎵 All chunks completed successfully');
      // Очищаем выделение после завершения всей главы
      _currentTTSParagraph = null;
      refreshUI();
    } catch (e, stackTrace) {
      _handleError('Ошибка воспроизведения главы: ${e.toString()}',
          stackTrace: stackTrace);
      dev.log('❌ Error in _playChapterInChunks: $e');

      _isPlayingChapter = false;
    }
  }

  /// Waits for TTS to complete by monitoring the state stream
  Future<void> _waitForTTSCompletion() async {
    try {
      dev.log('🎵 _waitForTTSCompletion: Starting wait for TTS completion');

      // Проверяем остановку перед началом ожидания
      if (_stopRequested || !_isPlayingChapter) {
        dev.log('🎵 _waitForTTSCompletion: Playback stopped before waiting');
        return;
      }

      // Ждем начала воспроизведения
      dev.log('🎵 _waitForTTSCompletion: Waiting for TTS to start playing...');
      final startedPlaying = await _waitForTTSState([TtsState.playing]);
      if (!startedPlaying) {
        dev.log('❌ _waitForTTSCompletion: TTS failed to start playing');
        return;
      }
      dev.log('🎵 _waitForTTSCompletion: TTS started playing');

      // Проверяем остановку после начала воспроизведения
      if (_stopRequested || !_isPlayingChapter) {
        dev.log('🎵 _waitForTTSCompletion: Playback stopped after TTS started');
        return;
      }

      // Ждем завершения TTS
      dev.log('🎵 _waitForTTSCompletion: Waiting for TTS to complete...');
      final completed =
          await _waitForTTSState([TtsState.stopped, TtsState.error]);
      dev.log('🎵 _waitForTTSCompletion: TTS completed, result: $completed');

      // Проверяем остановку после завершения
      if (_stopRequested || !_isPlayingChapter) {
        dev.log(
            '🎵 _waitForTTSCompletion: Playback stopped after TTS completion');
        return;
      }

      // Проверяем ошибку
      if (_ttsState == TtsState.error) {
        dev.log('❌ _waitForTTSCompletion: TTS ended with error');
      } else {
        dev.log('🎵 _waitForTTSCompletion: TTS completed successfully');
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      dev.log('⚠️ _waitForTTSCompletion: Error or timeout: $e');
    }
  }

  /// Waits for TTS to reach any of the target states
  Future<bool> _waitForTTSState(List<TtsState> targetStates) async {
    dev.log('🎵 _waitForTTSState: Waiting for states: $targetStates');
    final completer = Completer<bool>();
    StreamSubscription<TtsState>? subscription;

    subscription = _ttsUseCase.stateStream.listen((state) {
      dev.log('🎵 _waitForTTSState: Received state: $state');

      // Проверяем остановку
      if (_stopRequested || !_isPlayingChapter) {
        dev.log('🎵 _waitForTTSState: Playback stopped, completing with false');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return;
      }

      // Проверяем достижение целевого состояния
      if (targetStates.contains(state)) {
        dev.log('🎵 _waitForTTSState: Target state reached: $state');
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    final result = await completer.future;
    dev.log('🎵 _waitForTTSState: Wait completed with result: $result');
    return result;
  }

  Future<void> stopTTS() async {
    try {
      dev.log(
          '🎵 STOP TTS CALLED - Setting stop flag and stopping chapter playback');
      _stopRequested = true; // Устанавливаем флаг остановки
      _isPlayingChapter = false; // Останавливаем воспроизведение главы
      _currentTTSParagraph = null; // Очищаем текущий читаемый параграф
      dev.log('🎵 TTS: Clearing current paragraph in stopTTS');
      refreshUI(); // Обновляем UI для снятия выделения

      // Вызываем stop() в TTS репозитории
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.stop());

      // Дополнительная проверка: если TTS все еще в состоянии paused, принудительно останавливаем
      if (_ttsState == TtsState.paused) {
        dev.log('🎵 TTS still paused after stop call, forcing stop again...');
        await Future.delayed(
            const Duration(milliseconds: 200)); // Небольшая задержка
        _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.stop());
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
      dev.log('🎵 Error in stopTTS(): $e');

      _currentTTSParagraph = null; // Очищаем при ошибке
      dev.log('🎵 TTS: Clearing current paragraph due to error in stopTTS');
    }
  }

  Future<void> pauseTTS() async {
    try {
      dev.log('🎵 PAUSE TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.pause());
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
    }
  }

  Future<void> resumeTTS() async {
    try {
      dev.log('🎵 RESUME TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.resume());
    } catch (e, stackTrace) {
      _handleError(e, stackTrace: stackTrace);
    }
  }

  @override
  void refreshUI() {
    dev.log(
        '🔄 RefreshUI called - currentTTSParagraph: ${_currentTTSParagraph?.id ?? "null"}');
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
    _checkSubscriptionUseCase.dispose();
    _downloadRegulationDataUseCase.dispose();

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

      // Обновляем форматирование в текущей главе
      await _refreshCurrentChapterFormatting();

      _error = null;
      refreshUI();
    } catch (e, stackTrace) {
      _handleError('Ошибка сохранения: ${e.toString()}',
          stackTrace: stackTrace);
    }
  }

  // Обновляет форматирование в текущей главе
  Future<void> _refreshCurrentChapterFormatting() async {
    try {
      final chapterData = getChapterData(_currentChapterOrderNum);
      if (chapterData != null) {
        final originalParagraphs = chapterData['paragraphs'] as List<Paragraph>;
        final updatedParagraphs =
            await _dataRepository.applyParagraphEdits(originalParagraphs);

        _chaptersData[_currentChapterOrderNum] = {
          ...chapterData,
          'paragraphs': updatedParagraphs,
        };

        dev.log(
            '🔄 Форматирование обновлено для главы $_currentChapterOrderNum');
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      dev.log('❌ Ошибка обновления форматирования: $e');
    }
  }

  Future<void> _handleDownloadAction(
      int documentId, int chapterNum, int paragraphNum) async {
    _isLoading = true;
    refreshUI();

    try {
      final downloadStream =
          await _downloadRegulationDataUseCase.buildUseCaseStream(documentId);
      await downloadStream.drain();
// Invalidate library cache so it re-fetches the download status
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LibraryController.lastFetchDateKey);
      await prefs.remove(LibraryController.regulationsCacheKey);
      dev.log('Library cache invalidated after download from ChapterView.');
      _isLoading = false;
      refreshUI();
      Navigator.of(getContext()).push(
        MaterialPageRoute(
          builder: (context) => ChapterView(
            regulationId: documentId,
            initialChapterOrderNum: chapterNum,
            scrollToParagraphId: paragraphNum,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
            regulationRepository: _repository,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _handleError('Ошибка: ${e.toString()}', stackTrace: stackTrace);
      _isLoading = false;
    }
  }

  Future<void> navigateToDifferentDocument(
      int documentId, int chapterNum, int paragraphNum) async {
    bool isCached = await _repository.isRegulationCached(documentId);

    if (isCached) {
      Navigator.of(getContext()).push(
        MaterialPageRoute(
          builder: (context) => ChapterView(
            regulationId: documentId,
            initialChapterOrderNum: chapterNum,
            scrollToParagraphId: paragraphNum,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
            regulationRepository: _repository, // Pass the static repo instance
          ),
        ),
      );
    } else {
      showDialog(
        context: getContext(),
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            content: const Text(
                'Документ не загружен. Загрузите его из Библиотеки.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Отмена'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Загрузить'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleDownloadAction(documentId, chapterNum, paragraphNum);
                },
              ),
            ],
          );
        },
      );
    }
  }
}

class _TTSUseCaseObserver extends Observer<void> {
  final ChapterController _controller;

  _TTSUseCaseObserver(this._controller);

  @override
  void onComplete() {
    dev.log(
        '🎵 TTS Observer: onComplete called - NOT clearing current paragraph');
    // НЕ очищаем текущий читаемый параграф при завершении TTS
    // Пусть пользователь сам остановит или это сделает stopTTS()
    _controller.refreshUI();
  }

  @override
  void onError(e) {
    dev.log('❌ TTS Observer: onError called with: $e');
    _controller._handleError(e);
    // Очищаем текущий читаемый параграф только при ошибке TTS
    _controller._currentTTSParagraph = null;
    dev.log('🎵 TTS Observer: Clearing current paragraph in onError');
  }

  @override
  void onNext(_) {
    dev.log('🎵 TTS Observer: onNext called');
  }
}
