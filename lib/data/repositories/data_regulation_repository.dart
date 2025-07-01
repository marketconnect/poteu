import "../../domain/entities/chapter.dart";
import "../../domain/entities/regulation.dart";
import "../../domain/entities/paragraph.dart";
import "../../domain/repositories/regulation_repository.dart";
import "../helpers/database_helper.dart";

class DataRegulationRepository implements RegulationRepository {
  final DatabaseHelper _db;

  DataRegulationRepository(this._db);

  @override
  Future<List<Regulation>> getRegulations() async {
    return _db.getRegulations();
  }

  @override
  Future<Regulation> getRegulation(int id) async {
    final regulations = await getRegulations();
    final regulation = regulations.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Regulation not found'),
    );
    return regulation;
  }

  @override
  Future<void> toggleFavorite(int regulationId) async {
    await _db.toggleFavorite(regulationId);
  }

  @override
  Future<List<Regulation>> getFavorites() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "regulations",
      where: "isFavorite = ?",
      whereArgs: [1],
    );
    return Future.wait(maps.map((map) async {
      final chapters = await _getChapters(map["id"]);
      return Regulation(
        id: map["id"],
        title: map["title"],
        description: map["description"],
        lastUpdated: DateTime.parse(map["lastUpdated"]),
        isDownloaded: map["isDownloaded"] == 1,
        isFavorite: true,
        chapters: chapters,
      );
    }).toList());
  }

  @override
  Future<void> downloadRegulation(int regulationId) async {
    await _db.downloadRegulation(regulationId);
  }

  @override
  Future<void> deleteRegulation(int regulationId) async {
    await _db.deleteRegulation(regulationId);
  }

  @override
  Future<List<Regulation>> searchRegulations(String query) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "regulations",
      where: "title LIKE ? OR description LIKE ?",
      whereArgs: ["%$query%", "%$query%"],
    );

    return Future.wait(maps.map((map) async {
      final chapters = await _getChapters(map["id"]);
      return Regulation(
        id: map["id"],
        title: map["title"],
        description: map["description"],
        lastUpdated: DateTime.parse(map["lastUpdated"]),
        isDownloaded: map["isDownloaded"] == 1,
        isFavorite: map["isFavorite"] == 1,
        chapters: chapters,
      );
    }).toList());
  }

  Future<List<Chapter>> _getChapters(int regulationId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "chapters",
      where: "regulationId = ?",
      whereArgs: [regulationId],
      orderBy: "order_num ASC",
    );

    return Future.wait(maps.map((map) async {
      return Chapter(
        id: map["id"],
        regulationId: regulationId,
        title: map["title"],
        content: map["content"],
        level: map["order_num"] ?? 0,
      );
    }).toList());
  }

  @override
  Future<Map<String, dynamic>> getChapter(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "chapters",
      where: "id = ?",
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      throw Exception('Chapter not found');
    }
    return maps.first;
  }

  @override
  Future<List<Chapter>> getChapters(int regulationId) async {
    return _db.getChapters(regulationId);
  }

  @override
  Future<List<Chapter>> getChaptersByParentId(int parentId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      "chapters",
      where: "parentId = ?",
      whereArgs: [parentId],
      orderBy: "order_num ASC",
    );
    return maps
        .map((map) => Chapter(
              id: map["id"],
              regulationId: map["regulationId"],
              title: map["title"],
              content: map["content"],
              level: map["level"],
            ))
        .toList();
  }

  @override
  Future<List<Paragraph>> getParagraphsByChapterOrderNum(
      int regulationId, int chapterOrderNum) async {
    final db = await _db.database;

    // First find the chapter by order number
    final List<Map<String, dynamic>> chapterMaps = await db.query(
      "chapters",
      where: "regulationId = ? AND order_num = ?",
      whereArgs: [regulationId, chapterOrderNum],
    );

    if (chapterMaps.isEmpty) {
      return [];
    }

    final chapterId = chapterMaps.first['id'];
    final paragraphMaps = await _db.getParagraphs(chapterId);

    return paragraphMaps.map((map) => Paragraph.fromMap(map)).toList();
  }

  Future<List<Paragraph>> getParagraphsByChapterId(int chapterId) async {
    final paragraphMaps = await _db.getParagraphs(chapterId);
    return paragraphMaps.map((map) => Paragraph.fromMap(map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableOfContents() async {
    return await _db.query('chapters', orderBy: 'order_num');
  }

  @override
  Future<List<Map<String, dynamic>>> searchChapters(String query) async {
    // First search in chapters
    final chapterResults = await _db.query(
      'chapters',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    // Then search in paragraphs
    final paragraphResults = await _db.searchParagraphs(query);
    final chapterIds = paragraphResults.map((p) => p['chapter_id']).toSet();

    final additionalChapters = await Future.wait(
      chapterIds.map((id) async {
        final chapters = await _db.query(
          'chapters',
          where: 'id = ?',
          whereArgs: [id],
        );
        return chapters.isNotEmpty ? chapters.first : null;
      }),
    );

    final allResults = <Map<String, dynamic>>[
      ...chapterResults,
      ...additionalChapters
          .where((c) => c != null)
          .cast<Map<String, dynamic>>(),
    ];

    // Remove duplicates based on id
    final uniqueResults = <int, Map<String, dynamic>>{};
    for (final result in allResults) {
      uniqueResults[result['id']] = result;
    }

    return uniqueResults.values.toList();
  }

  @override
  Future<void> saveNote(int chapterId, String note) async {
    await _db.insert('notes', {
      'chapter_id': chapterId,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes() async {
    return await _db.query('notes');
  }

  @override
  Future<void> deleteNote(int noteId) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }
}
