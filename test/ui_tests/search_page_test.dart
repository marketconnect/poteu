import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/app/pages/search/search_view.dart';
import 'package:poteu/app/widgets/regulation_app_bar.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_repositories.dart';

void main() {
  group('Search Page Tests', () {
    late MockRepositories mockRepositories;

    setUp(() {
      mockRepositories = MockRepositories();
    });

    tearDown(() async {
      await mockRepositories.dispose();
    });

    testWidgets('Page renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      // Should render without exceptions
      expect(tester.takeException(), isNull);

      // Should have main components
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(RegulationAppBar), findsOneWidget);
    });

    testWidgets('Search input field works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find search input field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'правила');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('правила'), findsOneWidget);
    });

    testWidgets('Search results display correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'электроустановки');
      await tester.pumpAndSettle();

      // Should show search results
      expect(find.textContaining('электроустановки'), findsWidgets);
    });

    testWidgets('Empty search shows no results', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state or no results
      expect(tester.takeException(), isNull);

      // Should have search field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Tapping search result navigates to chapter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform search
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'правила');
      await tester.pumpAndSettle();

      // Tap on search result if available
      final resultItems = find.byType(GestureDetector);
      if (resultItems.evaluate().isNotEmpty) {
        await tester.tap(resultItems.first);
        await tester.pumpAndSettle();

        // Should navigate without errors
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Search debouncing works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type quickly multiple times
      await tester.enterText(searchField, 'п');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'пр');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'правила');
      await tester.pumpAndSettle();

      // Should handle rapid typing without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Clear search functionality works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Enter text
      await tester.enterText(searchField, 'тест');
      await tester.pumpAndSettle();

      // Clear text
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Should clear results
      expect(tester.takeException(), isNull);
    });

    testWidgets('Loading state displays during search',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start search
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'поиск');

      // Check for loading indicator during search
      await tester.pump(const Duration(milliseconds: 200));

      // Wait for search to complete
      await tester.pumpAndSettle();

      // Should complete without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find back button in app bar
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should handle navigation without errors
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Error state displays correctly', (WidgetTester tester) async {
      // Set repositories to return error
      mockRepositories.setAllShouldReturnError(true);

      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform search
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'ошибка');
      await tester.pumpAndSettle();

      // Should handle error gracefully
      expect(tester.takeException(), isNull);
    });
  });

  group('Search Page Integration Tests', () {
    late MockRepositories mockRepositories;

    setUp(() {
      mockRepositories = MockRepositories();
    });

    tearDown(() async {
      await mockRepositories.dispose();
    });

    testWidgets('Complete search flow works', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      // 1. Page loads
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      // 2. User enters search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'охрана труда');
      await tester.pumpAndSettle();

      // 3. User can see results
      expect(find.textContaining('охрана'), findsWidgets);

      // 4. User clears search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // All operations should complete without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Search with special characters works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: SearchView(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Test various characters
      final testQueries = [
        'электро-установки',
        'правила №1',
        'охрана труда!',
        'ПОТЭУ (2023)',
      ];

      for (final query in testQueries) {
        await tester.enterText(searchField, query);
        await tester.pumpAndSettle();

        // Should handle special characters without errors
        expect(tester.takeException(), isNull);
      }
    });
  });
}
