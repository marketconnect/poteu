import 'duckdb_provider.dart';
import '../repositories/static_regulation_repository.dart';

/// Простой тест производительности для демонстрации оптимизации БД
class DatabasePerformanceTest {
  static Future<void> runPerformanceTest() async {
    print('🚀 Starting database performance test...');

    final stopwatch = Stopwatch()..start();

    try {
      // Инициализируем провайдер БД
      await DuckDBProvider.instance.initialize();
      print('✅ Database initialized in ${stopwatch.elapsedMilliseconds}ms');

      final repository = StaticRegulationRepository();

      // Тест 1: Загрузка списка глав (оптимизированный метод)
      stopwatch.reset();
      final chapterList = await repository.getChapterList(1);
      print(
          '📚 Chapter list loaded in ${stopwatch.elapsedMilliseconds}ms (${chapterList.length} chapters)');

      // Тест 2: Загрузка содержимого одной главы
      if (chapterList.isNotEmpty) {
        stopwatch.reset();
        final chapterContent =
            await repository.getChapterContent(chapterList.first.id);
        print(
            '📖 Chapter content loaded in ${stopwatch.elapsedMilliseconds}ms (${chapterContent.paragraphs.length} paragraphs)');
      }

      // Тест 3: Поиск в регулировании
      stopwatch.reset();
      final searchResults = await repository.searchInRegulation(
        regulationId: 1,
        query: 'общие',
      );
      print(
          '🔍 Search completed in ${stopwatch.elapsedMilliseconds}ms (${searchResults.length} results)');

      print('✅ All performance tests completed successfully!');
    } catch (e) {
      print('❌ Performance test failed: $e');
    } finally {
      // Закрываем соединение
      await DuckDBProvider.instance.dispose();
    }
  }
}
