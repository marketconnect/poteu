import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../domain/entities/paragraph.dart';
import '../../../../domain/entities/search_result.dart';
import '../../../../domain/entities/tts_state.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/tts_repository.dart';
import '../../../../domain/repositories/regulation_repository.dart';
import '../../../../data/repositories/static_regulation_repository.dart';
import 'chapter_paging_controller.dart';
import 'text_formatting_controller.dart';
import 'tts_controller.dart';
import 'chapter_search_controller.dart';

class ChapterController extends Controller {
  final int _regulationId;
  // final int _initialChapterOrderNum;
  // final int? _scrollToParagraphId;

  // Specialized controllers
  late ChapterPagingController _pagingController;
  late TextFormattingController _formattingController;
  late TtsController _ttsController;
  late ChapterSearchController _searchController;

  ChapterController({
    required int regulationId,
    required int initialChapterOrderNum,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required RegulationRepository regulationRepository,
    int? scrollToParagraphId,
  }) : _regulationId = regulationId
  // _initialChapterOrderNum = initialChapterOrderNum,
  // _scrollToParagraphId = scrollToParagraphId
  {
    // Initialize specialized controllers
    _pagingController = ChapterPagingController(
      regulationId: regulationId,
      initialChapterOrderNum: initialChapterOrderNum,
      scrollToParagraphId: scrollToParagraphId,
    );

    _formattingController = TextFormattingController();

    _ttsController = TtsController(ttsRepository: ttsRepository);

    _searchController = ChapterSearchController(
      repository: StaticRegulationRepository(),
    );
  }

  @override
  void initListeners() {
    // Initialize listeners for all specialized controllers
    _pagingController.initListeners();
    _formattingController.initListeners();
    _ttsController.initListeners();
    _searchController.initListeners();
  }

  // Delegate getters to specialized controllers
  // Paging Controller Delegates
  Map<int, Map<String, dynamic>> get chaptersData =>
      _pagingController.chaptersData;
  int get currentChapterOrderNum => _pagingController.currentChapterOrderNum;
  int get totalChapters => _pagingController.totalChapters;
  bool get isLoading => _pagingController.isLoading;
  String? get error => _pagingController.error;
  String? get loadingError => _pagingController.loadingError;
  bool get canGoPreviousChapter => _pagingController.canGoPreviousChapter;
  bool get canGoNextChapter => _pagingController.canGoNextChapter;
  PageController get pageController => _pagingController.pageController;
  TextEditingController get pageTextController =>
      _pagingController.pageTextController;

  // Text Formatting Controller Delegates
  bool get isBottomBarExpanded => _formattingController.isBottomBarExpanded;
  bool get isBottomBarWhiteMode => _formattingController.isBottomBarWhiteMode;
  Paragraph? get selectedParagraph => _formattingController.selectedParagraph;
  int get selectionStart => _formattingController.selectionStart;
  int get selectionEnd => _formattingController.selectionEnd;
  String get lastSelectedText => _formattingController.lastSelectedText;
  List<int> get colorsList => _formattingController.colorsList;
  int get activeColorIndex => _formattingController.activeColorIndex;
  int get activeColor => _formattingController.activeColor;
  bool get hasSelection => _formattingController.hasSelection;
  bool get canApplyFormatting => _formattingController.canApplyFormatting;

  // TTS Controller Delegates
  bool get isTTSPlaying => _ttsController.isTTSPlaying;
  bool get isTTSPaused => _ttsController.isTTSPaused;
  bool get isTTSActive => _ttsController.isTTSActive;
  TtsState get ttsState => _ttsController.ttsState;
  Paragraph? get currentTTSParagraph => _ttsController.currentTTSParagraph;
  bool get isPlayingChapter => _ttsController.isPlayingChapter;

  // Search Controller Delegates
  bool get isSearching => _searchController.isSearching;
  List<SearchResult> get searchResults => _searchController.searchResults;
  String get searchQuery => _searchController.searchQuery;
  bool get hasSearchResults => _searchController.hasSearchResults;
  bool get hasSearchQuery => _searchController.hasSearchQuery;
  int get searchResultsCount => _searchController.searchResultsCount;

  // Combined error getter
  String? get combinedError {
    return _pagingController.error ??
        _pagingController.loadingError ??
        _formattingController.error ??
        _ttsController.error ??
        _searchController.error;
  }

  // Paging Controller Methods
  ScrollController getScrollControllerForChapter(int chapterOrderNum) {
    return _pagingController.getScrollControllerForChapter(chapterOrderNum);
  }

  ScrollController get currentChapterScrollController {
    return _pagingController.currentChapterScrollController;
  }

  ItemScrollController getItemScrollControllerForChapter(int chapterOrderNum) {
    return _pagingController.getItemScrollControllerForChapter(chapterOrderNum);
  }

