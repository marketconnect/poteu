import 'dart:async';
import '../../domain/entities/settings.dart';

class FontManager {
  static final FontManager _instance = FontManager._internal();
  factory FontManager() => _instance;
  FontManager._internal();

  final _fontController = StreamController<Settings>.broadcast();
  Settings _currentSettings = Settings.defaultSettings();

  Stream<Settings> get fontStream => _fontController.stream;
  Settings get currentSettings => _currentSettings;

  void updateSettings(Settings settings) {
    _currentSettings = settings;
    _fontController.add(settings);
  }

  void dispose() {
    _fontController.close();
  }
}
