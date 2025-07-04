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

  // Флаг для включения/отключения логирования TTS (для отладки)
  static const bool _enableTtsLogging = true;

  void _log(String message) {
    if (_enableTtsLogging) {
      print('[TTS] $message');
    }
  }

  DataTTSRepository(this._settingsRepository, [FlutterTts? tts])
      : _flutterTts = tts ?? FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _log('Initializing TTS...');
      final settings = await _settingsRepository.getSettings();
      _log(
          'Current settings: volume=${settings.volume}, pitch=${settings.pitch}, rate=${settings.speechRate}, language=${settings.language}, voiceId=${settings.voiceId}');

      await _flutterTts.setLanguage(settings.language);
      await _flutterTts.setSpeechRate(settings.speechRate);
      await _flutterTts.setVolume(settings.volume);
      await _flutterTts.setPitch(settings.pitch);

      if (settings.voiceId.isEmpty) {
        _log('No voice ID set, getting available voices...');
        final voices = await getVoices();
        _log('Available voices: ${voices.length}');
        if (voices.isNotEmpty) {
          final defaultVoice = voices.first;
          _log('Setting default voice: ${defaultVoice['name']}');
          await setVoice(defaultVoice['name']);
        }
      } else {
        _log('Setting saved voice: ${settings.voiceId}');
        await setVoice(settings.voiceId);
      }

      _flutterTts.setStartHandler(() {
        _log('Speech started');
        _stateController.add(TtsState.playing);
      });

      _flutterTts.setCompletionHandler(() {
        _log('Speech completed');
        _stateController.add(TtsState.stopped);
      });

      _flutterTts.setErrorHandler((msg) {
        _log('Speech error: $msg');
        _stateController.add(TtsState.error);
      });

      _flutterTts.setCancelHandler(() {
        _log('Speech cancelled');
        _stateController.add(TtsState.stopped);
      });

      _log('TTS initialization completed');
    } catch (e) {
      _log('Error during initialization: $e');
      _stateController.add(TtsState.error);
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      _log('=================== SPEAK CALLED ===================');
      _log(
          'Text to speak: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');

      // КРИТИЧНО: Применяем все настройки перед каждым speak(), как в оригинальном приложении
      _log('Applying current settings before speaking...');
      final settings = await _settingsRepository.getSettings();
      _log(
          'Repository settings: voice=${settings.voiceId}, language=${settings.language}, volume=${settings.volume}, pitch=${settings.pitch}, rate=${settings.speechRate}');

      // Применяем все настройки заново
      await _flutterTts.setLanguage(settings.language);
      await _flutterTts.setSpeechRate(settings.speechRate);
      await _flutterTts.setVolume(settings.volume);
      await _flutterTts.setPitch(settings.pitch);

      // Если есть сохраненный голос, применяем его
      if (settings.voiceId.isNotEmpty) {
        _log('Re-applying saved voice: ${settings.voiceId}');
        await _applyVoiceSettings(settings.voiceId);
      }

      // Get current TTS settings to log them
      final currentVoices = await _flutterTts.getVoices;
      final currentLanguages = await _flutterTts.getLanguages;

      _log('Current engine voices count: ${currentVoices?.length ?? 0}');
      _log('Current engine languages count: ${currentLanguages?.length ?? 0}');

      // Get current voice from FlutterTts if possible
      try {
        final currentVoice = await _flutterTts.getDefaultVoice;
        _log('Current FlutterTts voice: $currentVoice');
      } catch (e) {
        _log('Could not get current voice: $e');
      }

      await _flutterTts.speak(text);
      _log('speak() call completed');
    } catch (e) {
      _log('Error in speak(): $e');
      _stateController.add(TtsState.error);
    }
  }

  /// Внутренний метод для применения настроек голоса без сохранения в settings
  Future<void> _applyVoiceSettings(String voice) async {
    try {
      final voices = await getVoices();
      final selectedVoice = voices.firstWhere(
        (v) => v['name'] == voice,
        orElse: () => null,
      );

      if (selectedVoice != null) {
        final voiceMap = {
          "name": voice,
          "locale": selectedVoice['locale']?.toString() ?? '',
          "language": selectedVoice['language']?.toString() ?? '',
        };

        _log('Applying voice: $voiceMap');
        await _flutterTts.setVoice(voiceMap);

        if (selectedVoice['locale'] != null) {
          await _flutterTts.setLanguage(selectedVoice['locale']);
        }

        // Дополнительная проверка: убедимся что голос действительно установлен
        try {
          await Future.delayed(
              Duration(milliseconds: 100)); // Небольшая задержка
          final currentVoice = await _flutterTts.getDefaultVoice;
          final currentVoiceName = currentVoice?['name']?.toString() ?? '';

          _log('Verification: requested=$voice, current=$currentVoiceName');

          // Если голос не установился, попробуем еще раз
          if (currentVoiceName != voice) {
            _log('Voice not applied correctly, retrying...');
            await _flutterTts.setVoice(voiceMap);

            // Финальная проверка
            await Future.delayed(Duration(milliseconds: 100));
            final finalVoice = await _flutterTts.getDefaultVoice;
            final finalVoiceName = finalVoice?['name']?.toString() ?? '';
            _log('Final verification: requested=$voice, final=$finalVoiceName');
          }
        } catch (e) {
          _log('Could not verify voice application: $e');
        }
      } else {
        _log('Voice not found when applying: $voice');
      }
    } catch (e) {
      _log('Error applying voice settings: $e');
    }
  }

  @override
  Future<void> stop() async {
    _log('Stopping speech...');
    await _flutterTts.stop();
  }

  @override
  Future<void> setLanguage(String language) async {
    _log('Setting language to: $language');
    await _flutterTts.setLanguage(language);
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository
        .saveSettings(settings.copyWith(language: language));
    _log('Language set and saved');
  }

  @override
  Future<void> setVolume(double volume) async {
    _log('Setting volume to: $volume');
    await _flutterTts.setVolume(volume);
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(volume: volume));
    _log('Volume set and saved');
  }

  @override
  Future<void> setPitch(double pitch) async {
    _log('Setting pitch to: $pitch');
    await _flutterTts.setPitch(pitch);
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(pitch: pitch));
    _log('Pitch set and saved');
  }

  @override
  Future<void> setRate(double rate) async {
    _log('Setting rate to: $rate');
    await _flutterTts.setSpeechRate(rate);
    final settings = await _settingsRepository.getSettings();
    await _settingsRepository.saveSettings(settings.copyWith(speechRate: rate));
    _log('Rate set and saved');
  }

  @override
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    _log('Got ${languages?.length ?? 0} languages');
    return languages?.cast<String>() ?? [];
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    final available = await _flutterTts.isLanguageAvailable(language);
    _log('Language $language available: $available');
    return available ?? false;
  }

  @override
  Future<List<dynamic>> getVoices() async {
    try {
      _log('Getting voices...');
      final voices = await _flutterTts.getVoices;
      _log('Total voices available: ${voices?.length ?? 0}');

      final russianVoices = voices?.where((voice) {
            if (voice is Map) {
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              final language =
                  voice['language']?.toString().toLowerCase() ?? '';
              final name = voice['name']?.toString().toLowerCase() ?? '';

              return locale.contains('ru') ||
                  language.contains('ru') ||
                  name.contains('russian') ||
                  name.contains('русск');
            }
            return false;
          }).toList() ??
          [];

      _log('Russian voices found: ${russianVoices.length}');
      for (var voice in russianVoices) {
        _log('Russian voice: ${voice['name']} (${voice['locale']})');
      }

      return russianVoices;
    } catch (e) {
      _log('Error getting voices: $e');
      return [];
    }
  }

  @override
  Future<void> setVoice(String voice) async {
    try {
      _log('=================== SET VOICE CALLED =================');
      _log('Setting voice to: $voice');

      final voices = await getVoices();
      final selectedVoice = voices.firstWhere(
        (v) => v['name'] == voice,
        orElse: () => null,
      );

      if (selectedVoice != null) {
        _log(
            'Found voice: ${selectedVoice['name']} with locale: ${selectedVoice['locale']}');

        final voiceMap = {
          "name": voice,
          "locale": selectedVoice['locale']?.toString() ?? '',
          "language": selectedVoice['language']?.toString() ?? '',
        };

        _log('Setting voice with map: $voiceMap');
        await _flutterTts.setVoice(voiceMap);

        if (selectedVoice['locale'] != null) {
          _log('Setting language to: ${selectedVoice['locale']}');
          await _flutterTts.setLanguage(selectedVoice['locale']);
        }

        final settings = await _settingsRepository.getSettings();
        final newSettings = settings.copyWith(
          voiceId: voice,
          language: selectedVoice['locale'] ?? settings.language,
        );

        _log(
            'Saving settings: voice=${newSettings.voiceId}, language=${newSettings.language}');
        await _settingsRepository.saveSettings(newSettings);

        // Verify the voice was set
        try {
          final currentVoice = await _flutterTts.getDefaultVoice;
          _log('Current voice after setting: $currentVoice');
        } catch (e) {
          _log('Could not verify current voice: $e');
        }

        _log('Voice set successfully');
      } else {
        _log('Voice not found: $voice');
        _log('Available voices:');
        for (var v in voices) {
          _log('   - ${v['name']}');
        }
      }
    } catch (e) {
      _log('Error setting voice: $e');
      _stateController.add(TtsState.error);
    }
  }

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> dispose() async {
    _log('Disposing TTS repository...');
    await _flutterTts.stop();
    await _stateController.close();
  }
}
