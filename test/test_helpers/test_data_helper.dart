import 'package:flutter/material.dart';
import 'package:poteu/domain/entities/regulation.dart';
import 'package:poteu/domain/entities/chapter.dart';
import 'package:poteu/domain/entities/paragraph.dart';
import 'package:poteu/domain/entities/note.dart';
import 'package:poteu/domain/entities/search_result.dart';
import 'package:poteu/domain/entities/settings.dart';
import 'package:poteu/domain/entities/tts_state.dart';

/// Helper class for generating test data for UI tests
class TestDataHelper {
  static Regulation createTestRegulation({
    int id = 1,
    String title = 'ПОТЭУ',
    String description =
        'Правила охраны труда при эксплуатации электроустановок',
    bool isDownloaded = true,
    bool isFavorite = false,
    List<Chapter>? chapters,
  }) {
    return Regulation(
      id: id,
      title: title,
      description: description,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      isDownloaded: isDownloaded,
      isFavorite: isFavorite,
      chapters: chapters ?? createTestChapters(),
    );
  }

  static List<Chapter> createTestChapters() {
    return [
      Chapter(
        id: 1,
        regulationId: 1,
        title: 'Общие положения',
        content: '<p>Общие требования по охране труда</p>',
        level: 1,
        paragraphs: createTestParagraphs(chapterId: 1),
      ),
      Chapter(
        id: 2,
        regulationId: 1,
        title: 'Требования к персоналу',
        content: '<p>Квалификационные требования</p>',
        level: 2,
        paragraphs: createTestParagraphs(chapterId: 2),
      ),
      Chapter(
        id: 3,
        regulationId: 1,
        title: 'Электроустановки',
        content: '<p>Требования к электроустановкам</p>',
        level: 3,
        paragraphs: createTestParagraphs(chapterId: 3),
      ),
    ];
  }

  static List<Paragraph> createTestParagraphs({int chapterId = 1}) {
    return [
      Paragraph(
        id: chapterId * 100 + 1,
        originalId: chapterId * 100 + 1,
        chapterId: chapterId,
        num: 1,
        content:
            '<p>Настоящие Правила устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.</p>',
        textToSpeech:
            'Настоящие Правила устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
        isTable: false,
        isNft: false,
        paragraphClass: 'paragraph',
      ),
      Paragraph(
        id: chapterId * 100 + 2,
        originalId: chapterId * 100 + 2,
        chapterId: chapterId,
        num: 2,
        content:
            '<p>Действие Правил распространяется на работников, осуществляющих эксплуатацию электроустановок.</p>',
        textToSpeech:
            'Действие Правил распространяется на работников, осуществляющих эксплуатацию электроустановок.',
        isTable: false,
        isNft: false,
        paragraphClass: 'paragraph',
      ),
      Paragraph(
        id: chapterId * 100 + 3,
        originalId: chapterId * 100 + 3,
        chapterId: chapterId,
        num: 3,
        content:
            '<table><tr><td>Напряжение</td><td>Класс</td></tr><tr><td>До 1000 В</td><td>I</td></tr><tr><td>Свыше 1000 В</td><td>II</td></tr></table>',
        textToSpeech: 'Таблица классификации по напряжению',
        isTable: true,
        isNft: false,
        paragraphClass: 'table',
      ),
    ];
  }

