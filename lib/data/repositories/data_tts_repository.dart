import 'dart:async';
import "package:flutter_tts/flutter_tts.dart";
import "../../domain/repositories/tts_repository.dart";
import '../../domain/entities/tts_state.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/settings.dart';

class DataTTSRepository implements TTSRepository {
  final FlutterTts _flutterTts;
  final SettingsRepository _settingsRepository;
  final _stateController = StreamController<TtsState>.broadcast();

  DataTTSRepository(this._settingsRepository, [FlutterTts? tts])
      : _flutterTts = tts ?? FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Get settings
    final settings = await _settingsRepository.getSettings();

    // Initialize TTS with settings values
    await _flutterTts.setLanguage(settings.language);
    await _flutterTts.setSpeechRate(settings.speechRate);
    await _flutterTts.setVolume(settings.volume);
    await _flutterTts.setPitch(settings.pitch);
    if (settings.voiceId.isNotEmpty) {
      await setVoice(settings.voiceId);
    }

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
    // Save to settings
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository
        .saveSettings(settings.copyWith(language: language));
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
    // Save to settings
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(volume: volume));
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
    // Save to settings
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(pitch: pitch));
  }

  @override
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
    // Save to settings
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(speechRate: rate));
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
  Future<List<dynamic>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      // Filter only Russian voices
      return voices.where((voice) {
        // Check if voice is a Map and has a 'locale' or 'language' field containing 'ru'
        if (voice is Map) {
          final locale = voice['locale']?.toString().toLowerCase() ?? '';
          final language = voice['language']?.toString().toLowerCase() ?? '';
          final name = voice['name']?.toString().toLowerCase() ?? '';

          return locale.contains('ru') ||
              language.contains('ru') ||
              name.contains('russian') ||
              name.contains('русск');
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  @override
  Future<void> setVoice(String voice) async {
    try {
      await _flutterTts.setVoice({"name": voice});
      // Save to settings
      final settings = await _settingsRepository.getSettings();
      await _settingsRepository.saveSettings(settings.copyWith(voiceId: voice));
    } catch (e) {
      print('Error setting voice: $e');
    }
  }

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> dispose() async {
    await _flutterTts.stop();
    await _stateController.close();
  }
}
