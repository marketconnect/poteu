import 'package:poteu/domain/entities/chapter.dart';
import 'package:poteu/domain/entities/paragraph.dart';

import '../../domain/entities/regulation.dart';

import '../../domain/repositories/regulation_repository.dart';

import '../../domain/entities/search_result.dart';
import '../../app/utils/text_utils.dart';
import '../helpers/duckdb_provider.dart';

class StaticRegulationRepository implements RegulationRepository {
  final DuckDBProvider _dbProvider = DuckDBProvider.instance;

  @override
  Future<List<Regulation>> getRegulations() async {
    return await _dbProvider.executeTransaction((conn) async {
      // 3. Чтение правил
      final rulesRs =
          await conn.query('SELECT id, name, abbreviation FROM rules');
      final rules = rulesRs.fetchAll();

      final regs = <Regulation>[];
      for (final row in rules) {
        final ruleId = row[0] as int;
        final title = row[1] as String;
        final description = row[2] as String;

        // 4. Чтение глав
        final chRs = await conn.query(
            'SELECT id, name, orderNum, num FROM chapters WHERE rule_id = $ruleId ORDER BY orderNum');
        final chapters = <Chapter>[];
        for (final ch in chRs.fetchAll()) {
          final chapId = ch[0] as int;
          final chapName = ch[1] as String;
          final chapOrderNum = ch[2] as int;
          final chapNum = ch[3] as String;
          // 5. Чтение параграфов
          final pRs = await conn.query(
              'SELECT id, num, content, text_to_speech, isTable, isNFT, paragraphClass '
              'FROM paragraphs WHERE chapterID = $chapId ORDER BY num');
          final paras = pRs
              .fetchAll()
              .map((p) => Paragraph.fromMap({
                    'id': p[0],
                    'original_id': p[0],
                    'chapter_id': chapId,
                    'num': p[1],
                    'content': p[2],
                    'text_to_speech': p[3],
                    'is_table': (p[4] as bool) ? 1 : 0,
                    'is_nft': (p[5] as bool) ? 1 : 0,
                    'paragraph_class': p[6],
                    'note': '',
                  }))
              .toList();

          chapters.add(Chapter(
            id: chapId,
            num: chapNum,
            regulationId: ruleId,
            title: chapName,
            content: '',
            level: chapOrderNum,
            subChapters: const [],
            paragraphs: paras,
          ));
        }

        regs.add(Regulation(
          id: ruleId,
          title: title,
          description: description,
          sourceName: '',
          sourceUrl: '',
          lastUpdated: DateTime.now(),
          isDownloaded: true,
          isFavorite: false,
          chapters: chapters,
        ));
      }

      return regs;
    });
  }

