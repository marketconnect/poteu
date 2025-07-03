import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<Settings> getSettings();
  Future<void> saveSettings(Settings settings);
  Future<void> setDarkTheme(bool isDark);
  Future<void> setTheme(bool isDarkMode);
  Future<void> setFontSize(double size);
  Future<void> setSoundEnabled(bool enabled);
  Future<void> setHighlightColors(List<int> colors);
  Future<void> setLanguage(String language);
  Future<void> setColors(Map<String, String> colors);
  Future<void> setSpeechRate(double speechRate);
  Future<void> setPitch(double pitch);
  Future<void> setVoiceId(String voiceId);
}
