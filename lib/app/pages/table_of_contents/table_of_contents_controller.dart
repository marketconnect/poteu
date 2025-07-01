import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../navigation/app_navigator.dart';
import 'table_of_contents_presenter.dart';

class TableOfContentsController extends Controller {
  final TableOfContentsPresenter _presenter;
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final int _regulationId;

  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get chapters => _chapters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TableOfContentsController({
    required int regulationId,
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  })  : _presenter = TableOfContentsPresenter(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          regulationId: regulationId,
        ),
        _regulationRepository = regulationRepository,
        _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository,
        _regulationId = regulationId {
    _initializePresenter();
    loadChapters();
  }

  void _initializePresenter() {
    _presenter.onChaptersLoaded = (chapters) {
      _chapters = chapters;
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

  void loadChapters() {
    _isLoading = true;
    _error = null;
    refreshUI();
    _presenter.getChapters();
  }

  void onChapterSelected(Map<String, dynamic> chapter) {
    AppNavigator.navigateToChapter(
      getContext(),
      regulationId: _regulationId,
      chapterOrderNum: chapter['level'] as int,
      regulationRepository: _regulationRepository,
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
    );
  }

  @override
  void initListeners() {}

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
