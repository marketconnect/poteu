import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/settings_repository.dart';
import '../entities/settings.dart';
import 'dart:async';

class SoundSettingsUseCase extends UseCase<void, SoundSettingsUseCaseParams> {
  final SettingsRepository _settingsRepository;

  SoundSettingsUseCase(this._settingsRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(
      SoundSettingsUseCaseParams? params) async {
    final controller = StreamController<void>();

    try {
      if (params == null) {
        controller.addError(ArgumentError('Parameters can not be null'));
        return controller.stream;
      }

      switch (params.action) {
        case SoundSettingsAction.setVolume:
          await _settingsRepository.setVolume(params.volume!);
          break;
        case SoundSettingsAction.setPitch:
          await _settingsRepository.setPitch(params.pitch!);
          break;
        case SoundSettingsAction.setRate:
          await _settingsRepository.setSpeechRate(params.rate!);
          break;
        case SoundSettingsAction.setLanguage:
          await _settingsRepository.setLanguage(params.language!);
          break;
        case SoundSettingsAction.setVoice:
          await _settingsRepository.setVoiceId(params.voice!);
          break;
      }

      controller.close();
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  Future<Settings> getSettings() => _settingsRepository.getSettings();
}

enum SoundSettingsAction {
  setVolume,
  setPitch,
  setRate,
  setLanguage,
  setVoice,
}

class SoundSettingsUseCaseParams {
  final SoundSettingsAction action;
  final double? volume;
  final double? pitch;
  final double? rate;
  final String? language;
  final String? voice;

  SoundSettingsUseCaseParams.setVolume(double volume)
      : action = SoundSettingsAction.setVolume,
        volume = volume,
        pitch = null,
        rate = null,
        language = null,
        voice = null;

  SoundSettingsUseCaseParams.setPitch(double pitch)
      : action = SoundSettingsAction.setPitch,
        volume = null,
        pitch = pitch,
        rate = null,
        language = null,
        voice = null;

  SoundSettingsUseCaseParams.setRate(double rate)
      : action = SoundSettingsAction.setRate,
        volume = null,
        pitch = null,
        rate = rate,
        language = null,
        voice = null;

  SoundSettingsUseCaseParams.setLanguage(String language)
      : action = SoundSettingsAction.setLanguage,
        volume = null,
        pitch = null,
        rate = null,
        language = language,
        voice = null;

  SoundSettingsUseCaseParams.setVoice(String voice)
      : action = SoundSettingsAction.setVoice,
        volume = null,
        pitch = null,
        rate = null,
        language = null,
        voice = voice;
}
