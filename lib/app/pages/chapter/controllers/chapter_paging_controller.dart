import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../domain/entities/paragraph.dart';
import '../../../../data/repositories/data_regulation_repository.dart';
import '../../../../data/repositories/static_regulation_repository.dart';
import 'dart:developer' as dev;

class ChapterPagingController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final int? _scrollToParagraphId;
  final StaticRegulationRepository _repository = StaticRegulationRepository();
  final DataRegulationRepository _dataRepository =
      DataRegulationRepository(); // No longer needs DatabaseHelper

  // PageView управление
  late PageController pageController;
  late TextEditingController pageTextController;

  // ScrollController for each chapter
  final Map<int, ScrollController> _chapterScrollControllers = {};

  // ItemScrollController for precise scrolling
  final Map<int, ItemScrollController> _itemScrollControllers = {};

  // GlobalKeys for precise scrolling to paragraphs
  final Map<int, Map<int, GlobalKey>> _paragraphKeys =
      {}; // chapterOrderNum -> paragraphIndex -> GlobalKey

  final Map<int, Map<String, dynamic>> _chaptersData = {};
  int _currentChapterOrderNum = 1;
  int _totalChapters = 0;
  bool _isLoading = true;
  String? _error;
  String? _loadingError;

  // Getters
  Map<int, Map<String, dynamic>> get chaptersData => _chaptersData;
  int get currentChapterOrderNum => _currentChapterOrderNum;
  int get totalChapters => _totalChapters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get loadingError => _loadingError;

  // Navigation getters
  bool get canGoPreviousChapter => _currentChapterOrderNum > 1;
  bool get canGoNextChapter => _currentChapterOrderNum < _totalChapters;

  ChapterPagingController({
    required int regulationId,
    required int initialChapterOrderNum,
    int? scrollToParagraphId,
  })  : _regulationId = regulationId,
        _initialChapterOrderNum = initialChapterOrderNum,
        _scrollToParagraphId = scrollToParagraphId,
        _currentChapterOrderNum = initialChapterOrderNum {
    pageController = PageController(initialPage: initialChapterOrderNum - 1);
    pageTextController = TextEditingController(
      text: initialChapterOrderNum.toString(),
    );

    // Загружаем главы при создании контроллера
    loadAllChapters();
  }

  @override
  void initListeners() {
    // Initialize listeners if needed
  }

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

  // ItemScrollController methods for precise scrolling
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

  Future<void> loadAllChapters() async {
    final stopwatch = Stopwatch()..start();
    dev.log('🔄 Начало загрузки глав...');

    _isLoading = true;
    _loadingError = null;
    refreshUI();

    try {
      // Use the new optimized method to get chapter list
      final chapterList = await _repository.getChapterList(_regulationId);
      _totalChapters = chapterList.length;
      dev.log('📚 Найдено глав: $_totalChapters');

      // Загружаем только текущую главу и соседние для быстрой загрузки
      await _loadChapterWithNeighbors(_initialChapterOrderNum);

      _isLoading = false;
      _loadingError = null;
      refreshUI();

      stopwatch.stop();
      dev.log('✅ Загрузка завершена за ${stopwatch.elapsedMilliseconds}ms');

      // Delay navigation until after the PageView is built
      if (_scrollToParagraphId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToParagraph(_scrollToParagraphId!);
        });
      }
    } catch (e) {
      stopwatch.stop();
      dev.log('❌ Ошибка загрузки за ${stopwatch.elapsedMilliseconds}ms: $e');
      _isLoading = false;
      _loadingError = 'Ошибка загрузки: ${e.toString()}';
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
      final prevChapterInfo = chapterList.firstWhere(
        (ch) => ch.orderNum == chapterOrderNum - 1,
        orElse: () => throw Exception('Previous chapter not found'),
      );
      loadTasks
          .add(_loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
    }

    // Добавляем задачу загрузки следующей главы если есть
    if (chapterOrderNum < chapterList.length) {
      final nextChapterInfo = chapterList.firstWhere(
        (ch) => ch.orderNum == chapterOrderNum + 1,
        orElse: () => throw Exception('Next chapter not found'),
      );
      loadTasks
          .add(_loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
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
    final chapter = await _repository.getChapterContent(chapterId);

    // Применяем форматирование только для текущей главы
    List<Paragraph> updatedParagraphs;
    if (chapterOrderNum == _currentChapterOrderNum) {
      updatedParagraphs =
          await _dataRepository.applyParagraphEdits(chapter.paragraphs);
      dev.log(
          '🎨 Применено форматирование для ${updatedParagraphs.length} параграфов');
    } else {
      // Для соседних глав пока используем оригинальные параграфы
      updatedParagraphs = chapter.paragraphs;
    }

    _chaptersData[chapterOrderNum] = {
      'id': chapter.id,
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
    } catch (e) {
      dev.log('❌ Error loading chapter $chapterOrderNum: $e');
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
      try {
        // Get chapter list to find chapter IDs
        final chapterList = await _repository.getChapterList(_regulationId);

        // Подготавливаем список задач для параллельной загрузки
        final List<Future<void>> loadTasks = [];

        // Добавляем задачу загрузки предыдущей главы если есть
        if (chapterOrderNum > 1) {
          final prevChapterInfo = chapterList.firstWhere(
            (ch) => ch.orderNum == chapterOrderNum - 1,
            orElse: () => throw Exception('Previous chapter not found'),
          );
          loadTasks.add(
              _loadChapterDataById(prevChapterInfo.id, chapterOrderNum - 1));
        }

        // Добавляем задачу загрузки следующей главы если есть
        if (chapterOrderNum < chapterList.length) {
          final nextChapterInfo = chapterList.firstWhere(
            (ch) => ch.orderNum == chapterOrderNum + 1,
            orElse: () => throw Exception('Next chapter not found'),
          );
          loadTasks.add(
              _loadChapterDataById(nextChapterInfo.id, chapterOrderNum + 1));
        }

        // Выполняем все задачи параллельно
        if (loadTasks.isNotEmpty) {
          await Future.wait(loadTasks);
          dev.log('🔄 Соседние главы загружены в фоне (параллельно)');
        }
      } catch (e) {
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
          }
        });
      }
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

  void goToParagraph(int paragraphId) {
    // Ищем параграф только в текущей главе
    final result =
        _findParagraphInChapter(_currentChapterOrderNum, paragraphId);

    if (result != null) {
      // Параграф найден в текущей главе
      _scrollToParagraphInCurrentChapter(_currentChapterOrderNum, result);
      return;
    }

    // Если не найден в текущей главе, ищем во всех загруженных главах
    final globalResult = _findParagraphInAllChapters(paragraphId);

    if (globalResult != null) {
      final targetChapter = globalResult['chapterOrderNum'] as int;
      final paragraphOrderNum = globalResult['paragraphOrderNum'] as int;

      // Переходим на главу и скроллим к параграфу
      if (_currentChapterOrderNum == targetChapter) {
        _scrollToParagraphInCurrentChapter(targetChapter, paragraphOrderNum);
      } else {
        goToChapter(targetChapter);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (_currentChapterOrderNum == targetChapter) {
            _scrollToParagraphInCurrentChapter(
                targetChapter, paragraphOrderNum);
          }
        });
      }
    } else {
      dev.log('❌ Paragraph $paragraphId not found in any loaded chapter');
    }
  }

  /// Ищет параграф в конкретной главе
  int? _findParagraphInChapter(int chapterOrderNum, int paragraphId) {
    final chapterData = _chaptersData[chapterOrderNum];
    if (chapterData == null) return null;

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
            break;
          }
        }
      }

      if (found) {
        return i; // Return paragraph index
      }
    }

    return null;
  }

  /// Ищет параграф во всех загруженных главах
  Map<String, dynamic>? _findParagraphInAllChapters(int paragraphId) {
    for (final entry in _chaptersData.entries) {
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
              break;
            }
          }
        }

        if (found) {
          return {
            'chapterOrderNum': chapterOrderNum,
            'paragraphOrderNum': i,
          };
        }
      }
    }

    return null;
  }

  /// Скроллит к параграфу в текущей главе
  void _scrollToParagraphInCurrentChapter(
      int chapterOrderNum, int paragraphIndex) {
    try {
      final itemScrollController =
          getItemScrollControllerForChapter(chapterOrderNum);

      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: paragraphIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        dev.log(
            '📖 Scrolled to paragraph $paragraphIndex in chapter $chapterOrderNum');
      } else {
        dev.log(
            '❌ ItemScrollController not attached for chapter $chapterOrderNum');
      }
    } catch (e) {
      dev.log('❌ Error scrolling to paragraph: $e');
    }
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

    // Clear all item scroll controllers
    _itemScrollControllers.clear();

    // Clear all paragraph keys
    _paragraphKeys.clear();

    super.onDisposed();
  }
}
