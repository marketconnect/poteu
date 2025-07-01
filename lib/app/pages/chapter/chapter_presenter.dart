import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/paragraph.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/usecases/get_chapter_usecase.dart';
import '../../../domain/usecases/get_chapter_content.dart';

class ChapterPresenter extends Presenter {
  late Function(Chapter?) onChapterLoaded;
  late Function(List<Paragraph>) onChapterContentLoaded;
  late Function(dynamic) onError;

  final GetChapterUseCase _getChapterUseCase;
  final GetChapterContentUseCase _getChapterContentUseCase;
  final int _regulationId;
  final int _chapterId;
  final int _chapterOrderNum;

  ChapterPresenter({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required int regulationId,
    required int chapterId,
    required int chapterOrderNum,
  })  : _getChapterUseCase = GetChapterUseCase(regulationRepository),
        _getChapterContentUseCase =
            GetChapterContentUseCase(regulationRepository),
        _regulationId = regulationId,
        _chapterId = chapterId,
        _chapterOrderNum = chapterOrderNum;

  void getChapter() {
    _getChapterUseCase.execute(
      _GetChapterUseCaseObserver(this),
      GetChapterUseCaseParams(_chapterId),
    );
  }

  void getChapterContent() {
    _getChapterContentUseCase.execute(
      _GetChapterContentUseCaseObserver(this),
      GetChapterContentParams(
        regulationId: _regulationId,
        chapterOrderNum: _chapterOrderNum,
      ),
    );
  }

  @override
  void dispose() {
    _getChapterUseCase.dispose();
    _getChapterContentUseCase.dispose();
  }
}

class _GetChapterUseCaseObserver extends Observer<Chapter?> {
  final ChapterPresenter presenter;

  _GetChapterUseCaseObserver(this.presenter);

  @override
  void onComplete() {}

  @override
  void onError(dynamic e) {
    presenter.onError(e);
  }

  @override
  void onNext(Chapter? response) {
    presenter.onChapterLoaded(response);
  }
}

class _GetChapterContentUseCaseObserver extends Observer<List<Paragraph>> {
  final ChapterPresenter presenter;

  _GetChapterContentUseCaseObserver(this.presenter);

  @override
  void onComplete() {}

  @override
  void onError(dynamic e) {
    presenter.onError(e);
  }

  @override
  void onNext(List<Paragraph>? response) {
    if (response != null) {
      presenter.onChapterContentLoaded(response);
    }
  }
}
