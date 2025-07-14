// lib/data/migration/migration_service.dart

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as old_db; // Keep for reading old db
import 'package:poteu/data/repositories/data_regulation_repository.dart';
import 'package:poteu/data/repositories/static_regulation_repository.dart';
import 'package:poteu/domain/entities/paragraph.dart';
import 'dart:developer' as dev;

// Временная модель для десериализации данных из старой базы SQLite.
// Поля названы в точности как в старой таблице.
class OldEditedParagraph {
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

class MigrationService {
  // final StaticRegulationRepository _staticRepo;
  final DataRegulationRepository _dataRepo; // Репозиторий для записи данных

  MigrationService({
    required StaticRegulationRepository staticRepo,
    required DataRegulationRepository dataRepo, // Добавляем зависимость
  }) :
        // _staticRepo = staticRepo,
        _dataRepo = dataRepo;

  Future<void> migrateIfNeeded() async {
    const String migrationFlagKey = 'sqlite_migration_v2_completed';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(migrationFlagKey) ?? false) {
      dev.log('[MIGRATION_LOG] Миграция уже была выполнена. Пропускаем.');
      return;
    }

    dev.log('[MIGRATION_LOG] 🚀 Запуск миграции данных из SQLite...');

    try {
      final oldDbPath = join(await old_db.getDatabasesPath(), 'paragraphs.db');
      dev.log('[MIGRATION_LOG] ℹ️ Путь к старой базе: $oldDbPath');

      if (!await old_db.databaseExists(oldDbPath)) {
        dev.log(
            '[MIGRATION_LOG] 🟡 Старая база данных не найдена. Миграция не требуется.');
        await prefs.setBool(migrationFlagKey, true);
        return;
      }

      final db = await old_db.openDatabase(oldDbPath);
      final List<Map<String, dynamic>> oldParagraphsJson =
          await db.query('paragraphs');
      await db.close();

      if (oldParagraphsJson.isEmpty) {
        dev.log(
            '[MIGRATION_LOG] 🟡 В старой базе данных нет данных для миграции.');
        await prefs.setBool(migrationFlagKey, true);
        return;
      }

      dev.log(
          '[MIGRATION_LOG] 🔍 Найдено ${oldParagraphsJson.length} записей для миграции.');

      for (final oldDataJson in oldParagraphsJson) {
        final oldParagraph = OldEditedParagraph.fromJson(oldDataJson);

        dev.log(
            '[MIGRATION_LOG] --- Мигрируем параграф ID: ${oldParagraph.paragraphId}');
        dev.log('[MIGRATION_LOG] --- Старый контент: ${oldParagraph.text}');

        // Создаем временный объект Paragraph, который требует метод сохранения.
        // Нам важны только ID для правильного поиска и сохранения.
        final tempParagraph = Paragraph(
          id: oldParagraph.paragraphId,
          originalId: oldParagraph.paragraphId,
          chapterId: oldParagraph.chapterId,
          num: 0, // Не используется при сохранении
          content: '', // Будет перезаписан
        );

        // Используем метод из репозитория нового приложения для сохранения данных.
        // Это гарантирует, что данные сохранятся правильно.
        await _dataRepo.saveEditedParagraph(
          oldParagraph.paragraphId, // ID для поиска
          oldParagraph.text, // Контент, который нужно сохранить
          tempParagraph, // Вспомогательный объект
        );

        dev.log(
            '[MIGRATION_LOG] --- Запись для параграфа ${oldParagraph.paragraphId} успешно сохранена.');
      }

      await prefs.setBool(migrationFlagKey, true);
      dev.log('[MIGRATION_LOG] ✅✅✅ Миграция успешно завершена!');
    } catch (e, stackTrace) {
      dev.log('[MIGRATION_LOG] ❌❌❌ КРИТИЧЕСКАЯ ОШИБКА МИГРАЦИИ: $e');
      dev.log(stackTrace.toString());
    }
  }
}