  static List<Note> createTestNotes() {
    return [
      Note(
        paragraphId: 101,
        originalParagraphId: 101,
        chapterId: 1,
        chapterOrderNum: 1,
        regulationTitle: 'ПОТЭУ',
        chapterName: 'I. Общие положения',
        content:
            'Важное замечание: требования охраны труда обязательны для всех работников',
        lastTouched: DateTime.now().subtract(const Duration(hours: 2)),
        isEdited: true,
        link: const EditedParagraphLink(
          color: Color(0xFFFFEB3B),
          text:
              'Настоящие Правила устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
        ),
      ),
      Note(
        paragraphId: 102,
        originalParagraphId: 102,
        chapterId: 1,
        chapterOrderNum: 1,
        regulationTitle: 'ПОТЭУ',
        chapterName: 'I. Общие положения',
        content:
            'Обратить внимание: распространяется на всех работников, включая подрядчиков',
        lastTouched: DateTime.now().subtract(const Duration(hours: 1)),
        isEdited: false,
        link: const EditedParagraphLink(
          color: Color(0xFF4CAF50),
          text:
              'Действие Правил распространяется на работников, осуществляющих эксплуатацию электроустановок.',
        ),
      ),
      Note(
        paragraphId: 103,
        originalParagraphId: 103,
        chapterId: 1,
        chapterOrderNum: 1,
        regulationTitle: 'ПОТЭУ',
        chapterName: 'I. Общие положения',
        content: 'Важно: работы проводятся только по наряду-допуску',
        lastTouched: DateTime.now(),
        isEdited: true,
        link: const EditedParagraphLink(
          color: Color(0xFF1976D2),
          text:
              'Работы в электроустановках проводятся по наряду-допуску, распоряжению или в порядке текущей эксплуатации.',
        ),
      ),
    ];
  }

  static List<SearchResult> createTestSearchResults(String query) {
    if (query.isEmpty) return [];

    return [
      SearchResult(
        id: 1,
        paragraphId: 101,
        chapterOrderNum: 1,
        text:
            'Настоящие Правила устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
        matchStart: 0,
        matchEnd: query.length,
      ),
      SearchResult(
        id: 2,
        paragraphId: 102,
        chapterOrderNum: 1,
        text:
            'Действие Правил распространяется на работников, осуществляющих эксплуатацию электроустановок.',
        matchStart: 8,
        matchEnd: 8 + query.length,
      ),
      SearchResult(
        id: 3,
        paragraphId: 201,
        chapterOrderNum: 2,
        text:
            'Работники должны иметь соответствующую квалификацию для работы с электроустановками.',
        matchStart: 50,
        matchEnd: 50 + query.length,
      ),
    ];
  }

  static Settings createTestSettings({
    bool isDarkMode = false,
    double fontSize = 16.0,
    double speechRate = 1.0,
    double volume = 1.0,
    double pitch = 1.0,
    String voiceId = 'ru-RU-voice-1',
    bool isSoundEnabled = true,
    String language = 'ru-RU',
  }) {
    return Settings(
      isDarkMode: isDarkMode,
      fontSize: fontSize,
      speechRate: speechRate,
      volume: volume,
      voiceId: voiceId,
      isSoundEnabled: isSoundEnabled,
      highlightColors: const [0xFF1976D2, 0xFFFFEB3B, 0xFF4CAF50],
      language: language,
      pitch: pitch,
    );
  }

  static List<Map<String, dynamic>> createTestTableOfContents() {
    return [
      {
        'id': 1,
        'orderNum': 1,
        'name': 'Общие положения',
        'regulationId': 1,
      },
      {
        'id': 2,
        'orderNum': 2,
        'name': 'Требования к персоналу',
        'regulationId': 1,
      },
      {
        'id': 3,
        'orderNum': 3,
        'name': 'Электроустановки',
        'regulationId': 1,
      },
      {
        'id': 4,
        'orderNum': 4,
        'name': 'Средства защиты',
        'regulationId': 1,
      },
      {
        'id': 5,
        'orderNum': 5,
        'name': 'Организация работ',
        'regulationId': 1,
      },
      {
        'id': 6,
        'orderNum': 6,
        'name': 'Заключительные положения',
        'regulationId': 1,
      },
    ];
  }

  /// Creates test voices for TTS testing
  static List<Map<String, String>> createTestVoices() {
    return [
      {
        'name': 'Russian Male Voice',
        'locale': 'ru-RU',
        'id': 'ru-RU-voice-1',
      },
      {
        'name': 'Russian Female Voice',
        'locale': 'ru-RU',
        'id': 'ru-RU-voice-2',
      },
      {
        'name': 'English Male Voice',
        'locale': 'en-US',
        'id': 'en-US-voice-1',
      },
    ];
  }

  /// Creates empty/loading states for testing error scenarios
  static List<T> createEmptyList<T>() => <T>[];

  static String createErrorMessage(String operation) =>
      'Ошибка при выполнении операции: $operation';
}
