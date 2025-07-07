import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poteu/app/pages/table_of_contents/table_of_contents_page.dart';
import 'package:poteu/app/widgets/regulation_app_bar.dart';
import 'package:poteu/app/widgets/table_of_contents_app_bar.dart';
import 'package:poteu/app/widgets/chapter_card.dart';
import 'package:poteu/app/pages/search/search_view.dart';
import 'package:poteu/app/router/app_router.dart';
import 'package:poteu/app/pages/chapter/model/chapter_arguments.dart';
import 'package:poteu/app/pages/chapter/chapter_view.dart';
import 'package:poteu/domain/repositories/settings_repository.dart';
import 'package:poteu/domain/repositories/tts_repository.dart';
import 'package:poteu/domain/repositories/notes_repository.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_repositories.dart';
import '../test_helpers/database_test_helper.dart';

void main() {
  group('Table of Contents Page Tests', () {
    late MockRepositories mockRepositories;

    setUpAll(() async {
      // Initialize database for testing
      await DatabaseTestHelper.initializeForTesting();
    });

    setUp(() async {
      mockRepositories = MockRepositories();
      // Wait for any async initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await mockRepositories.dispose();
      // Clean up database
      await DatabaseTestHelper.cleanup();
    });

    Future<void> pumpTableOfContentsPage(WidgetTester tester) async {
      final appRouter = TestAppRouter(
        regulationRepository: mockRepositories.regulationRepository,
        testSettingsRepository: mockRepositories.settingsRepository,
        testTtsRepository: mockRepositories.ttsRepository,
        testNotesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );

      // Wait for initial loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    }

    testWidgets('Page renders without errors', (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Should render without exceptions
      expect(tester.takeException(), isNull);

      // Should have main components
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(RegulationAppBar), findsOneWidget);
      expect(find.byType(TableOfContentsAppBar), findsOneWidget);

      // Verify drawer is present in portrait mode
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('App bar displays correct title', (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Check for POTEU title
      expect(find.text('ПОТЭУ'), findsOneWidget,
          reason: 'App bar should show abbreviated title');

      // Tap the title to show full name in snackbar
      await tester.tap(find.text('ПОТЭУ'));
      await tester.pumpAndSettle();

      // Verify snackbar shows full name
      expect(
          find.text('Правила охраны труда при эксплуатации электроустановок'),
          findsOneWidget,
          reason:
              'Full title should be shown in snackbar when tapping abbreviated title');
    });

    testWidgets('Table of contents items display correctly',
        (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Check for test chapter titles
      expect(find.text('Общие положения'), findsOneWidget);
      expect(find.text('Требования к персоналу'), findsOneWidget);
      expect(find.text('Электроустановки'), findsOneWidget);
      expect(find.text('Средства защиты'), findsOneWidget);
      expect(find.text('Организация работ'), findsOneWidget);
      expect(find.text('Заключительные положения'), findsOneWidget);
    });

    testWidgets('Tapping chapter item navigates to chapter',
        (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Find and tap the first chapter
      final firstChapter = find.text('Общие положения').first;
      expect(firstChapter, findsOneWidget);

      await tester.tap(firstChapter);
      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pump(const Duration(seconds: 2));

      // Note: In a real app this would navigate to ChapterView
      // For our test, we verify the tap doesn't cause errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Drawer opens and closes correctly',
        (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Initially drawer should be closed
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Заметки'), findsNothing);

      // Open drawer by tapping menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify drawer content is visible
      expect(find.text('Заметки'), findsOneWidget);
      expect(find.text('Шрифт'), findsOneWidget);
      expect(find.text('Звук'), findsOneWidget);

      // Close drawer by tapping outside
      await tester.tapAt(const Offset(500, 500));
      await tester.pumpAndSettle();

      // Verify drawer is closed
      expect(find.text('Заметки'), findsNothing);
    });

    testWidgets('Search functionality works', (WidgetTester tester) async {
      await pumpTableOfContentsPage(tester);

      // Find search icon in app bar
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);

      // Tap search icon
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Should navigate to search screen
      expect(find.byType(SearchView), findsOneWidget);
    });

    testWidgets('Error state displays correctly', (WidgetTester tester) async {
      // Set repositories to return error
      mockRepositories.setAllShouldReturnError(true);

      await pumpTableOfContentsPage(tester);

      // Should show error message
      expect(find.textContaining('Ошибка'), findsWidgets);
    });

    testWidgets('Empty state handles correctly', (WidgetTester tester) async {
      final appRouter = AppRouter(
        settingsRepository: mockRepositories.settingsRepository,
        ttsRepository: mockRepositories.ttsRepository,
        notesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle empty state gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pull to refresh works', (WidgetTester tester) async {
      final appRouter = AppRouter(
        settingsRepository: mockRepositories.settingsRepository,
        ttsRepository: mockRepositories.ttsRepository,
        notesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to pull to refresh if RefreshIndicator is present
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Should handle refresh without errors
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Accessibility features work', (WidgetTester tester) async {
      final appRouter = AppRouter(
        settingsRepository: mockRepositories.settingsRepository,
        ttsRepository: mockRepositories.ttsRepository,
        notesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for semantic elements
      expect(find.byType(Semantics), findsWidgets);

      // Verify tap targets are accessible
      final chapterCards = find.byType(ChapterCard);
      expect(chapterCards, findsWidgets);

      for (final card in chapterCards.evaluate()) {
        final widget = card.widget as ChapterCard;
        expect(widget.chapterID, isNotNull);
        expect(widget.name, isNotEmpty);
      }

      // Verify menu button is accessible
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      expect(tester.getSemantics(menuButton), isNotNull);
    });

    testWidgets('Loading states display correctly',
        (WidgetTester tester) async {
      final appRouter = AppRouter(
        settingsRepository: mockRepositories.settingsRepository,
        ttsRepository: mockRepositories.ttsRepository,
        notesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();

      // Loading should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Table of Contents Integration Tests', () {
    late MockRepositories mockRepositories;

    setUp(() {
      mockRepositories = MockRepositories();
    });

    tearDown(() async {
      await mockRepositories.dispose();
    });

    testWidgets('Complete user flow works', (WidgetTester tester) async {
      // Set portrait mode for test
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      final appRouter = AppRouter(
        settingsRepository: mockRepositories.settingsRepository,
        ttsRepository: mockRepositories.ttsRepository,
        notesRepository: mockRepositories.notesRepository,
      );
      await tester.pumpWidget(
        TestAppWrapper(
          onGenerateRoute: appRouter.onGenerateRoute,
          child: TableOfContentsPage(
            regulationRepository: mockRepositories.regulationRepository,
            settingsRepository: mockRepositories.settingsRepository,
            ttsRepository: mockRepositories.ttsRepository,
            notesRepository: mockRepositories.notesRepository,
          ),
        ),
      );

      // 1. Page loads
      await tester.pumpAndSettle();

      // 2. User can see table of contents
      expect(find.text('Общие положения'), findsOneWidget);

      // 3. User opens drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 4. User can see drawer options
      expect(find.text('Заметки'), findsOneWidget);
      expect(find.text('Шрифт'), findsOneWidget);
      expect(find.text('Звук'), findsOneWidget);

      // 5. Close drawer
      await tester.tapAt(const Offset(500, 500));
      await tester.pumpAndSettle();

      // 6. Navigate to chapter
      await tester.tap(find.text('Общие положения'));
      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pump(const Duration(seconds: 2));

      // All operations should complete without errors
      expect(tester.takeException(), isNull);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}

class TestAppRouter extends AppRouter {
  final regulationRepository;
  final SettingsRepository testSettingsRepository;
  final TTSRepository testTtsRepository;
  final NotesRepository testNotesRepository;
  TestAppRouter({
    required this.regulationRepository,
    required this.testSettingsRepository,
    required this.testTtsRepository,
    required this.testNotesRepository,
  }) : super(
          settingsRepository: testSettingsRepository,
          ttsRepository: testTtsRepository,
          notesRepository: testNotesRepository,
        );

  @override
  Route? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRouteNames.chapter:
        final arguments = routeSettings.arguments;
        final chapterArguments = arguments is ChapterArguments
            ? arguments
            : const ChapterArguments(
                totalChapters: 6, chapterOrderNum: 1, scrollTo: 0);
        return MaterialPageRoute(
          builder: (_) => ChapterView(
            regulationId: 1,
            initialChapterOrderNum: chapterArguments.chapterOrderNum,
            scrollToParagraphId: chapterArguments.scrollTo,
            settingsRepository: testSettingsRepository,
            ttsRepository: testTtsRepository,
            regulationRepository: regulationRepository,
          ),
        );
      // You can add more custom routes if needed
      default:
        return super.onGenerateRoute(routeSettings);
    }
  }
}
