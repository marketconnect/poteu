// lib/data/migration/migration_service.dart

import 'package:html/parser.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as old_db;
import 'package:poteu/data/repositories/data_regulation_repository.dart';
import 'package:poteu/data/repositories/static_regulation_repository.dart';

import 'package:poteu/domain/entities/paragraph.dart';

// Подключаем файл с функцией обфускации
import '../../app/utils/id_obfuscator.dart';

// Класс OldEditedParagraph остается без изменений
class OldEditedParagraph {
  // ... (код класса без изменений)
  final int? id;
  final int paragraphId;
  final int chapterId;
  final int lastTouched;
  final int edited;
  final String text;

  OldEditedParagraph({
    this.id,
    required this.paragraphId,
    required this.chapterId,
    required this.lastTouched,
    required this.edited,
    required this.text,
  });

  factory OldEditedParagraph.fromJson(Map<String, dynamic> json) {
    return OldEditedParagraph(
      id: json['_id'] as int?,
      paragraphId: json['_paragraphId'] as int,
      chapterId: json['_chapterId'] as int,
      lastTouched: json['lastTouched'] as int,
      edited: json['edited'] as int,
      text: json['text'] as String,
    );
  }
}

// Утилита для очистки "грязного" HTML из старой версии
String cleanHtmlContent(String htmlString) {
  final document = parse(htmlString);
  // Находим все теги <a>
  document.querySelectorAll('a').forEach((element) {
    // Заменяем тег его текстовым содержимым, если оно есть
    if (element.nodes.isNotEmpty) {
      element.replaceWith(element.nodes.first);
    } else {
      // Если тег пустой (<a></a>), просто удаляем его
      element.remove();
    }
  });
  // Возвращаем "очищенный" HTML, который может содержать другие теги форматирования (<u>, <span>)
  return document.body?.innerHtml ?? document.body?.text ?? '';
}

class MigrationService {
  final DataRegulationRepository _dataRepo;

  MigrationService({
    required StaticRegulationRepository staticRepo,
    required DataRegulationRepository dataRepo,
  }) : _dataRepo = dataRepo;

  Future<void> migrateIfNeeded() async {
    // ВАЖНО: Смените ключ, чтобы миграция запустилась заново на тестовых устройствах
    const String migrationFlagKey = 'sqlite_migration_v4_id_obfuscation_fix';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(migrationFlagKey) ?? false) {
      print('[MIGRATION_LOG] Миграция v4 уже была выполнена. Пропускаем.');
      return;
    }

    print(
        '[MIGRATION_LOG] 🚀 Запуск миграции данных из SQLite (v4 с обфускацией ID)...');

    try {
      final oldDbPath = join(await old_db.getDatabasesPath(), 'paragraphs.db');
      print('[MIGRATION_LOG] ℹ️ Путь к старой базе: $oldDbPath');

      if (!await old_db.databaseExists(oldDbPath)) {
        print(
            '[MIGRATION_LOG] 🟡 Старая база данных не найдена. Миграция не требуется.');
        await prefs.setBool(migrationFlagKey, true);
        return;
      }

      final db = await old_db.openDatabase(oldDbPath);
      final List<Map<String, dynamic>> oldParagraphsJson =
          await db.query('paragraphs');
      await db.close();

      if (oldParagraphsJson.isEmpty) {
        print(
            '[MIGRATION_LOG] 🟡 В старой базе данных нет данных для миграции.');
        await prefs.setBool(migrationFlagKey, true);
        return;
      }

      print(
          '[MIGRATION_LOG] 🔍 Найдено ${oldParagraphsJson.length} записей для миграции.');

      for (final oldDataJson in oldParagraphsJson) {
        final oldParagraph = OldEditedParagraph.fromJson(oldDataJson);

        // === КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Обфускация ID ===
        final newParagraphId = confuseId(oldParagraph.paragraphId);

        // === ВТОРОЕ ИСПРАВЛЕНИЕ: Очистка HTML ===
        final cleanedContent = cleanHtmlContent(oldParagraph.text);

        print(
            '[MIGRATION_LOG] --- Мигрируем параграф: старый ID ${oldParagraph.paragraphId} -> новый ID $newParagraphId');
        print('[MIGRATION_LOG] --- Старый контент: ${oldParagraph.text}');
        print('[MIGRATION_LOG] --- Очищенный контент: $cleanedContent');

        // Создаем временный объект Paragraph, который нужен для метода сохранения.
        // Важно передать в него новый, обфусцированный ID.
        final tempParagraph = Paragraph(
          id: newParagraphId,
          originalId:
              newParagraphId, // В новой архитектуре id и originalId совпадают
          chapterId: oldParagraph.chapterId,
          num: 0,
          content: '',
        );

        // Сохраняем данные, используя новый ID как ключ (original_id)
        await _dataRepo.saveParagraphEditByOriginalId(
          newParagraphId, // Ключ для поиска/создания записи
          cleanedContent, // Очищенный контент
          tempParagraph,
        );

        print(
            '[MIGRATION_LOG] --- Запись для параграфа $newParagraphId успешно сохранена.');
      }

      // Принудительно закрываем соединение с DuckDB, чтобы гарантировать,
      // что все изменения, сделанные во время миграции, будут сохранены на диск.
      // Это решает проблему, когда изменения терялись после перезапуска приложения.

      await prefs.setBool(migrationFlagKey, true);
      print('[MIGRATION_LOG] ✅✅✅ Миграция (v4) успешно завершена!');
    } catch (e, stackTrace) {
      print('[MIGRATION_LOG] ❌❌❌ КРИТИЧЕСКАЯ ОШИБКА МИГРАЦИИ: $e');
      print(stackTrace.toString());
    }
  }
}
