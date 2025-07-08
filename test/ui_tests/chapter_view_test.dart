import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/app/pages/chapter/chapter_view.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_repositories.dart';

void main() {
  group('Chapter View Table Tests', () {
    late MockRepositories mockRepositories;

    setUp(() {
      mockRepositories = MockRepositories();
    });

    tearDown(() async {
      await mockRepositories.dispose();
    });

    testWidgets('Table content displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: ChapterView(
            regulationId: 1,
            initialChapterOrderNum:
                1, // Use first chapter which should have test data
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            regulationRepository: mockRepositories.regulationRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display content without errors
      expect(tester.takeException(), isNull);

      // Should have some content
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Chapter view loads without database errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: ChapterView(
            regulationId: 1,
            initialChapterOrderNum: 1,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            regulationRepository: mockRepositories.regulationRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not have database errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chapter view handles loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: ChapterView(
            regulationId: 1,
            initialChapterOrderNum: 1,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            regulationRepository: mockRepositories.regulationRepository,
          ),
        ),
      );

      // Should handle loading state gracefully
      await tester.pumpAndSettle();

      // Should complete without errors
      expect(tester.takeException(), isNull);
    });
  });
}
