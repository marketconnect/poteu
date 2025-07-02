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

  @override
  Future<void> updateParagraph(
      int paragraphId, Map<String, dynamic> data) async {
    await _db.updateParagraph(paragraphId, data);
  }

  @override
  Future<void> saveParagraphEdit(int paragraphId, String editedContent) async {
    await _db.saveParagraphEdit(paragraphId, editedContent);
  }

  @override
  Future<void> saveParagraphNote(int paragraphId, String note) async {
    await _db.saveParagraphNote(paragraphId, note);
  }

  @override
  Future<void> updateParagraphHighlight(
      int paragraphId, String highlightData) async {
    await _db.updateParagraphHighlight(paragraphId, highlightData);
  }

  // Method to get saved paragraph edits and apply them to original paragraphs
  Future<List<Paragraph>> applyParagraphEdits(
      List<Paragraph> originalParagraphs) async {
    final db = await _db.database;

    final List<Paragraph> updatedParagraphs = [];

    for (final paragraph in originalParagraphs) {
      // Check if there's a saved edit for this paragraph
      final List<Map<String, dynamic>> savedEdits = await db.query(
        'paragraphs',
        where: 'original_id = ? AND updated_at IS NOT NULL',
        whereArgs: [paragraph.originalId],
      );

      if (savedEdits.isNotEmpty) {
        final savedEdit = savedEdits.first;
        // Apply the saved formatting/content
        updatedParagraphs.add(paragraph.copyWith(
          content: savedEdit['content'],
          note: savedEdit['note'],
        ));
        print(
            'Applied saved formatting to paragraph ${paragraph.id}: "${savedEdit['content']}"');
      } else {
        // No saved edits, use original
        updatedParagraphs.add(paragraph);
      }
    }

    return updatedParagraphs;
  }

  // Method to check if a paragraph has saved edits
  Future<bool> hasParagraphEdits(int originalParagraphId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> savedEdits = await db.query(
      'paragraphs',
      where: 'original_id = ? AND updated_at IS NOT NULL',
      whereArgs: [originalParagraphId],
    );
    return savedEdits.isNotEmpty;
  }

  // Method to get saved edit for a specific paragraph
  Future<Map<String, dynamic>?> getParagraphEdit(
      int originalParagraphId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> savedEdits = await db.query(
      'paragraphs',
      where: 'original_id = ? AND updated_at IS NOT NULL',
      whereArgs: [originalParagraphId],
    );
    return savedEdits.isNotEmpty ? savedEdits.first : null;
  }

  // Save paragraph edit by originalId, handling both create and update cases
  Future<void> saveParagraphEditByOriginalId(
      int originalId, String content, Paragraph originalParagraph) async {
    print('=== SAVE PARAGRAPH EDIT BY ORIGINAL ID ===');
    print('Original ID: $originalId');
    print('New content: "$content"');
    print('Chapter ID: ${originalParagraph.chapterId}');

    final db = await _db.database;

    // Check if entry exists
    final existing = await db.query(
      'paragraphs',
      where: 'original_id = ?',
      whereArgs: [originalId],
    );

    print(
        'Found ${existing.length} existing entries for originalId $originalId');

    if (existing.isNotEmpty) {
      // Update existing entry
      print('Updating existing entry...');
      final updateResult = await db.update(
        'paragraphs',
        {
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'original_id = ?',
        whereArgs: [originalId],
      );
      print('✅ Updated $updateResult rows for originalId: $originalId');
    } else {
      // Create new entry
      print('Creating new entry...');
      final insertResult = await db.insert('paragraphs', {
        'original_id': originalId,
        'chapter_id': originalParagraph.chapterId,
        'num': originalParagraph.num,
        'content': content,
        'text_to_speech': originalParagraph.textToSpeech,
        'is_table': originalParagraph.isTable ? 1 : 0,
        'is_nft': originalParagraph.isNft ? 1 : 0,
        'paragraph_class': originalParagraph.paragraphClass ?? '',
        'note': originalParagraph.note,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print(
          '✅ Created new paragraph edit with ID: $insertResult for originalId: $originalId');
    }

    // Verify the save
    final verification = await db.query(
      'paragraphs',
      where: 'original_id = ? AND updated_at IS NOT NULL',
      whereArgs: [originalId],
    );
    print(
        'Verification: Found ${verification.length} entries with formatting for originalId $originalId');
    if (verification.isNotEmpty) {
      print('Saved content: "${verification.first['content']}"');
    }
  }
}