  @override
  Future<Regulation> getRegulation(int id) async {
    final regs = await getRegulations();
    return regs.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> toggleFavorite(int regulationId) async {}

  @override
  Future<List<Regulation>> getFavorites() async => [];

  @override
  Future<void> downloadRegulation(int regulationId) async {}

  @override
  Future<void> deleteRegulation(int regulationId) async {}

  @override
  Future<List<Regulation>> searchRegulations(String query) async {
    final regs = await getRegulations();
    return regs
        .where((r) => r.title.contains(query) || r.description.contains(query))
        .toList();
  }

  @override
  Future<List<Chapter>> getChapters(int regulationId) async {
    return await _dbProvider.executeTransaction((conn) async {
      final chRs = await conn.query(
          'SELECT id, name, orderNum, num FROM chapters WHERE rule_id = $regulationId ORDER BY orderNum');
      final chapters = <Chapter>[];
      for (final ch in chRs.fetchAll()) {
        chapters.add(Chapter(
          id: ch[0] as int,
          title: ch[1] as String,
          level: ch[2] as int,
          num: ch[3] as String,
          regulationId: regulationId,
          content: '',
          paragraphs: [],
          subChapters: [],
        ));
      }
      return chapters;
    });
  }

  /// Загружает только список глав (ID, номер, название) без их содержимого
  @override
  Future<List<ChapterInfo>> getChapterList(int regulationId) async {
    return await _dbProvider.executeTransaction((conn) async {
      // 3. Чтение только списка глав без параграфов
      final chRs = await conn.query(
          'SELECT id, name, orderNum FROM chapters WHERE rule_id = $regulationId ORDER BY orderNum');

      final chapters = <ChapterInfo>[];
      for (final ch in chRs.fetchAll()) {
        final chapId = ch[0] as int;
        final chapName = ch[1] as String;
        final chapOrderNum = ch[2] as int;

        chapters.add(ChapterInfo(
          id: chapId,
          orderNum: chapOrderNum,
          name: chapName,
          regulationId: regulationId,
        ));
      }

      return chapters;
    });
  }

  /// Загружает полное содержимое (все параграфы) только для одной конкретной главы по ее ID
  @override
  Future<Chapter> getChapterContent(int regulationId, int chapterId) async {
    return await _dbProvider.executeTransaction((conn) async {
      // 3. Чтение информации о главе
      final chRs = await conn.query(
          'SELECT id, rule_id, name, orderNum, num FROM chapters WHERE id = $chapterId AND rule_id = $regulationId');

      if (chRs.fetchAll().isEmpty) {
        throw Exception('Chapter not found: $chapterId');
      }

      final ch = chRs.fetchAll().first;
      final chapId = ch[0] as int;
      final ruleId = ch[1] as int;
      final chapName = ch[2] as String;
      final chapOrderNum = ch[3] as int;
      final chapNum = ch[4] as String;
      // 4. Чтение параграфов для этой главы
      final pRs = await conn.query(
          'SELECT id, num, content, text_to_speech, isTable, isNFT, paragraphClass '
          'FROM paragraphs WHERE chapterID = $chapId ORDER BY num');

      final paras = pRs
          .fetchAll()
          .map((p) => Paragraph.fromMap({
                'id': p[0],
                'original_id': p[0],
                'chapter_id': chapId,
                'num': p[1],
                'content': p[2],
                'text_to_speech': p[3],
                'is_table': (p[4] as bool) ? 1 : 0,
                'is_nft': (p[5] as bool) ? 1 : 0,
                'paragraph_class': p[6],
                'note': '',
              }))
          .toList();

      return Chapter(
        id: chapId,
        num: chapNum,
        regulationId: ruleId,
        title: chapName,
        content: '',
        level: chapOrderNum,
        subChapters: const [],
        paragraphs: paras,
      );
    });
  }

  @override
  Future<Map<String, dynamic>> getChapter(int id) async {
    final regs = await getRegulations();
    for (final reg in regs) {
      for (final chapter in reg.chapters) {
        if (chapter.id == id) {
          return {
            'id': chapter.id,
            'num': chapter.num,
            'title': chapter.title,
            'level': chapter.level,
            'paragraphs': chapter.paragraphs,
          };
        }
      }
    }
    throw Exception('Chapter not found');
  }

  @override
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum) async {
    final chapters = await getChapters(regulationId);
    final chapter = chapters.firstWhere((c) => c.level == chapterOrderNum);
    return chapter.paragraphs;
  }

  @override
  Future<List<Chapter>> getTableOfContents() async {
    final regs = await getRegulations();
    final toc = <Chapter>[];
    for (final reg in regs) {
      toc.addAll(reg.chapters);
    }
    return toc;
  }

  @override
  Future<List<Map<String, dynamic>>> searchChapters(String query) async {
    final chapters = (await getRegulations())
        .expand((r) => r.chapters)
        .where((c) => c.title.contains(query))
        .map((c) => {
              'id': c.id,
              'title': c.title,
              'level': c.level,
            })
        .toList();
    return chapters;
  }

