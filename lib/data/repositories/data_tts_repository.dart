import "package:flutter_tts/flutter_tts.dart";
import "../../domain/repositories/tts_repository.dart";

class DataTTSRepository implements TTSRepository {
  final FlutterTts _flutterTts;
  bool _isPlaying = false;

  DataTTSRepository(this._flutterTts) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }

  @override
  Future<void> speak(String text) async {
    if (_isPlaying) {
      await stop();
    }
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  @override
  Future<void> pause() async {
    if (_isPlaying) {
      await _flutterTts.pause();
      _isPlaying = false;
    }
  }

  @override
  Future<void> resume() async {
    if (!_isPlaying) {
      await _flutterTts.speak("");
      _isPlaying = true;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setRate(double rate) async {
    await setSpeechRate(rate);
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
  Future<List<String>> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }

  @override
  Future<List<String>> getVoices() async {
    final voices = await _flutterTts.getVoices;
    return voices.map((voice) => voice.toString()).toList();
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    final languages = await getLanguages();
    return languages.contains(language);
  }

  @override
  Future<void> setVoice(String voiceId) async {
    await _flutterTts.setVoice({'name': voiceId});
  }

  @override
  Future<bool> get isPlaying async => _isPlaying;

  @override
  Future<void> dispose() async {
    await stop();
  }
}
