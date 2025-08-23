import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/tts_repository.dart';
import 'sound_settings_presenter.dart';

class SoundSettingsController extends Controller {
  final SoundSettingsPresenter _presenter;
  final TTSRepository _ttsRepository;

  // State
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  String _language = 'ru-RU';
  String _selectedVoice = '';
  List<dynamic> _availableVoices = [];
  String? _error;

  // Getters
  double get volume => _volume;
  double get pitch => _pitch;
  double get rate => _rate;
  String get language => _language;
  String get selectedVoice => _selectedVoice;
  List<dynamic> get availableVoices => _availableVoices;
  String? get error => _error;

  SoundSettingsController(settingsRepository, this._ttsRepository)
      : _presenter = SoundSettingsPresenter(settingsRepository) {
    _loadSettings();
    _loadVoices();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _presenter.getSettings();
      _volume = settings.volume;
      _pitch = settings.pitch;
      _rate = settings.speechRate;
      _language = settings.language;
      _selectedVoice = settings.voiceId;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> _loadVoices() async {
    try {
      _availableVoices = await _ttsRepository.getVoices();
      refreshUI();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  void setVolume(double value) {
    _volume = value;
    _presenter.setVolume(value);
    _ttsRepository.setVolume(value);
    refreshUI();
  }

  void setPitch(double value) {
    _pitch = value;
    _presenter.setPitch(value);
    _ttsRepository.setPitch(value);
    refreshUI();
  }

  void setRate(double value) {
    _rate = value;
    _presenter.setRate(value);
    _ttsRepository.setRate(value);
    refreshUI();
  }

  void setLanguage(String value) {
    _language = value;
    _presenter.setLanguage(value);
    _ttsRepository.setLanguage(value);
    refreshUI();
  }

  void setVoice(String value) {
    _selectedVoice = value;
    _presenter.setVoice(value);
    _ttsRepository.setVoice(value);
    refreshUI();
  }

  @override
  void initListeners() {
    _presenter.onComplete = () {
      _error = null;
      refreshUI();
    };

    _presenter.onError = (e) {
      _error = e.toString();
      refreshUI();
    };
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
