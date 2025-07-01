import '../../domain/entities/regulation.dart';
import '../../domain/entities/chapter.dart' as domain;
import '../../domain/entities/paragraph.dart' as domain;
import '../../domain/repositories/regulation_repository.dart';
import '../static/regulation.dart' as static_data;
import '../static/chapter.dart' as static_model;
import '../static/paragraph.dart' as static_model;

class StaticRegulationRepository implements RegulationRepository {
  // Маппер static->domain для параграфа
  domain.Paragraph _mapParagraph(static_model.Paragraph p, int chapterId) {
    return domain.Paragraph(
      id: p.id,
      originalId: p.id,
      chapterId: chapterId,
      num: p.num,
      content: p.content,
      textToSpeech:
          p.textToSpeech.isNotEmpty ? p.textToSpeech.join('\n') : null,
      isTable: p.isTable,
      isNft: p.isNFT,
      paragraphClass: p.paragraphClass.isNotEmpty ? p.paragraphClass : null,
      note: null,
    );
  }

  // Маппер static->domain для главы
  domain.Chapter _mapChapter(static_model.Chapter c) {
    return domain.Chapter(
      id: c.id,
      regulationId: 1,
      title: c.num.isNotEmpty ? '${c.num}. ${c.name}' : c.name,
      content: '',
      level: c.orderNum,
      subChapters: const [],
      paragraphs: c.paragraphs.map((p) => _mapParagraph(p, c.id)).toList(),
    );
  }

  @override
  Future<List<Regulation>> getRegulations() async {
    return [
      Regulation(
        id: static_data.Regulation.id,
        title: static_data.Regulation.name,
        description: '',
        lastUpdated: DateTime(2023, 1, 1),
        isDownloaded: true,
        isFavorite: false,
        chapters: static_data.Regulation.chapters.map(_mapChapter).toList(),
      ),
    ];
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
  Future<List<domain.Chapter>> getChapters(int regulationId) async {
    final reg = await getRegulation(regulationId);
    return reg.chapters;
  }

  @override
  Future<Map<String, dynamic>> getChapter(int id) async {
    final regs = await getRegulations();
    for (final reg in regs) {
      for (final chapter in reg.chapters) {
        if (chapter.id == id) {
          return {
            'id': chapter.id,
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
  Future<List<domain.Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum) async {
    final chapters = await getChapters(regulationId);
    final chapter = chapters.firstWhere((c) => c.level == chapterOrderNum);
    return chapter.paragraphs;
  }

  @override
  Future<List<Map<String, dynamic>>> getTableOfContents() async {
    final regs = await getRegulations();
    final toc = <Map<String, dynamic>>[];
    for (final reg in regs) {
      for (final chapter in reg.chapters) {
        toc.add({
          'id': chapter.id,
          'title': chapter.title,
          'level': chapter.level,
        });
      }
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
  Future<List<domain.Chapter>> getChaptersByParentId(int parentId) async => [];

  @override
  Future<void> saveNote(int chapterId, String note) async {}

  @override
  Future<List<Map<String, dynamic>>> getNotes() async => [];

  // Добавляем метод для получения главы по номеру порядка
  Future<domain.Chapter?> getChapterByOrderNum(int orderNum) async {
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
}