  @override
  Future<void> deleteNote(int noteId) async {}

  @override
  Future<List<Chapter>> getChaptersByParentId(int parentId) async => [];

  @override
  Future<void> saveNote(int chapterId, String note) async {}

  @override
  Future<List<Map<String, dynamic>>> getNotes() async => [];

  // Добавляем метод для получения главы по номеру порядка
  Future<Chapter?> getChapterByOrderNum(int orderNum) async {
    final regs = await getRegulations();
    for (final reg in regs) {
      for (final chapter in reg.chapters) {
        if (chapter.level == orderNum) {
          return chapter;
        }
      }
    }
    return null;
  }

  @override
  Future<void> updateParagraph(
      int paragraphId, Map<String, dynamic> data) async {
    // Static repository - editing not supported
    throw UnsupportedError('Editing not supported in static repository');
  }

  @override
  Future<void> saveParagraphEdit(int paragraphId, String editedContent) async {
    // Static repository - editing not supported
    throw UnsupportedError('Editing not supported in static repository');
  }

  @override
  Future<void> saveParagraphNote(int paragraphId, String note) async {
    // Static repository - editing not supported
    throw UnsupportedError('Editing not supported in static repository');
  }

  @override
  Future<void> updateParagraphHighlight(
      int paragraphId, String highlightData) async {
    // Static repository - editing not supported
    throw UnsupportedError('Editing not supported in static repository');
  }

  @override
  Future<List<Paragraph>> applyParagraphEdits(
      List<Paragraph> originalParagraphs) async {
    // Static repository - just return original paragraphs unchanged
    return originalParagraphs;
  }

  @override
  Future<bool> hasParagraphEdits(int originalParagraphId) async {
    // Static repository - no edits stored
    return false;
  }

  @override
  Future<Map<String, dynamic>?> getParagraphEdit(
      int originalParagraphId) async {
    // Static repository - no edits stored
    return null;
  }

  @override
  Future<void> saveParagraphEditByOriginalId(
      int originalId, String content, Paragraph originalParagraph) async {
    // Static repository - editing not supported
    throw UnsupportedError('Editing not supported in static repository');
  }

  @override
  Future<void> saveEditedParagraph(int paragraphId, String editedContent,
      Paragraph originalParagraph) async {
    // StaticRegulationRepository is for read-only data
    // For saving edits, use DataRegulationRepository instead
    throw UnimplementedError(
        'StaticRegulationRepository does not support editing. Use DataRegulationRepository instead.');
  }

  @override
  Future<List<SearchResult>> searchInRegulation({
    required int regulationId,
    required String query,
  }) async {
    if (query.isEmpty) return [];

    return await _dbProvider.executeTransaction((conn) async {
      final results = <SearchResult>[];
      int searchResultId = 0;

      // Get regulation name
      final ruleNameRs =
          await conn.query('SELECT name FROM rules WHERE id = $regulationId');
      final ruleRows = ruleNameRs.fetchAll();
      if (ruleRows.isEmpty) {
        // Regulation not found, return empty list
        return [];
      }
      final regulationName = ruleRows.first[0] as String;

      // Получаем все главы для данного regulation
      final chRs = await conn.query(
          'SELECT id, orderNum FROM chapters WHERE rule_id = $regulationId ORDER BY orderNum');
      final chapters = chRs.fetchAll();

      for (final ch in chapters) {
        final chapterId = ch[0] as int;
        final chapterOrderNum = ch[1] as int;

        // Получаем параграфы для главы
        final pRs = await conn.query(
            'SELECT id, content FROM paragraphs WHERE chapterID = $chapterId ORDER BY num');
        final paragraphs = pRs.fetchAll();

        for (final p in paragraphs) {
          final paragraphId = p[0] as int;
          final content = p[1] as String;

          final text = TextUtils.parseHtmlString(content);
          final lowerText = text.toLowerCase();
          final lowerQuery = query.toLowerCase();

          int startIndex = lowerText.indexOf(lowerQuery);
          while (startIndex != -1) {
            // Get context around the found text
            int contextStart = startIndex - 50;
            if (contextStart < 0) contextStart = 0;

            int contextEnd = startIndex + query.length + 50;
            if (contextEnd > text.length) contextEnd = text.length;

            final contextText = text.substring(contextStart, contextEnd);
            final matchStartInContext = startIndex - contextStart;
            final matchEndInContext = matchStartInContext + query.length;

            results.add(SearchResult(
              id: searchResultId++,
              regulationId: regulationId,
              regulationTitle: regulationName,
              paragraphId: paragraphId,
              chapterOrderNum: chapterOrderNum,
              text: contextText,
              matchStart: matchStartInContext,
              matchEnd: matchEndInContext,
            ));

            // Find next occurrence
            startIndex = lowerText.indexOf(lowerQuery, startIndex + 1);
          }
        }
      }

      return results;
    });
  }

