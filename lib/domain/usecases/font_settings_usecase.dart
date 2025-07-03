import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class SetFontSizeUseCase extends UseCase<void, SetFontSizeUseCaseParams> {
  final SettingsRepository _settingsRepository;

  SetFontSizeUseCase(this._settingsRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(
      SetFontSizeUseCaseParams? params) async {
    print(
        'SetFontSizeUseCase.buildUseCaseStream called with fontSize: ${params?.fontSize}');
    final StreamController<void> controller = StreamController();
    try {
      await _settingsRepository.setFontSize(params!.fontSize);
      print('SetFontSizeUseCase: fontSize set successfully');
      controller.close();
    } catch (e) {
      print('SetFontSizeUseCase error: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SetFontFamilyUseCase extends UseCase<void, SetFontFamilyUseCaseParams> {
  final SettingsRepository _settingsRepository;

  SetFontFamilyUseCase(this._settingsRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(
      SetFontFamilyUseCaseParams? params) async {
    print(
        'SetFontFamilyUseCase.buildUseCaseStream called with fontFamily: ${params?.fontFamily}');
    final StreamController<void> controller = StreamController();
    try {
      await _settingsRepository.setFontFamily(params!.fontFamily);
      print('SetFontFamilyUseCase: fontFamily set successfully');
      controller.close();
    } catch (e) {
      print('SetFontFamilyUseCase error: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}

class GetSettingsUseCase extends UseCase<Settings, void> {
  final SettingsRepository _settingsRepository;

  GetSettingsUseCase(this._settingsRepository);

  @override
  Future<Stream<Settings>> buildUseCaseStream(void params) async {
    print('GetSettingsUseCase.buildUseCaseStream called');
    final StreamController<Settings> controller = StreamController();
    try {
      final settings = await _settingsRepository.getSettings();
      print('GetSettingsUseCase: settings loaded successfully');
      controller.add(settings);
      controller.close();
    } catch (e) {
      print('GetSettingsUseCase error: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SetFontSizeUseCaseParams {
  final double fontSize;
  SetFontSizeUseCaseParams(this.fontSize);
}

class SetFontFamilyUseCaseParams {
  final String fontFamily;
  SetFontFamilyUseCaseParams(this.fontFamily);
}
