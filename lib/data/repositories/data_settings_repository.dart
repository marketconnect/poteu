import "package:shared_preferences/shared_preferences.dart";
import "../../domain/entities/settings.dart";
import "../../domain/repositories/settings_repository.dart";

class DataSettingsRepository implements SettingsRepository {
  static const String _darkModeKey = "isDarkMode";
  static const String _fontSizeKey = "fontSize";
  static const String _soundEnabledKey = "isSoundEnabled";
  static const String _colorsKey = "highlightColors";
  static const String _languageKey = "language";
  static const String _speechRateKey = "speechRate";
  static const String _pitchKey = "pitch";
  static const String _voiceIdKey = "voiceId";
  static const String _volumeKey = "volume";

  final SharedPreferences _prefs;

  DataSettingsRepository(this._prefs);

  @override
  Future<Settings> getSettings() async {
    return Settings(
      isDarkMode: _prefs.getBool(_darkModeKey) ?? false,
      fontSize: _prefs.getDouble(_fontSizeKey) ?? 16.0,
      speechRate: _prefs.getDouble(_speechRateKey) ?? 1.0,
      volume: _prefs.getDouble(_volumeKey) ?? 1.0,
      voiceId: _prefs.getString(_voiceIdKey) ?? '',
      isSoundEnabled: _prefs.getBool(_soundEnabledKey) ?? true,
      highlightColors:
          _prefs.getStringList(_colorsKey)?.map((e) => int.parse(e)).toList() ??
              [0xFF1976D2],
      language: _prefs.getString(_languageKey) ?? 'ru-RU',
      pitch: _prefs.getDouble(_pitchKey) ?? 1.0,
    );
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    await _prefs.setBool(_darkModeKey, settings.isDarkMode);
    await _prefs.setDouble(_fontSizeKey, settings.fontSize);
    await _prefs.setBool(_soundEnabledKey, settings.isSoundEnabled);
    await _prefs.setStringList(
        _colorsKey, settings.highlightColors.map((e) => e.toString()).toList());
    await _prefs.setString(_languageKey, settings.language);
    await _prefs.setDouble(_speechRateKey, settings.speechRate);
    await _prefs.setDouble(_pitchKey, settings.pitch);
    await _prefs.setString(_voiceIdKey, settings.voiceId);
    await _prefs.setDouble(_volumeKey, settings.volume);
  }

  @override
  Future<void> setTheme(bool isDarkMode) async {
    await _prefs.setBool(_darkModeKey, isDarkMode);
  }

  @override
  Future<void> setFontSize(double fontSize) async {
    await _prefs.setDouble(_fontSizeKey, fontSize);
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  @override
  Future<void> setHighlightColors(List<int> colors) async {
    await _prefs.setStringList(
        _colorsKey, colors.map((e) => e.toString()).toList());
  }

  @override
  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  @override
  Future<void> setColors(Map<String, String> colors) async {
    await _prefs.setStringList(
        _colorsKey, colors.values.map((e) => e).toList());
  }

  @override
  Future<void> setDarkTheme(bool isDark) async {
    await _prefs.setBool(_darkModeKey, isDark);
  }

  @override
  Future<void> setSpeechRate(double speechRate) async {
    await _prefs.setDouble(_speechRateKey, speechRate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _prefs.setDouble(_pitchKey, pitch);
  }

  @override
  Future<void> setVoiceId(String voiceId) async {
    await _prefs.setString(_voiceIdKey, voiceId);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _prefs.setDouble(_volumeKey, volume);
  }
}
