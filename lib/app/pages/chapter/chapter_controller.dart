import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../data/repositories/static_regulation_repository.dart';

class ChapterController extends Controller {
  final int _regulationId;
  final int _initialChapterOrderNum;
  final StaticRegulationRepository _repository = StaticRegulationRepository();

  // PageView управление как в оригинале
  late PageController pageController;
  late TextEditingController pageTextController;

  Map<int, Map<String, dynamic>> _chaptersData = {};
  int _currentChapterOrderNum = 1;
  int _totalChapters = 0;
  bool _isLoading = false;
  String? _error;
  bool _isTTSPlaying = false;

  // Getters
  Map<int, Map<String, dynamic>> get chaptersData => _chaptersData;
  int get currentChapterOrderNum => _currentChapterOrderNum;
  int get totalChapters => _totalChapters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTTSPlaying => _isTTSPlaying;

  // Добавленные геттеры для навигации
  bool get canGoPreviousChapter => _currentChapterOrderNum > 1;
  bool get canGoNextChapter => _currentChapterOrderNum < _totalChapters;

  ChapterController({
    required int regulationId,
    required int initialChapterOrderNum,
  })  : _regulationId = regulationId,
        _initialChapterOrderNum = initialChapterOrderNum,
        _currentChapterOrderNum = initialChapterOrderNum {
    pageController = PageController(initialPage: initialChapterOrderNum - 1);
    pageTextController =
        TextEditingController(text: initialChapterOrderNum.toString());

    loadAllChapters();
  }

  Future<void> loadAllChapters() async {
    _isLoading = true;
    refreshUI();

    try {
      // Получаем все главы из репозитория
      final chapters = await _repository.getChapters(_regulationId);
      _totalChapters = chapters.length;

      // Загружаем данные для каждой главы
      for (final chapter in chapters) {
        _chaptersData[chapter.level] = {
          'id': chapter.id,
          'title': chapter.title,
          'content': chapter.content,
          'paragraphs': chapter.paragraphs,
        };
      }

      _isLoading = false;
      refreshUI();
    } catch (e) {
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

  // Поиск в текущей главе как в оригинале
  List<Paragraph> searchInCurrentChapter(String query) {
    if (query.isEmpty) return [];

    final currentChapterData = getChapterData(_currentChapterOrderNum);
    if (currentChapterData == null) return [];

    final paragraphs = currentChapterData['paragraphs'] as List<Paragraph>;
    return paragraphs
        .where((paragraph) =>
            paragraph.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // TTS методы обновленные
  Future<void> playTTS(Paragraph paragraph) async {
    try {
      final textToSpeak =
          paragraph.textToSpeech ?? _stripHtml(paragraph.content);
      print('TTS: Playing - $textToSpeak'); // Mock TTS
      _isTTSPlaying = true;
      refreshUI();

      // Simulate TTS duration
      await Future.delayed(const Duration(seconds: 3));
      _isTTSPlaying = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> toggleTTS() async {
    try {
      if (_isTTSPlaying) {
        print('TTS: Stopped'); // Mock TTS stop
        _isTTSPlaying = false;
      } else {
        final chapterData = getChapterData(_currentChapterOrderNum);
        if (chapterData != null) {
          final paragraphs = chapterData['paragraphs'] as List<Paragraph>;
          final textToSpeak = paragraphs
              .map((p) => p.textToSpeech ?? _stripHtml(p.content))
              .join(' ');
          print('TTS: Playing chapter - $textToSpeak'); // Mock TTS
          _isTTSPlaying = true;
        }
      }
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void speakParagraph(Paragraph paragraph) async {
    try {
      final textToSpeak =
          paragraph.textToSpeech ?? _stripHtml(paragraph.content);
      print('TTS: Speaking paragraph - $textToSpeak'); // Mock TTS
      _isTTSPlaying = true;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void stopTTS() async {
    try {
      print('TTS: Stopped'); // Mock TTS stop
      _isTTSPlaying = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void shareParagraph(Paragraph paragraph) {
    // Mock sharing functionality
    final textToShare = _stripHtml(paragraph.content);
    print('Sharing: $textToShare');
  }

  String _stripHtml(String htmlText) {
    // Simple HTML tag removal
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  void initListeners() {
    // Initialize listeners here
  }

  @override
  void onDisposed() {
    pageController.dispose();
    pageTextController.dispose();
    super.onDisposed();
  }
}