  @override
  Future<List<SearchResult>> searchInAllRegulations(
      {required String query}) async {
    if (query.isEmpty) return [];

    return await _dbProvider.executeTransaction((conn) async {
      final results = <SearchResult>[];
      int searchResultId = 0;

      // Get all rules
      final rulesRs = await conn.query('SELECT id, name FROM rules');
      final allRules = rulesRs.fetchAll();

      for (final rule in allRules) {
        final regulationId = rule[0] as int;
        final regulationName = rule[1] as String;

        // Get all chapters for this regulation
        final chRs = await conn.query(
            'SELECT id, orderNum FROM chapters WHERE rule_id = $regulationId ORDER BY orderNum');
        final chapters = chRs.fetchAll();

        for (final ch in chapters) {
          final chapterId = ch[0] as int;
          final chapterOrderNum = ch[1] as int;

          // Get paragraphs for the chapter
          final pRs = await conn.query(
              'SELECT id, content FROM paragraphs WHERE chapterID = $chapterId ORDER BY num');
          final paragraphs = pRs.fetchAll();

          for (final p in paragraphs) {
            final paragraphId = p[0] as int;
            final content = p[1] as String;

            final text = TextUtils.parseHtmlString(content);
            final lowerText = text.toLowerCase();
            final lowerQuery = query.toLowerCase();

            int startIndex = lowerText.indexOf(lowerQuery);
            while (startIndex != -1) {
              int contextStart = startIndex - 50;
              if (contextStart < 0) contextStart = 0;

              int contextEnd = startIndex + query.length + 50;
              if (contextEnd > text.length) contextEnd = text.length;

              final contextText = text.substring(contextStart, contextEnd);
              final matchStartInContext = startIndex - contextStart;
              final matchEndInContext = matchStartInContext + query.length;

              results.add(SearchResult(
                  id: searchResultId++,
                  regulationId: regulationId,
                  regulationTitle: regulationName,
                  paragraphId: paragraphId,
                  chapterOrderNum: chapterOrderNum,
                  text: contextText,
                  matchStart: matchStartInContext,
                  matchEnd: matchEndInContext));

              startIndex = lowerText.indexOf(lowerQuery, startIndex + 1);
            }
          }
        }
      }
      return results;
    });
  }

  @override
  Future<bool> isRegulationCached(int regulationId) async {
    return await _dbProvider.executeTransaction((conn) async {
      final result = await conn.query(
          'SELECT 1 FROM chapters WHERE rule_id = $regulationId LIMIT 1');
      return result.fetchAll().isNotEmpty;
    });
  }

  @override
  Future<void> deletePremiumContent() async {
    // Static repository is read-only, so this is a no-op.
    return;
  }

  @override
  Future<void> saveRegulations(List<Regulation> regulations) {
    // Static repository is read-only
    throw UnimplementedError('StaticRegulationRepository is read-only.');
  }
}