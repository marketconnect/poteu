import 'dart:async';
import "package:flutter_tts/flutter_tts.dart";
import "../../domain/repositories/tts_repository.dart";
import '../../domain/entities/tts_state.dart';

class DataTTSRepository implements TTSRepository {
  final FlutterTts _flutterTts;
  final _stateController = StreamController<TtsState>.broadcast();

  DataTTSRepository([FlutterTts? tts]) : _flutterTts = tts ?? FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _stateController.add(TtsState.playing);
    });

    _flutterTts.setCompletionHandler(() {
      _stateController.add(TtsState.stopped);
    });

    _flutterTts.setErrorHandler((msg) {
      _stateController.add(TtsState.error);
    });

    _flutterTts.setCancelHandler(() {
      _stateController.add(TtsState.stopped);
    });
  }

  @override
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    final available = await _flutterTts.isLanguageAvailable(language);
    return available ?? false;
  }

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  Future<void> dispose() async {
    await _flutterTts.stop();
    await _stateController.close();
  }
}
