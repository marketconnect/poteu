import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/usecases/sound_settings_usecase.dart';
import '../../../domain/entities/settings.dart';

class SoundSettingsPresenter extends Presenter {
  final SoundSettingsUseCase _soundSettingsUseCase;

  // Callbacks
  Function? onComplete;
  Function? onError;

  SoundSettingsPresenter(settingsRepository)
      : _soundSettingsUseCase = SoundSettingsUseCase(settingsRepository);

  void setVolume(double volume) {
    _soundSettingsUseCase.execute(
      _SoundSettingsUseCaseObserver(this),
      SoundSettingsUseCaseParams.setVolume(volume),
    );
  }

  void setPitch(double pitch) {
    _soundSettingsUseCase.execute(
      _SoundSettingsUseCaseObserver(this),
      SoundSettingsUseCaseParams.setPitch(pitch),
    );
  }

  void setRate(double rate) {
    _soundSettingsUseCase.execute(
      _SoundSettingsUseCaseObserver(this),
      SoundSettingsUseCaseParams.setRate(rate),
    );
  }

  void setLanguage(String language) {
    _soundSettingsUseCase.execute(
      _SoundSettingsUseCaseObserver(this),
      SoundSettingsUseCaseParams.setLanguage(language),
    );
  }

  void setVoice(String voice) {
    _soundSettingsUseCase.execute(
      _SoundSettingsUseCaseObserver(this),
      SoundSettingsUseCaseParams.setVoice(voice),
    );
  }

  Future<Settings> getSettings() => _soundSettingsUseCase.getSettings();

  @override
  void dispose() {
    _soundSettingsUseCase.dispose();
  }
}

class _SoundSettingsUseCaseObserver extends Observer<void> {
  final SoundSettingsPresenter _presenter;

  _SoundSettingsUseCaseObserver(this._presenter);

  @override
  void onComplete() {
    _presenter.onComplete?.call();
  }

  @override
  void onError(e) {
    _presenter.onError?.call(e);
  }

  @override
  void onNext(_) {}
}
