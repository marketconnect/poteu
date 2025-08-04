import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/entities/chapter.dart';
import '../../navigation/app_navigator.dart';
import 'table_of_contents_presenter.dart';

class TableOfContentsController extends Controller {
  TableOfContentsPresenter presenter;
  RegulationRepository regulationRepository;
  SettingsRepository settingsRepository;
  TTSRepository ttsRepository;
  int regulationId;

  List<Chapter> _chapters = [];
  bool _isLoading = true;
  String? _error;

  List<Chapter> get chapters => _chapters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TableOfContentsController({
    required this.regulationId,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
  }) : presenter = TableOfContentsPresenter(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          regulationId: regulationId,
        ) {
    _initializePresenter();
    loadChapters();
  }

  void _initializePresenter() {
    presenter.onChaptersLoaded = (chapters) {
      _chapters = chapters;
      _isLoading = false;
      _error = null;
      refreshUI();
    };

    presenter.onError = (error) {
      _error = error.toString();
      _isLoading = false;
      refreshUI();
    };
  }

  void loadChapters() {
    _isLoading = true;
    _error = null;
    refreshUI();
    presenter.getChapters();
  }

  void onChapterSelected(Chapter chapter) {
    AppNavigator.navigateToChapter(
      getContext(),
      regulationId: chapter.regulationId,
      chapterOrderNum: chapter.level,
      regulationRepository: regulationRepository,
      settingsRepository: settingsRepository,
      ttsRepository: ttsRepository,
    );
  }

  @override
  void initListeners() {}

  @override
  void onDisposed() {
    presenter.dispose();
    super.onDisposed();
  }
}
