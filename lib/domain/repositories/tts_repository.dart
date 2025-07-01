abstract class TTSRepository {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setVoice(String voiceId);
  Future<List<String>> getLanguages();
  Future<List<String>> getVoices();
  Future<bool> isLanguageAvailable(String language);
  Future<bool> get isPlaying;
  Future<void> dispose();
}
