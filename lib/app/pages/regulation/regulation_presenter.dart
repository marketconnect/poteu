import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';

class RegulationPresenter extends Presenter {
  final RegulationRepository _regulationRepository;
  final TTSRepository _ttsRepository;
  final int _chapterId;

  void Function(Map<String, dynamic>)? onChapterLoaded;
  void Function(dynamic)? onError;

  RegulationPresenter({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required int regulationId,
    required int chapterId,
  })  : _regulationRepository = regulationRepository,
        _ttsRepository = ttsRepository,
        _chapterId = chapterId {
    _loadChapter();
  }

  Future<Map<String, dynamic>> getChapter() async {
    return await _regulationRepository.getChapter(_chapterId);
  }

  Future<void> startReading(String text) async {
    await _ttsRepository.speak(text);
  }

  Future<void> pauseReading() async {
    await _ttsRepository.pause();
  }

  Future<void> resumeReading() async {
    await _ttsRepository.resume();
  }

  Future<void> stopReading() async {
    await _ttsRepository.stop();
  }

  Future<void> _loadChapter() async {
    try {
      final chapter = await _regulationRepository.getChapter(_chapterId);
      onChapterLoaded?.call(chapter);
    } catch (e) {
      onError?.call(e);
    }
  }

  @override
  void dispose() {
    _ttsRepository.dispose();
  }
}
