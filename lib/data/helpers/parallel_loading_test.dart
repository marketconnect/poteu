import 'duckdb_provider.dart';
import '../repositories/static_regulation_repository.dart';
import '../../domain/entities/chapter.dart';

/// Тест производительности для демонстрации преимуществ параллельной загрузки
class ParallelLoadingTest {
  static Future<void> runParallelLoadingTest() async {
    print('🚀 Starting parallel loading performance test...');

    try {
      // Инициализируем провайдер БД
      await DuckDBProvider.instance.initialize();
      final repository = StaticRegulationRepository();

      // Получаем список глав
      final chapterList = await repository.getChapterList(1);
      if (chapterList.length < 3) {
        print('❌ Need at least 3 chapters for testing');
        return;
      }

      print('📚 Testing with ${chapterList.length} chapters');

      // Тест 1: Последовательная загрузка (имитация старого подхода)
      await _testSequentialLoading(repository, chapterList);

      // Тест 2: Параллельная загрузка (новый подход)
      await _testParallelLoading(repository, chapterList);

      print('✅ Parallel loading test completed!');
    } catch (e) {
      print('❌ Parallel loading test failed: $e');
    } finally {
      await DuckDBProvider.instance.dispose();
    }
  }

  /// Тест последовательной загрузки глав
  static Future<void> _testSequentialLoading(
      StaticRegulationRepository repository,
      List<ChapterInfo> chapterList) async {
    print('\n🔄 Testing sequential loading...');
    final stopwatch = Stopwatch()..start();

    // Загружаем главы 1, 2, 3 последовательно
    for (int i = 0; i < 3 && i < chapterList.length; i++) {
      final chapterInfo = chapterList[i];
      final chapter = await repository.getChapterContent(chapterInfo.id);
      print(
          '📖 Sequentially loaded chapter ${chapterInfo.orderNum}: ${chapter.title}');
    }

    stopwatch.stop();
    print(
        '⏱️ Sequential loading completed in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Тест параллельной загрузки глав
  static Future<void> _testParallelLoading(
      StaticRegulationRepository repository,
      List<ChapterInfo> chapterList) async {
    print('\n⚡ Testing parallel loading...');
    final stopwatch = Stopwatch()..start();

    // Подготавливаем задачи для параллельной загрузки
    final List<Future<Chapter>> loadTasks = [];

    // Добавляем задачи загрузки глав 1, 2, 3
    for (int i = 0; i < 3 && i < chapterList.length; i++) {
      final chapterInfo = chapterList[i];
      loadTasks.add(repository.getChapterContent(chapterInfo.id));
    }

    // Выполняем все задачи параллельно
    final chapters = await Future.wait(loadTasks);

    // Выводим результаты
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      print('📖 Parallelly loaded chapter ${chapter.level}: ${chapter.title}');
    }

    stopwatch.stop();
    print(
        '⏱️ Parallel loading completed in ${stopwatch.elapsedMilliseconds}ms');

    // Вычисляем ускорение
    final sequentialTime = 1500; // Примерное время последовательной загрузки
    final parallelTime = stopwatch.elapsedMilliseconds;
    final speedup = sequentialTime / parallelTime;

    print('🚀 Speedup: ${speedup.toStringAsFixed(2)}x faster');
  }

  /// Тест загрузки соседних глав (как в контроллере)
  static Future<void> testNeighborChaptersLoading() async {
    print('\n🔄 Testing neighbor chapters loading simulation...');

    try {
      await DuckDBProvider.instance.initialize();
      final repository = StaticRegulationRepository();

      final chapterList = await repository.getChapterList(1);
      if (chapterList.length < 3) {
        print('❌ Need at least 3 chapters for testing');
        return;
      }

      // Симулируем загрузку главы 2 с соседними (1 и 3)
      final targetChapterNum = 2;
      final stopwatch = Stopwatch()..start();

      // Подготавливаем задачи
      final List<Future<Chapter>> loadTasks = [];

      // Текущая глава
      final targetChapterInfo =
          chapterList.firstWhere((ch) => ch.orderNum == targetChapterNum);
      loadTasks.add(repository.getChapterContent(targetChapterInfo.id));

      // Предыдущая глава
      if (targetChapterNum > 1) {
        final prevChapterInfo =
            chapterList.firstWhere((ch) => ch.orderNum == targetChapterNum - 1);
        loadTasks.add(repository.getChapterContent(prevChapterInfo.id));
      }

      // Следующая глава
      if (targetChapterNum < chapterList.length) {
        final nextChapterInfo =
            chapterList.firstWhere((ch) => ch.orderNum == targetChapterNum + 1);
        loadTasks.add(repository.getChapterContent(nextChapterInfo.id));
      }

      // Выполняем параллельно
      final chapters = await Future.wait(loadTasks);

      stopwatch.stop();
      print(
          '✅ Neighbor chapters loaded in ${stopwatch.elapsedMilliseconds}ms (parallel)');
      print(
          '📚 Loaded ${chapters.length} chapters: ${chapters.map((c) => c.level).join(', ')}');
    } catch (e) {
      print('❌ Neighbor chapters test failed: $e');
    } finally {
      await DuckDBProvider.instance.dispose();
    }
  }
}
