import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/usecases/get_table_of_contents.dart';

class TableOfContentsPresenter extends Presenter {
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final int _regulationId;

  Function(List<Map<String, dynamic>>)? onChaptersLoaded;
  Function(dynamic)? onError;

  TableOfContentsPresenter({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required int regulationId,
  })  : _regulationRepository = regulationRepository,
        _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository,
        _regulationId = regulationId;

  void getChapters() {
    final useCase = GetTableOfContents(_regulationRepository);
    useCase.execute(_TableOfContentsObserver(this), null);
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }
}

class _TableOfContentsObserver extends Observer<List<Map<String, dynamic>>?> {
  final TableOfContentsPresenter _presenter;

  _TableOfContentsObserver(this._presenter);

  @override
  void onComplete() {
    // Handle completion if needed
  }

  @override
  void onError(e) {
    _presenter.onError?.call(e);
  }

  @override
  void onNext(List<Map<String, dynamic>>? chapters) {
    if (chapters != null) {
      _presenter.onChaptersLoaded?.call(chapters);
    }
  }
}
