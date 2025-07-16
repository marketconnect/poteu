import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../../domain/repositories/regulation_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/tts_repository.dart';
import '../../domain/repositories/notes_repository.dart';
import '../pages/chapter/chapter_view.dart';
import '../pages/table_of_contents/table_of_contents_page.dart';
import '../pages/notes/notes_view.dart';
import '../../data/repositories/data_regulation_repository.dart';

class AppNavigator {
  static void navigateToSearch(
    BuildContext context, {
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    Navigator.pushNamed(context, AppRouteNames.search);
  }

  static void navigateToSettings(
    BuildContext context, {
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    Navigator.pushNamed(context, '/settings');
  }

  static Future<void> navigateToChapter(
    BuildContext context, {
    required int regulationId,
    required int chapterOrderNum,
    required RegulationRepository regulationRepository,
    int? scrollToParagraphId,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterView(
          regulationId: regulationId,
          initialChapterOrderNum: chapterOrderNum,
          scrollToParagraphId: scrollToParagraphId,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          regulationRepository: DataRegulationRepository(),
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
    required NotesRepository notesRepository,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableOfContentsView(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          notesRepository: notesRepository,
          regulationId: regulationId,
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
