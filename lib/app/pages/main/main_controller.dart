import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import "../../../domain/entities/regulation.dart";
import "../../../domain/repositories/regulation_repository.dart";
import "../../../domain/repositories/settings_repository.dart";
import "../../../domain/repositories/tts_repository.dart";
import "../../../domain/repositories/notes_repository.dart";
import "../../navigation/app_navigator.dart";
import "main_presenter.dart";

class MainController extends Controller {
  final MainPresenter _presenter;
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final NotesRepository _notesRepository;

  List<Regulation>? _regulations;
  bool _isLoading = true;
  String? _error;

  List<Regulation>? get regulations => _regulations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MainController({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required NotesRepository notesRepository,
  })  : _presenter = MainPresenter(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          notesRepository: notesRepository,
        ),
        _regulationRepository = regulationRepository,
        _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository,
        _notesRepository = notesRepository {
    _initializePresenter();
    _loadRegulations();
  }

  void _initializePresenter() {
    _presenter.onRegulationsLoaded = (regulations) {
      _regulations = regulations;
      _isLoading = false;
      _error = null;
      refreshUI();
    };

    _presenter.onError = (error) {
      _error = error.toString();
      _isLoading = false;
      refreshUI();
    };
  }

  void _loadRegulations() {
    _isLoading = true;
    _error = null;
    refreshUI();
    _presenter.getRegulations();
  }

  void selectRegulation(Regulation regulation) {
    AppNavigator.navigateToChapter(
      getContext(),
      regulationId: regulation.id,
      chapterOrderNum: regulation.chapters.first.level,
      regulationRepository: _regulationRepository,
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
    );
  }

  void navigateToSearch() {
    AppNavigator.navigateToSearch(
      getContext(),
      regulationRepository: _regulationRepository,
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
    );
  }

  void navigateToTableOfContents() {
    AppNavigator.navigateToTableOfContents(
      getContext(),
      regulationId: 1,
      regulationRepository: _regulationRepository,
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
      notesRepository: _notesRepository,
    );
  }

  void navigateToNotes() {
    AppNavigator.navigateToNotes(
      getContext(),
      notesRepository: _notesRepository,
    );
  }

  void navigateToSettings() {
    AppNavigator.navigateToSettings(
      getContext(),
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
    );
  }

  @override
  void initListeners() {
    // Initialize presenter listeners here
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }

  Future<void> toggleFavorite(int regulationId) async {
    try {
      await _regulationRepository.toggleFavorite(regulationId);
      _loadRegulations();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> downloadRegulation(int regulationId) async {
    try {
      await _regulationRepository.downloadRegulation(regulationId);
      _loadRegulations();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> deleteRegulation(int regulationId) async {
    try {
      await _regulationRepository.deleteRegulation(regulationId);
      _loadRegulations();
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }
}
