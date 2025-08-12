import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/notes_repository.dart';
import '../../../domain/usecases/get_regulations.dart';
import '../../../domain/entities/regulation.dart';

class MainPresenter extends Presenter {
  final RegulationRepository _regulationRepository;
  // final SettingsRepository _settingsRepository;
  // final TTSRepository _ttsRepository;
  // final NotesRepository _notesRepository;
  // final SubscriptionRepository _subscriptionRepository;

  Function(List<Regulation>)? onRegulationsLoaded;
  Function(dynamic)? onError;

  MainPresenter({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required NotesRepository notesRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _regulationRepository = regulationRepository;
  // _settingsRepository = settingsRepository,
  // _ttsRepository = ttsRepository,
  // _notesRepository = notesRepository;

  void getRegulations() {
    final useCase = GetRegulations(_regulationRepository);
    useCase.execute(_MainObserver(this), null);
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }
}

class _MainObserver extends Observer<List<Regulation>> {
  final MainPresenter _presenter;

  _MainObserver(this._presenter);

  @override
  void onComplete() {
    // Handle completion if needed
  }

  @override
  void onError(e) {
    _presenter.onError?.call(e);
  }

  @override
  void onNext(List<Regulation>? regulations) {
    if (regulations != null) {
      _presenter.onRegulationsLoaded?.call(regulations);
    }
  }
}
