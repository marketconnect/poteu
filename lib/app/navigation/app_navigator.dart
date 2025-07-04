import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../../domain/repositories/regulation_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/tts_repository.dart';
import '../../domain/repositories/notes_repository.dart';
import '../pages/search/search_page.dart';
import '../pages/chapter/chapter_view.dart';
import '../pages/table_of_contents/table_of_contents_page.dart';
import '../pages/notes/notes_view.dart';

class AppNavigator {
  static void navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, AppRouteNames.search);
  }

  static void navigateToSettings(
    BuildContext context, {
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    Navigator.pushNamed(context, '/settings');
  }

  static void navigateToChapter(
    BuildContext context, {
    required int regulationId,
    required int chapterOrderNum,
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterView(
          regulationId: regulationId,
          initialChapterOrderNum: chapterOrderNum,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
        ),
      ),
    );
  }

  static void navigateToTableOfContents(
    BuildContext context, {
    required int regulationId,
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableOfContentsPage(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
        ),
      ),
    );
  }

  static void navigateToNotes(
    BuildContext context, {
    required NotesRepository notesRepository,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesView(
          notesRepository: notesRepository,
        ),
      ),
    );
  }
}
