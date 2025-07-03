import 'package:flutter/material.dart';
import 'package:poteu/app/pages/chapter/model/chapter_arguments.dart';
import 'package:poteu/app/pages/chapter/chapter_view.dart';
import 'package:poteu/app/pages/notes/notes_view.dart';
import 'package:poteu/app/pages/search/search_page.dart';
import 'package:poteu/app/pages/table_of_contents/table_of_contents_page.dart';
import 'package:poteu/data/repositories/static_regulation_repository.dart';
import 'package:poteu/data/repositories/data_notes_repository.dart';
import 'package:poteu/data/repositories/data_settings_repository.dart';
import 'package:poteu/data/repositories/data_tts_repository.dart';
import 'package:poteu/data/helpers/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/tts_repository.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/entities/settings.dart';
import 'dart:async';
import '../../domain/entities/tts_state.dart';

// Simple mock repositories for router
class _MockSettingsRepository implements SettingsRepository {
  @override
  Future<Settings> getSettings() async => Settings(
        isDarkMode: false,
        fontSize: 16.0,
        isSoundEnabled: true,
        highlightColors: [0xFF1976D2],
        language: "ru-RU",
        speechRate: 1.0,
        pitch: 1.0,
        voiceId: '',
        volume: 1.0,
      );

  @override
  Future<void> saveSettings(Settings settings) async {}
  @override
  Future<void> setTheme(bool isDarkMode) async {}
  @override
  Future<void> setFontSize(double fontSize) async {}
  @override
  Future<void> setSoundEnabled(bool enabled) async {}
  @override
  Future<void> setHighlightColors(List<int> colors) async {}
  @override
  Future<void> setLanguage(String language) async {}
  @override
  Future<void> setColors(Map<String, String> colors) async {}
  @override
  Future<void> setDarkTheme(bool isDark) async {}
  @override
  Future<void> setSpeechRate(double speechRate) async {}
  @override
  Future<void> setPitch(double pitch) async {}
  @override
  Future<void> setVoiceId(String voiceId) async {}
  @override
  Future<void> setVolume(double volume) async {}
}

class _MockTTSRepository implements TTSRepository {
  final _stateController = StreamController<TtsState>.broadcast();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<List<String>> getLanguages() async => [];

  @override
  Future<bool> isLanguageAvailable(String language) async => false;

  @override
  Future<List<dynamic>> getVoices() async => [];

  @override
  Future<void> setVoice(String voice) async {}

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }
}

abstract class AppRouteNames {
  static const contents = '/';
  static const chapter = '/chapter';
  static const notesList = '/notesList';
  static const searchScreen = '/searchScreen';
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
          builder: (BuildContext context) => TableOfContentsPage(
            regulationRepository: _repository,
            settingsRepository: _settingsRepository,
            ttsRepository: _ttsRepository,
          ),
        );
      case AppRouteNames.notesList:
        return MaterialPageRoute(
          builder: (_) => NotesView(
            notesRepository: _notesRepository,
          ),
        );
      case AppRouteNames.chapter:
        final arguments = routeSettings.arguments;
        final chapterArguments = arguments is ChapterArguments
            ? arguments
            : ChapterArguments(
                totalChapters: 6, chapterOrderNum: 1, scrollTo: 0);

        return MaterialPageRoute(
          builder: (_) => ChapterView(
            regulationId: 1, // POTEU regulation ID
            initialChapterOrderNum: chapterArguments.chapterOrderNum,
            settingsRepository: _settingsRepository,
            scrollToParagraphId: chapterArguments.scrollTo > 0
                ? chapterArguments.scrollTo
                : null,
          ),
        );
      case AppRouteNames.searchScreen:
        return MaterialPageRoute(builder: (_) => const SearchPage());
      default:
        return null;
    }
  }
}
