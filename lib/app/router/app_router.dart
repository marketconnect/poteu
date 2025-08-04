import 'package:flutter/material.dart';
import 'package:poteu/app/pages/chapter/model/chapter_arguments.dart';
import 'package:poteu/app/pages/chapter/chapter_view.dart';
import 'package:poteu/app/pages/library/library_view.dart';
import 'package:poteu/app/pages/notes/notes_view.dart';
import 'package:poteu/app/pages/search/search_view.dart';
import 'package:poteu/app/pages/table_of_contents/table_of_contents_page.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import 'package:poteu/domain/repositories/settings_repository.dart';
import 'package:poteu/domain/repositories/tts_repository.dart';
import 'package:poteu/data/repositories/data_regulation_repository.dart';
import 'package:poteu/data/repositories/static_regulation_repository.dart';
import '../../domain/repositories/notes_repository.dart';

// Simple mock repositories for router

abstract class AppRouteNames {
  static const contents = '/';
  static const chapter = '/chapter';
  static const notesList = '/notesList';
  static const library = '/library';
  static const search = '/search';
}

class AppRouter {
  final StaticRegulationRepository _repository = StaticRegulationRepository();
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final NotesRepository _notesRepository;

  AppRouter({
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required NotesRepository notesRepository,
  })  : _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository,
        _notesRepository = notesRepository;

  Route? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRouteNames.contents:
        return MaterialPageRoute(
          builder: (BuildContext context) => TableOfContentsView(
            regulationRepository: _repository,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
            notesRepository: _notesRepository,
            regulationId: ActiveRegulationService().currentRegulationId,
          ),
        );
      case AppRouteNames.notesList:
        return MaterialPageRoute(
          builder: (_) => NotesView(
            notesRepository: _notesRepository,
          ),
        );
      case AppRouteNames.library:
        return MaterialPageRoute(
          builder: (_) => const LibraryView(),
        );
      case AppRouteNames.chapter:
        final arguments = routeSettings.arguments;
        final chapterArguments = arguments is ChapterArguments
            ? arguments
            : const ChapterArguments(
                totalChapters: 6,
                chapterOrderNum: 1,
                scrollTo: 0,
                regulationId: 0);

        return MaterialPageRoute(
          builder: (_) => ChapterView(
            // Use the regulationId from arguments if provided, otherwise use the active one.
            regulationId: chapterArguments.regulationId > 0
                ? chapterArguments.regulationId
                : ActiveRegulationService().currentRegulationId,
            initialChapterOrderNum: chapterArguments.chapterOrderNum,
            scrollToParagraphId: chapterArguments.scrollTo > 0
                ? chapterArguments.scrollTo
                : null,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
            regulationRepository: DataRegulationRepository(),
          ),
        );
      case AppRouteNames.search:
        return MaterialPageRoute(
          builder: (_) => SearchView(
            regulationRepository: _repository,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
          ),
        );
      default:
        return null;
    }
  }
}
