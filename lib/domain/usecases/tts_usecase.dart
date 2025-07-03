import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/tts_repository.dart';
import '../entities/tts_state.dart';

class TTSUseCase extends UseCase<void, TTSUseCaseParams> {
  final TTSRepository _ttsRepository;

  TTSUseCase(this._ttsRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(TTSUseCaseParams? params) async {
    final controller = StreamController<void>();

    try {
      if (params == null) {
        controller.addError(ArgumentError('Parameters can not be null'));
        return controller.stream;
      }

      switch (params.action) {
        case TTSAction.speak:
          if (params.text == null) {
            controller.addError(
                ArgumentError('Text can not be null for speak action'));
            return controller.stream;
          }
          await _ttsRepository.speak(params.text!);
          break;
        case TTSAction.stop:
          await _ttsRepository.stop();
          break;
        case TTSAction.setLanguage:
          if (params.language == null) {
            controller.addError(ArgumentError(
                'Language can not be null for setLanguage action'));
            return controller.stream;
          }
          await _ttsRepository.setLanguage(params.language!);
          break;
        case TTSAction.setVolume:
          if (params.volume == null) {
            controller.addError(
                ArgumentError('Volume can not be null for setVolume action'));
            return controller.stream;
          }
          await _ttsRepository.setVolume(params.volume!);
          break;
        case TTSAction.setPitch:
          if (params.pitch == null) {
            controller.addError(
                ArgumentError('Pitch can not be null for setPitch action'));
            return controller.stream;
          }
          await _ttsRepository.setPitch(params.pitch!);
          break;
        case TTSAction.setRate:
          if (params.rate == null) {
            controller.addError(
                ArgumentError('Rate can not be null for setRate action'));
            return controller.stream;
          }
          await _ttsRepository.setRate(params.rate!);
          break;
      }

      controller.close();
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  Stream<TtsState> get stateStream => _ttsRepository.stateStream;
}

enum TTSAction {
  speak,
  stop,
  setLanguage,
  setVolume,
  setPitch,
  setRate,
}

class TTSUseCaseParams {
  final TTSAction action;
  final String? text;
  final String? language;
  final double? volume;
  final double? pitch;
  final double? rate;

  TTSUseCaseParams.speak(String text)
      : action = TTSAction.speak,
        text = text,
        language = null,
        volume = null,
        pitch = null,
        rate = null;

  TTSUseCaseParams.stop()
      : action = TTSAction.stop,
        text = null,
        language = null,
        volume = null,
        pitch = null,
        rate = null;

  TTSUseCaseParams.setLanguage(String language)
      : action = TTSAction.setLanguage,
        text = null,
        language = language,
        volume = null,
        pitch = null,
        rate = null;

  TTSUseCaseParams.setVolume(double volume)
      : action = TTSAction.setVolume,
        text = null,
        language = null,
        volume = volume,
        pitch = null,
        rate = null;

  TTSUseCaseParams.setPitch(double pitch)
      : action = TTSAction.setPitch,
        text = null,
        language = null,
        volume = null,
        pitch = pitch,
        rate = null;

  TTSUseCaseParams.setRate(double rate)
      : action = TTSAction.setRate,
        text = null,
        language = null,
        volume = null,
        pitch = null,
        rate = rate;
}