  ItemScrollController get currentChapterItemScrollController {
    return _pagingController.currentChapterItemScrollController;
  }

  GlobalKey getParagraphKey(int chapterOrderNum, int paragraphIndex) {
    return _pagingController.getParagraphKey(chapterOrderNum, paragraphIndex);
  }

  void clearParagraphKeys(int chapterOrderNum) {
    _pagingController.clearParagraphKeys(chapterOrderNum);
  }

  Map<String, dynamic>? getChapterData(int chapterOrderNum) {
    return _pagingController.getChapterData(chapterOrderNum);
  }

  void onPageChanged(int newChapterOrderNum) {
    _pagingController.onPageChanged(newChapterOrderNum);
  }

  void goToChapter(int chapterOrderNum) {
    _pagingController.goToChapter(chapterOrderNum);
  }

  void goToPreviousChapter() {
    _pagingController.goToPreviousChapter();
  }

  void goToNextChapter() {
    _pagingController.goToNextChapter();
  }

  void goToParagraph(int paragraphId) {
    _pagingController.goToParagraph(paragraphId);
  }

  // Text Formatting Controller Methods
  void toggleBottomBar() {
    _formattingController.toggleBottomBar();
  }

  void setBottomBarExpanded(bool expanded) {
    _formattingController.setBottomBarExpanded(expanded);
  }

  void toggleBottomBarWhiteMode() {
    _formattingController.toggleBottomBarWhiteMode();
  }

  void setBottomBarWhiteMode(bool whiteMode) {
    _formattingController.setBottomBarWhiteMode(whiteMode);
  }

  void setSelectedParagraph(Paragraph? paragraph) {
    _formattingController.setSelectedParagraph(paragraph);
  }

  void setSelectionRange(int start, int end) {
    _formattingController.setSelectionRange(start, end);
  }

  void setLastSelectedText(String text) {
    _formattingController.setLastSelectedText(text);
  }

  void clearSelection() {
    _formattingController.clearSelection();
  }

  void setActiveColorIndex(int index) {
    _formattingController.setActiveColorIndex(index);
  }

  void nextColor() {
    _formattingController.nextColor();
  }

  void previousColor() {
    _formattingController.previousColor();
  }

  Future<void> applyHighlight() async {
    await _formattingController.applyHighlight();
  }

  Future<void> applyUnderline() async {
    await _formattingController.applyUnderline();
  }

  Future<void> applyBold() async {
    await _formattingController.applyBold();
  }

  Future<void> applyItalic() async {
    await _formattingController.applyItalic();
  }

  Future<void> removeFormatting() async {
    await _formattingController.removeFormatting();
  }

  Future<void> saveEditedParagraph(
      Paragraph paragraph, String editedContent) async {
    await _formattingController.saveEditedParagraph(paragraph, editedContent);
  }

  // TTS Controller Methods
  Future<void> playText(String text) async {
    await _ttsController.playText(text);
  }

  Future<void> playParagraph(Paragraph paragraph) async {
    await _ttsController.playParagraph(paragraph);
  }

  Future<void> playChapter(List<Paragraph> paragraphs,
      {int startIndex = 0}) async {
    await _ttsController.playChapter(paragraphs, startIndex: startIndex);
  }

  Future<void> stopTTS() async {
    await _ttsController.stopTTS();
  }

  Future<void> pauseTTS() async {
    await _ttsController.pauseTTS();
  }

  Future<void> resumeTTS() async {
    await _ttsController.resumeTTS();
  }

  void setCurrentTTSParagraph(Paragraph? paragraph) {
    _ttsController.setCurrentTTSParagraph(paragraph);
  }

  // Search Controller Methods
  void search(String query) {
    _searchController.search(query, _regulationId);
  }

  void clearSearch() {
    _searchController.clearSearch();
  }

  void goToSearchResult(SearchResult result) {
    _searchController.goToSearchResult(result);
    // Navigate to the paragraph using paging controller
    goToParagraph(result.paragraphId);
  }

  void setSearchQuery(String query) {
    _searchController.setSearchQuery(query);
  }

  void setSearchResults(List<SearchResult> results) {
    _searchController.setSearchResults(results);
  }

  void setSearching(bool searching) {
    _searchController.setSearching(searching);
  }

  // Utility methods
  void clearAllErrors() {
    _formattingController.clearError();
    _ttsController.clearError();
    _searchController.clearError();
  }

  @override
  void onDisposed() {
    // Dispose all specialized controllers
    _pagingController.onDisposed();
    _formattingController.onDisposed();
    _ttsController.onDisposed();
    _searchController.onDisposed();
    super.onDisposed();
  }
}
