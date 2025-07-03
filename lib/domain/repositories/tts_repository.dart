import '../entities/tts_state.dart';

abstract class TTSRepository {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String language);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> setRate(double rate);
  Future<List<String>> getLanguages();
  Future<bool> isLanguageAvailable(String language);
  Future<List<dynamic>> getVoices();
  Future<void> setVoice(String voice);
  Stream<TtsState> get stateStream;
  Future<void> dispose();
}
