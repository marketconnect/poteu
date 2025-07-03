import 'package:flutter/material.dart';
import 'font_settings_presenter.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../main.dart';

class FontSettingsController extends ChangeNotifier {
  final FontSettingsPresenter _presenter;
  final SettingsRepository _settingsRepository;

  Settings? _currentSettings;
  Settings? get currentSettings => _currentSettings;

  FontSettingsController(SettingsRepository settingsRepository)
      : _presenter = FontSettingsPresenter(settingsRepository),
        _settingsRepository = settingsRepository {
    _initListeners();
  }

  void _initListeners() {
    _presenter.setFontSizeOnComplete = () {
      // После сохранения размера шрифта - перезагружаем настройки
      print('Font size saved successfully');
      _loadAndUpdateSettings();
    };

    _presenter.setFontSizeOnError = (e) {
      print('Error setting font size: $e');
    };

    _presenter.setFontFamilyOnComplete = () {
      // После сохранения семейства шрифта - перезагружаем настройки
      print('Font family saved successfully');
      _loadAndUpdateSettings();
    };

    _presenter.setFontFamilyOnError = (e) {
      print('Error setting font family: $e');
    };

    _presenter.getSettingsOnNext = (Settings? settings) {
      if (settings != null) {
        print(
            'Settings loaded: fontSize=${settings.fontSize}, fontFamily=${settings.fontFamily}');
        _currentSettings = settings;
        notifyListeners();
      }
    };

    _presenter.getSettingsOnComplete = () {
      print('Settings loaded successfully');
    };

    _presenter.getSettingsOnError = (e) {
      print('Error loading settings: $e');
    };
  }

  Future<void> _loadAndUpdateSettings() async {
    try {
      final settings = await _settingsRepository.getSettings();
      _currentSettings = settings;
      FontManager().updateSettings(settings);
      notifyListeners();
    } catch (e) {
      print('Error reloading settings: $e');
    }
  }

  void setFontSize(double fontSize) {
    print('FontSettingsController.setFontSize called with: $fontSize');
    _presenter.setFontSize(fontSize);
  }

  void setFontFamily(String fontFamily) {
    print('FontSettingsController.setFontFamily called with: $fontFamily');
    _presenter.setFontFamily(fontFamily);
  }

  void loadSettings() {
    _presenter.getSettings();
  }

  void initialize() {
    loadSettings();
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }
}
