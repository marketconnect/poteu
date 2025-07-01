class Settings {
  final bool isDarkMode;
  final double fontSize;
  final double speechRate;
  final double volume;
  final String voiceId;
  final bool isSoundEnabled;
  final String fontFamily;
  final List<int> highlightColors;
  final String language;
  final double pitch;

  const Settings({
    required this.isDarkMode,
    required this.fontSize,
    required this.speechRate,
    required this.volume,
    required this.voiceId,
    required this.isSoundEnabled,
    required this.fontFamily,
    required this.highlightColors,
    required this.language,
    required this.pitch,
  });

  Settings copyWith({
    bool? isDarkMode,
    double? fontSize,
    double? speechRate,
    double? volume,
    String? voiceId,
    bool? isSoundEnabled,
    String? fontFamily,
    List<int>? highlightColors,
    String? language,
    double? pitch,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      voiceId: voiceId ?? this.voiceId,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      fontFamily: fontFamily ?? this.fontFamily,
      highlightColors: highlightColors ?? this.highlightColors,
      language: language ?? this.language,
      pitch: pitch ?? this.pitch,
    );
  }

  factory Settings.defaultSettings() {
    return const Settings(
      isDarkMode: false,
      fontSize: 16.0,
      speechRate: 1.0,
      volume: 1.0,
      voiceId: '',
      isSoundEnabled: true,
      fontFamily: 'Roboto',
      highlightColors: [0xFF1976D2],
      language: 'ru-RU',
      pitch: 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Settings &&
        other.isDarkMode == isDarkMode &&
        other.fontSize == fontSize &&
        other.speechRate == speechRate &&
        other.volume == volume &&
        other.voiceId == voiceId &&
        other.isSoundEnabled == isSoundEnabled &&
        other.fontFamily == fontFamily &&
        other.language == language &&
        other.pitch == pitch;
  }

  @override
  int get hashCode {
    return isDarkMode.hashCode ^
        fontSize.hashCode ^
        speechRate.hashCode ^
        volume.hashCode ^
        voiceId.hashCode ^
        isSoundEnabled.hashCode ^
        fontFamily.hashCode ^
        language.hashCode ^
        pitch.hashCode;
  }

  @override
  String toString() {
    return 'Settings(isDarkMode: $isDarkMode, fontSize: $fontSize, speechRate: $speechRate, volume: $volume, voiceId: $voiceId, isSoundEnabled: $isSoundEnabled, fontFamily: $fontFamily, highlightColors: $highlightColors, language: $language, pitch: $pitch)';
  }
}
