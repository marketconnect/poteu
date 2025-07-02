import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Added for WidgetsBinding
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../domain/entities/formatting.dart';
import '../../../data/repositories/static_regulation_repository.dart';
import '../../../data/repositories/data_regulation_repository.dart';
import '../../../data/helpers/database_helper.dart';
import '../../utils/text_utils.dart';

class ChapterController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final int? _scrollToParagraphId;
  final StaticRegulationRepository _repository = StaticRegulationRepository();
  final DataRegulationRepository _dataRepository = DataRegulationRepository(
    DatabaseHelper(),
  );

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

  // ScrollController methods
  ScrollController getScrollControllerForChapter(int chapterOrderNum) {
    if (!_chapterScrollControllers.containsKey(chapterOrderNum)) {
      _chapterScrollControllers[chapterOrderNum] = ScrollController();
      print('Created ScrollController for chapter $chapterOrderNum');
    }
    return _chapterScrollControllers[chapterOrderNum]!;
  }

  ScrollController get currentChapterScrollController {
    return getScrollControllerForChapter(_currentChapterOrderNum);
  }

  // ItemScrollController methods for precise scrolling (like original)
  ItemScrollController getItemScrollControllerForChapter(int chapterOrderNum) {
    if (!_itemScrollControllers.containsKey(chapterOrderNum)) {
      _itemScrollControllers[chapterOrderNum] = ItemScrollController();
      print('Created ItemScrollController for chapter $chapterOrderNum');
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
      print(
          'Created GlobalKey for chapter $chapterOrderNum, paragraph $paragraphIndex');
    }
    return _paragraphKeys[chapterOrderNum]![paragraphIndex]!;
  }

  void clearParagraphKeys(int chapterOrderNum) {
    _paragraphKeys[chapterOrderNum]?.clear();
    print('Cleared paragraph keys for chapter $chapterOrderNum');
  }

  ChapterController({
    required int regulationId,
    required int initialChapterOrderNum,
    int? scrollToParagraphId,
  })  : _regulationId = regulationId,
        _initialChapterOrderNum = initialChapterOrderNum,
        _scrollToParagraphId = scrollToParagraphId,
        _currentChapterOrderNum = initialChapterOrderNum {
    print('=== CHAPTER CONTROLLER CONSTRUCTOR ===');
    print('regulationId: $regulationId');
    print('initialChapterOrderNum: $initialChapterOrderNum');
    print('scrollToParagraphId: $scrollToParagraphId');

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

      // Delay navigation until after the PageView is built
      if (_scrollToParagraphId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToParagraph(_scrollToParagraphId!);
        });
      }
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
    print('=== GO TO CHAPTER ===');
    print('Target chapter: $chapterOrderNum');
    print('Total chapters: $_totalChapters');
    print('PageController has clients: ${pageController.hasClients}');

    if (chapterOrderNum >= 1 && chapterOrderNum <= _totalChapters) {
      if (pageController.hasClients) {
        print(
            'PageController is attached, animating to page ${chapterOrderNum - 1}');
        pageController.animateToPage(
          chapterOrderNum - 1,
          duration: const Duration(seconds: 1),
          curve: Curves.ease,
        );
      } else {
        print('PageController not attached yet, scheduling for next frame');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pageController.hasClients) {
            pageController.animateToPage(
              chapterOrderNum - 1,
              duration: const Duration(seconds: 1),
              curve: Curves.ease,
            );
          } else {
            print(
                'ERROR: PageController still not attached after post frame callback');
          }
        });
      }
    } else {
      print(
          'ERROR: Invalid chapter number $chapterOrderNum (total: $_totalChapters)');
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
    print('=== GO TO PARAGRAPH ===');
    print('Looking for paragraph ID: $paragraphId');
    print('Available chapters: ${_chaptersData.keys.toList()}');

    // First, try to find the paragraph by ID to get its order number
    int? targetChapterOrderNum;
    int?
        paragraphOrderNum; // This will be the order number in the chapter (1-based)

    for (final MapEntry<int, Map<String, dynamic>> entry
        in _chaptersData.entries) {
      final chapterOrderNum = entry.key;
      final chapterData = entry.value;

      print('Searching in chapter $chapterOrderNum (${chapterData['title']})');
      final paragraphs = chapterData['paragraphs'] as List<Paragraph>;
      print('Chapter $chapterOrderNum has ${paragraphs.length} paragraphs');

      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i];
        print(
            '  Paragraph $i: id=${paragraph.id}, originalId=${paragraph.originalId}, num=${paragraph.num}');

        // Try matching by different ID types
        bool found = false;

        // Check database IDs
        if (paragraph.originalId == paragraphId ||
            paragraph.id == paragraphId ||
            paragraph.num == paragraphId) {
          found = true;
          paragraphOrderNum = i + 1; // 1-based order number in chapter
          print(
              '✅ Found target paragraph in chapter $chapterOrderNum at order number $paragraphOrderNum (index $i)');
          print(
              '   Matched by: ${paragraph.originalId == paragraphId ? 'originalId' : paragraph.id == paragraphId ? 'id' : 'num'}');
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
              print(
                  '✅ Found target paragraph by HTML anchor in chapter $chapterOrderNum at order number $paragraphOrderNum (index $i)');
              print('   Matched anchor ID: $anchorId');
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
                print(
                    '✅ Found target paragraph by content number in chapter $chapterOrderNum at order number $paragraphOrderNum (index $i)');
                print(
                    '   Matched content number: ${match.group(1)}.${match.group(2)} -> $fullNumber');
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
                  print(
                      '✅ Found target paragraph by combined number in chapter $chapterOrderNum at order number $paragraphOrderNum (index $i)');
                  print(
                      '   Matched combined number: $chapterNum.$paragraphNum -> $combinedNumber');
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
      print('❌ Paragraph with ID $paragraphId not found in any chapter');
      print('Available paragraph IDs in current chapter:');
      final currentChapterData = _chaptersData[_currentChapterOrderNum];
      if (currentChapterData != null) {
        final paragraphs = currentChapterData['paragraphs'] as List<Paragraph>;
        for (int i = 0; i < paragraphs.length && i < 10; i++) {
          // Show first 10
          final p = paragraphs[i];
          print(
              '  [${i + 1}] id=${p.id}, originalId=${p.originalId}, num=${p.num}');

          // Also show anchor IDs
          final anchorRegex = RegExp('<a\\s+id=["\']([0-9]+)["\']');
          final matches = anchorRegex.allMatches(p.content);
          final anchorIds = matches.map((m) => m.group(1)).toList();
          if (anchorIds.isNotEmpty) {
            print('      anchors: ${anchorIds.join(", ")}');
          }
        }
        if (paragraphs.length > 10) {
          print('  ... and ${paragraphs.length - 10} more paragraphs');
        }
      }
      return;
    }

    // Save final values after null check
    final finalTargetChapter = targetChapterOrderNum;
    final finalParagraphOrderNum = paragraphOrderNum;

    print(
        '✅ Target found: Chapter $finalTargetChapter, Paragraph order number $finalParagraphOrderNum');

    // Check if we're already on the target chapter
    if (_currentChapterOrderNum == finalTargetChapter) {
      print('Already on target chapter, scrolling directly...');
      _scrollToParagraphInCurrentChapter(
          finalTargetChapter, finalParagraphOrderNum);
    } else {
      // Navigate to the chapter first
      print('✅ Navigating to chapter $finalTargetChapter');
      goToChapter(finalTargetChapter);

      // Then scroll to the paragraph after the page transition completes
      Future.delayed(const Duration(milliseconds: 1200), () {
        // Double-check we're on the right chapter before scrolling
        if (_currentChapterOrderNum == finalTargetChapter) {
          _scrollToParagraphInCurrentChapter(
              finalTargetChapter, finalParagraphOrderNum);
        } else {
          print('Chapter navigation not completed yet, trying again...');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_currentChapterOrderNum == finalTargetChapter) {
              _scrollToParagraphInCurrentChapter(
                  finalTargetChapter, finalParagraphOrderNum);
            } else {
              print('⚠️  Chapter navigation failed or still in progress');
            }
          });
        }
      });
    }
  }

  void _scrollToParagraphInCurrentChapter(
      int chapterOrderNum, int paragraphOrderNum) {
    print('=== SCROLL TO PARAGRAPH IN CHAPTER (PRECISE METHOD) ===');
    print(
        'Chapter: $chapterOrderNum, Paragraph order number: $paragraphOrderNum');

    // First try using ItemScrollController for precise navigation (like original)
    final itemScrollController =
        getItemScrollControllerForChapter(chapterOrderNum);

    if (itemScrollController.isAttached) {
      print('Using ItemScrollController for precise navigation');

      // Get paragraphs to validate order number
      final paragraphs =
          _chaptersData[chapterOrderNum]?['paragraphs'] as List<Paragraph>?;
      if (paragraphs == null) {
        print('❌ No paragraphs found for chapter $chapterOrderNum');
        return;
      }

      print('Total paragraphs in chapter: ${paragraphs.length}');
      print('Target paragraph order number: $paragraphOrderNum');

      // Convert 1-based order number to 0-based index
      final paragraphIndex = paragraphOrderNum - 1;

      if (paragraphIndex < 0 || paragraphIndex >= paragraphs.length) {
        print(
            '❌ Invalid paragraph order number: $paragraphOrderNum (valid range: 1-${paragraphs.length})');
        return;
      }

      // In the list, index 0 is title, so paragraph order N is at index N
      // But in ItemScrollController, we jump directly to the item index
      // Since our ListView has title at index 0, paragraph order 1 is at index 1
      final targetItemIndex =
          paragraphOrderNum; // Direct mapping: order 1 -> index 1, order 2 -> index 2, etc.

      print(
          'Jumping to item index: $targetItemIndex (paragraph order $paragraphOrderNum)');

      try {
        itemScrollController.jumpTo(index: targetItemIndex);
        print(
            '✅ Successfully jumped to item index $targetItemIndex using ItemScrollController');
        return;
      } catch (e) {
        print('❌ Error jumping with ItemScrollController: $e');
        print('Falling back to ScrollController method...');
      }
    } else {
      print('ItemScrollController not attached yet, trying again in 300ms...');
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphOrderNum);
      });
      return;
    }

    // Fallback to ScrollController method if ItemScrollController fails
    print('=== FALLBACK TO SCROLLCONTROLLER METHOD ===');
    final scrollController = getScrollControllerForChapter(chapterOrderNum);

    if (!scrollController.hasClients) {
      print('ScrollController has no clients yet, retrying...');
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphOrderNum);
      });
      return;
    }

    try {
      print('ScrollController has clients, calculating position...');

      // Get paragraphs to understand total count
      final paragraphs =
          _chaptersData[chapterOrderNum]?['paragraphs'] as List<Paragraph>?;
      if (paragraphs == null) {
        print('❌ No paragraphs found for chapter $chapterOrderNum');
        return;
      }

      print('Total paragraphs in chapter: ${paragraphs.length}');
      print('Target paragraph order number: $paragraphOrderNum');

      // Convert 1-based order number to 0-based index
      final paragraphIndex = paragraphOrderNum - 1;

      if (paragraphIndex < 0 || paragraphIndex >= paragraphs.length) {
        print(
            '❌ Invalid paragraph order number: $paragraphOrderNum (valid range: 1-${paragraphs.length})');
        return;
      }

      // Use a more accurate calculation based on paragraph types and content
      double targetPosition =
          _calculatePositionForParagraphIndex(paragraphs, paragraphIndex);

      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final finalPosition = targetPosition.clamp(0.0, maxScrollExtent);

      print('Calculated target position: $targetPosition');
      print(
          'Clamped to max scroll extent: $finalPosition (max: $maxScrollExtent)');

      // Scroll to the calculated position
      scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );

      print('✅ Scroll animation started to position $finalPosition');
    } catch (e) {
      print('❌ Error in order number scrolling: $e');
      print('Trying simple fallback...');
      _scrollToParagraphFallback(chapterOrderNum,
          paragraphOrderNum - 1); // Convert to 0-based for fallback
    }
  }

  /// Calculate position for a paragraph index using more accurate height estimation
  double _calculatePositionForParagraphIndex(
      List<Paragraph> paragraphs, int targetParagraphIndex) {
    print(
        '=== CALCULATING POSITION FOR PARAGRAPH INDEX $targetParagraphIndex ===');

    // Title section height (fixed)
    const double titleHeight = 70.0; // title height + padding
    double totalHeight = titleHeight;

    print('Starting with title height: $titleHeight');

    // Calculate height for all paragraphs before the target
    for (int i = 0; i < targetParagraphIndex && i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final paragraphHeight = _calculateParagraphHeight(paragraph);
      totalHeight += paragraphHeight;

      print(
          'Paragraph $i: estimated height = $paragraphHeight, total = $totalHeight');
    }

    print('Final calculated position: $totalHeight');
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
    print('=== FALLBACK SCROLL METHOD ===');
    final scrollController = getScrollControllerForChapter(chapterOrderNum);

    if (scrollController.hasClients) {
      print('ScrollController has clients, using fallback calculation...');

      // Simplified fallback calculation - much more conservative
      const titleHeight = 100.0; // Title section height
      const averageParagraphHeight = 80.0; // Average paragraph height

      double targetPosition =
          titleHeight + (paragraphIndex * averageParagraphHeight);

      // Add some extra offset to ensure target paragraph is visible
      targetPosition += 20.0;

      print('Fallback calculated position: $targetPosition');

      // Get max scroll extent to avoid over-scrolling
      final maxScroll = scrollController.position.maxScrollExtent;
      final finalPosition =
          targetPosition > maxScroll ? maxScroll : targetPosition;

      print('Final fallback position: $finalPosition (max: $maxScroll)');

      scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      print('ScrollController has no clients yet, trying again...');
      // Try again after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToParagraphInCurrentChapter(chapterOrderNum, paragraphIndex);
      });
    }
  }

  /// Debug function to print information about paragraphs in current chapter
  void debugPrintChapterParagraphs() {
    print('=== DEBUG: CHAPTER $currentChapterOrderNum PARAGRAPHS ===');
    final chapterData = getChapterData(currentChapterOrderNum);
    if (chapterData == null) {
      print('No chapter data available');
      return;
    }

    final paragraphs = chapterData['paragraphs'] as List<Paragraph>;
    print('Total paragraphs: ${paragraphs.length}');

    for (int i = 0; i < paragraphs.length && i < 20; i++) {
      // Show first 20
      final p = paragraphs[i];

      final plainText = TextUtils.parseHtmlString(p.content);
      final preview = plainText.length > 50
          ? '${plainText.substring(0, 50)}...'
          : plainText;

      print('[$i] id=${p.id}, originalId=${p.originalId}, num=${p.num}');
      print(
          '    class="${p.paragraphClass}", table=${p.isTable}, nft=${p.isNft}');
      print('    preview: "$preview"');

      // Look for anchor IDs
      final anchorRegex = RegExp('<a\\s+id=["\']([0-9]+)["\']');
      final matches = anchorRegex.allMatches(p.content);
      final anchorIds = matches.map((m) => m.group(1)).toList();
      if (anchorIds.isNotEmpty) {
        print('    anchors: ${anchorIds.join(", ")}');
      }

      // Look for number patterns
      final numberRegex = RegExp(r'(\d+)\.(\d+)');
      final numberMatches = numberRegex.allMatches(p.content);
      if (numberMatches.isNotEmpty) {
        final numbers =
            numberMatches.map((m) => '${m.group(1)}.${m.group(2)}').toList();
        print('    numbers: ${numbers.join(", ")}');
      }

      print('');
    }

    if (paragraphs.length > 20) {
      print('... and ${paragraphs.length - 20} more paragraphs');
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
      try {
        await _dataRepository.saveParagraphEditByOriginalId(
            _selectedParagraph!.originalId, content, _selectedParagraph!);
        print('✅ Successfully saved to database');
        print('Original ID: ${_selectedParagraph!.originalId}');
        print('New content: "$content"');
      } catch (saveError) {
        print('❌ Failed to save to database: $saveError');
        _error = 'Ошибка сохранения: ${saveError.toString()}';
        refreshUI();
        return;
      }

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

    // Dispose all scroll controllers
    for (final controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    _chapterScrollControllers.clear();
    print('Disposed ${_chapterScrollControllers.length} scroll controllers');

    // Clear all item scroll controllers (they don't need explicit disposal)
    _itemScrollControllers.clear();
    print('Cleared ${_itemScrollControllers.length} item scroll controllers');

    // Clear all paragraph keys
    _paragraphKeys.clear();
    print('Cleared all paragraph keys');

    super.onDisposed();
  }
}
