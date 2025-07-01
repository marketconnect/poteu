import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import 'regulation_presenter.dart';

class RegulationController extends Controller {
  final RegulationPresenter _presenter;

  bool isLoading = true;
  String? chapterTitle;
  String? chapterContent;
  bool isPlaying = false;

  RegulationController({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required int regulationId,
    required int chapterId,
  }) : _presenter = RegulationPresenter(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          regulationId: regulationId,
          chapterId: chapterId,
        ) {
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    try {
      final chapter = await _presenter.getChapter();
      chapterTitle = chapter['title'] as String? ?? '';
      chapterContent = chapter['content'] as String? ?? '';
      isLoading = false;
      refreshUI();
    } catch (e) {
      isLoading = false;
      refreshUI();
    }
  }

  void startReading() async {
    if (chapterContent != null) {
      await _presenter.startReading(chapterContent!);
      isPlaying = true;
      refreshUI();
    }
  }

  void pauseReading() async {
    await _presenter.pauseReading();
    isPlaying = false;
    refreshUI();
  }

  void resumeReading() async {
    await _presenter.resumeReading();
    isPlaying = true;
    refreshUI();
  }

  void stopReading() async {
    await _presenter.stopReading();
    isPlaying = false;
    refreshUI();
  }

  @override
  void initListeners() {
    _presenter.onChapterLoaded = (chapter) {
      chapterTitle = chapter['title'] as String? ?? '';
      chapterContent = chapter['content'] as String? ?? '';
      isLoading = false;
      refreshUI();
    };

    _presenter.onError = (error) {
      isLoading = false;
      refreshUI();
    };
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
