import 'package:poteu/config.dart';

import 'duckdb_provider.dart';
import '../repositories/static_regulation_repository.dart';
import 'dart:developer' as dev;

/// Простой тест производительности для демонстрации оптимизации БД
class DatabasePerformanceTest {
  static Future<void> runPerformanceTest() async {
    dev.log('🚀 Starting database performance test...');

    final stopwatch = Stopwatch()..start();

    try {
      // Инициализируем провайдер БД
      await DuckDBProvider.instance.initialize();
      dev.log('✅ Database initialized in ${stopwatch.elapsedMilliseconds}ms');

      final repository = StaticRegulationRepository();

      // Тест 1: Загрузка списка глав (оптимизированный метод)
      stopwatch.reset();
      const testRegulationId = 1;
      final chapterList = await repository.getChapterList(testRegulationId);
      dev.log(
          '📚 Chapter list loaded in ${stopwatch.elapsedMilliseconds}ms (${chapterList.length} chapters)');

      // Тест 2: Загрузка содержимого одной главы
      if (chapterList.isNotEmpty) {
        stopwatch.reset();
        final chapterContent = await repository.getChapterContent(
            testRegulationId, chapterList.first.id);
        dev.log(
            '📖 Chapter content loaded in ${stopwatch.elapsedMilliseconds}ms (${chapterContent.paragraphs.length} paragraphs)');
      }

      // Тест 3: Поиск в регулировании
      stopwatch.reset();
      final searchResults = await repository.searchInRegulation(
        regulationId: AppConfig.instance.regulationId,
        query: 'общие',
      );
      dev.log(
          '🔍 Search completed in ${stopwatch.elapsedMilliseconds}ms (${searchResults.length} results)');

      dev.log('✅ All performance tests completed successfully!');
    } catch (e) {
      dev.log('❌ Performance test failed: $e');
    } finally {
      // Закрываем соединение
      await DuckDBProvider.instance.dispose();
    }
  }
}
