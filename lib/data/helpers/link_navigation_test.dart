import 'duckdb_provider.dart';
import '../repositories/static_regulation_repository.dart';
import '../../domain/entities/chapter.dart';

/// Тест для проверки корректной работы навигации по ссылкам
class LinkNavigationTest {
  static Future<void> testLinkNavigation() async {
    print('🔗 Testing link navigation...');

    try {
      await DuckDBProvider.instance.initialize();
      final repository = StaticRegulationRepository();

      // Получаем список глав
      final chapterList = await repository.getChapterList(1);
      if (chapterList.length < 3) {
        print('❌ Need at least 3 chapters for testing');
        return;
      }

      print('📚 Testing with ${chapterList.length} chapters');

      // Тест 1: Проверяем, что параграфы в разных главах имеют разные ID
      await _testParagraphIdsUniqueness(repository, chapterList);

      // Тест 2: Симулируем навигацию по ссылке
      await _testLinkNavigationSimulation(repository, chapterList);

      print('✅ Link navigation test completed!');
    } catch (e) {
      print('❌ Link navigation test failed: $e');
    } finally {
      await DuckDBProvider.instance.dispose();
    }
  }

  /// Проверяем уникальность ID параграфов в разных главах
  static Future<void> _testParagraphIdsUniqueness(
      StaticRegulationRepository repository,
      List<ChapterInfo> chapterList) async {
    print('\n🔍 Testing paragraph IDs uniqueness...');

    final Map<int, List<String>> chapterParagraphIds = {};

    // Загружаем первые 3 главы и собираем ID параграфов
    for (int i = 0; i < 3 && i < chapterList.length; i++) {
      final chapterInfo = chapterList[i];
      final chapter = await repository.getChapterContent(chapterInfo.id);

      final paragraphIds = chapter.paragraphs
          .take(5) // Берем первые 5 параграфов для теста
          .map((p) => '${p.id} (${p.num})')
          .toList();

      chapterParagraphIds[chapterInfo.orderNum] = paragraphIds;

      print('📖 Chapter ${chapterInfo.orderNum}: ${paragraphIds.join(', ')}');
    }

    // Проверяем, что ID не пересекаются между главами
    final allIds = <String>[];
    for (final ids in chapterParagraphIds.values) {
      allIds.addAll(ids);
    }

    final uniqueIds = allIds.toSet();
    if (allIds.length == uniqueIds.length) {
      print('✅ All paragraph IDs are unique across chapters');
    } else {
      print('⚠️ Found duplicate paragraph IDs across chapters');
      print('This could cause navigation issues!');
    }
  }

  /// Симулируем навигацию по ссылке
  static Future<void> _testLinkNavigationSimulation(
      StaticRegulationRepository repository,
      List<ChapterInfo> chapterList) async {
    print('\n🎯 Testing link navigation simulation...');

    // Симулируем нажатие на ссылку "1/2/1" (документ 1, глава 2, параграф 1)
    final targetChapterNum = 2;
    final targetParagraphNum = 1;

    print('🔗 Simulating link click: 1/$targetChapterNum/$targetParagraphNum');

    // Загружаем целевую главу
    final targetChapterInfo =
        chapterList.firstWhere((ch) => ch.orderNum == targetChapterNum);
    final targetChapter =
        await repository.getChapterContent(targetChapterInfo.id);

    print('📖 Loaded target chapter: ${targetChapter.title}');

    // Ищем параграф в целевой главе
    final targetParagraph = targetChapter.paragraphs
        .where((p) => p.num == targetParagraphNum)
        .firstOrNull;

    if (targetParagraph != null) {
      print(
          '✅ Found target paragraph: ${targetParagraph.num} in chapter $targetChapterNum');
      print(
          '📝 Paragraph content preview: ${targetParagraph.content.substring(0, 50)}...');
    } else {
      print(
          '❌ Target paragraph $targetParagraphNum not found in chapter $targetChapterNum');
    }

    // Проверяем, что параграф с таким же номером не существует в других главах
    print('\n🔍 Checking for duplicate paragraph numbers...');
    for (int i = 0; i < 3 && i < chapterList.length; i++) {
      if (i + 1 == targetChapterNum) continue; // Пропускаем целевую главу

      final chapterInfo = chapterList[i];
      final chapter = await repository.getChapterContent(chapterInfo.id);

      final duplicateParagraphs =
          chapter.paragraphs.where((p) => p.num == targetParagraphNum).toList();

      if (duplicateParagraphs.isNotEmpty) {
        print(
            '⚠️ Found duplicate paragraph $targetParagraphNum in chapter ${chapterInfo.orderNum}');
        print('This could cause navigation confusion!');
      } else {
        print(
            '✅ No duplicate paragraph $targetParagraphNum in chapter ${chapterInfo.orderNum}');
      }
    }
  }

  /// Тест для проверки, что навигация не переключается на неправильную главу
  static Future<void> testNavigationAccuracy() async {
    print('\n🎯 Testing navigation accuracy...');

    try {
      await DuckDBProvider.instance.initialize();
      final repository = StaticRegulationRepository();

      final chapterList = await repository.getChapterList(1);
      if (chapterList.length < 3) {
        print('❌ Need at least 3 chapters for testing');
        return;
      }

      // Загружаем главы 1, 2, 3
      final chapters = <Chapter>[];
      for (int i = 0; i < 3; i++) {
        final chapterInfo = chapterList[i];
        final chapter = await repository.getChapterContent(chapterInfo.id);
        chapters.add(chapter);
        print('📖 Loaded chapter ${chapterInfo.orderNum}: ${chapter.title}');
      }

      // Проверяем, что параграфы с одинаковыми номерами находятся в правильных главах
      for (int paragraphNum = 1; paragraphNum <= 3; paragraphNum++) {
        print('\n🔍 Checking paragraph $paragraphNum across chapters...');

        for (int chapterIndex = 0;
            chapterIndex < chapters.length;
            chapterIndex++) {
          final chapter = chapters[chapterIndex];
          final chapterNum = chapterIndex + 1;

          final paragraph = chapter.paragraphs
              .where((p) => p.num == paragraphNum)
              .firstOrNull;

          if (paragraph != null) {
            print(
                '✅ Paragraph $paragraphNum found in chapter $chapterNum (ID: ${paragraph.id})');
          } else {
            print('❌ Paragraph $paragraphNum not found in chapter $chapterNum');
          }
        }
      }
    } catch (e) {
      print('❌ Navigation accuracy test failed: $e');
    } finally {
      await DuckDBProvider.instance.dispose();
    }
  }
}
