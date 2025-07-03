import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/usecases/font_settings_usecase.dart';
import '../../../domain/entities/settings.dart';

class FontSettingsPresenter extends Presenter {
  Function? setFontSizeOnComplete;
  Function? setFontSizeOnError;
  Function? setFontFamilyOnComplete;
  Function? setFontFamilyOnError;
  Function? getSettingsOnNext;
  Function? getSettingsOnComplete;
  Function? getSettingsOnError;

  final SetFontSizeUseCase _setFontSizeUseCase;
  final SetFontFamilyUseCase _setFontFamilyUseCase;
  final GetSettingsUseCase _getSettingsUseCase;

  FontSettingsPresenter(settingsRepository)
      : _setFontSizeUseCase = SetFontSizeUseCase(settingsRepository),
        _setFontFamilyUseCase = SetFontFamilyUseCase(settingsRepository),
        _getSettingsUseCase = GetSettingsUseCase(settingsRepository);

  void setFontSize(double fontSize) {
    print('FontSettingsPresenter.setFontSize called with: $fontSize');
    _setFontSizeUseCase.execute(
      _SetFontSizeUseCaseObserver(this),
      SetFontSizeUseCaseParams(fontSize),
    );
  }

  void setFontFamily(String fontFamily) {
    print('FontSettingsPresenter.setFontFamily called with: $fontFamily');
    _setFontFamilyUseCase.execute(
      _SetFontFamilyUseCaseObserver(this),
      SetFontFamilyUseCaseParams(fontFamily),
    );
  }

  void getSettings() {
    print('FontSettingsPresenter.getSettings called');
    _getSettingsUseCase.execute(_GetSettingsUseCaseObserver(this), null);
  }

  @override
  void dispose() {
    _setFontSizeUseCase.dispose();
    _setFontFamilyUseCase.dispose();
    _getSettingsUseCase.dispose();
  }
}

class _SetFontSizeUseCaseObserver extends Observer<void> {
  final FontSettingsPresenter presenter;

  _SetFontSizeUseCaseObserver(this.presenter);

  @override
  void onComplete() {
    print('_SetFontSizeUseCaseObserver.onComplete called');
    assert(presenter.setFontSizeOnComplete != null);
    presenter.setFontSizeOnComplete!();
  }

  @override
  void onError(e) {
    print('_SetFontSizeUseCaseObserver.onError called with: $e');
    assert(presenter.setFontSizeOnError != null);
    presenter.setFontSizeOnError!(e);
  }

  @override
  void onNext(void response) {
    print('_SetFontSizeUseCaseObserver.onNext called');
  }
}

class _SetFontFamilyUseCaseObserver extends Observer<void> {
  final FontSettingsPresenter presenter;

  _SetFontFamilyUseCaseObserver(this.presenter);

  @override
  void onComplete() {
    print('_SetFontFamilyUseCaseObserver.onComplete called');
    assert(presenter.setFontFamilyOnComplete != null);
    presenter.setFontFamilyOnComplete!();
  }

  @override
  void onError(e) {
    print('_SetFontFamilyUseCaseObserver.onError called with: $e');
    assert(presenter.setFontFamilyOnError != null);
    presenter.setFontFamilyOnError!(e);
  }

  @override
  void onNext(void response) {
    print('_SetFontFamilyUseCaseObserver.onNext called');
  }
}

class _GetSettingsUseCaseObserver extends Observer<Settings> {
  final FontSettingsPresenter presenter;

  _GetSettingsUseCaseObserver(this.presenter);

  @override
  void onComplete() {
    print('_GetSettingsUseCaseObserver.onComplete called');
    assert(presenter.getSettingsOnComplete != null);
    presenter.getSettingsOnComplete!();
  }

  @override
  void onError(e) {
    print('_GetSettingsUseCaseObserver.onError called with: $e');
    assert(presenter.getSettingsOnError != null);
    presenter.getSettingsOnError!(e);
  }

  @override
  void onNext(Settings? response) {
    print('_GetSettingsUseCaseObserver.onNext called with: $response');
    assert(presenter.getSettingsOnNext != null);
    presenter.getSettingsOnNext!(response);
  }
}
