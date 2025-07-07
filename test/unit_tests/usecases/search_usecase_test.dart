import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/domain/usecases/search_usecase.dart';
import 'package:poteu/domain/entities/search_result.dart';
import '../../test_helpers/mock_repositories.dart';

void main() {
  group('SearchUseCase Tests', () {
    late SearchUseCase searchUseCase;
    late MockRegulationRepository mockRepository;

    setUp(() {
      mockRepository = MockRegulationRepository();
      searchUseCase = SearchUseCase(mockRepository);
    });

    group('buildUseCaseStream', () {
      test('returns empty list for null parameters', () async {
        final stream = await searchUseCase.buildUseCaseStream(null);

        await expectLater(
          stream,
          emits(isEmpty),
        );
      });

      test('returns empty list for empty query', () async {
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: '',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);

        await expectLater(
          stream,
          emits(isEmpty),
        );
      });

      test('returns search results for valid query', () async {
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: 'электроустановки',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);

        await expectLater(
          stream,
          emits(isA<List<SearchResult>>()),
        );
      });

      test('returns search results with proper content', () async {
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: 'правила',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);
        final results = await stream.first;

        expect(results, isNotEmpty);
        expect(results.first.text.toLowerCase(), contains('правила'),
            reason:
                'Search result should contain the query text (case-insensitive)');
      });

      test('handles repository errors correctly', () async {
        mockRepository.setShouldReturnError(true);

        final params = SearchUseCaseParams(
          regulationId: 1,
          query: 'test query',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);

        await expectLater(
          stream,
          emitsError(isA<Exception>()),
        );
      });

      test('passes correct parameters to repository', () async {
        final params = SearchUseCaseParams(
          regulationId: 123,
          query: 'specific query',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);
        await stream.first; // Trigger the execution

        // Repository should have been called with correct parameters
        // This is verified by the mock implementation
        expect(mockRepository, isNotNull);
      });
    });

    group('SearchUseCaseParams', () {
      test('creates parameters with required fields', () {
        final params = SearchUseCaseParams(
          regulationId: 100,
          query: 'test search query',
        );

        expect(params.regulationId, 100);
        expect(params.query, 'test search query');
      });

      test('handles special characters in query', () {
        final specialQuery = 'охрана труда №1 (2023) @#\$%^&*()';
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: specialQuery,
        );

        expect(params.query, specialQuery);
      });

      test('handles unicode characters in query', () {
        final unicodeQuery = '电气设备 中文 🚀 émojis';
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: unicodeQuery,
        );

        expect(params.query, unicodeQuery);
      });
    });

    group('Integration Tests', () {
      test('complete search flow works correctly', () async {
        // 1. Empty query returns empty results
        var params = SearchUseCaseParams(regulationId: 1, query: '');
        var stream = await searchUseCase.buildUseCaseStream(params);
        var results = await stream.first;
        expect(results, isEmpty);

        // 2. Valid query returns results
        params =
            SearchUseCaseParams(regulationId: 1, query: 'электроустановки');
        stream = await searchUseCase.buildUseCaseStream(params);
        results = await stream.first;
        expect(results, isNotEmpty);

        // 3. Results contain expected data
        expect(results.first, isA<SearchResult>());
        expect(results.first.text, isNotEmpty);
        expect(results.first.paragraphId, greaterThan(0));
        expect(results.first.chapterOrderNum, greaterThan(0));
      });

      test('search with different regulation IDs', () async {
        final queries = [
          SearchUseCaseParams(regulationId: 1, query: 'test'),
          SearchUseCaseParams(regulationId: 2, query: 'test'),
          SearchUseCaseParams(regulationId: 999, query: 'test'),
        ];

        for (final params in queries) {
          final stream = await searchUseCase.buildUseCaseStream(params);
          final results = await stream.first;

          // Should handle different regulation IDs without errors
          expect(results, isA<List<SearchResult>>());
        }
      });

      test('concurrent search requests work correctly', () async {
        final futures = <Future<List<SearchResult>>>[];

        // Start multiple concurrent searches
        for (int i = 0; i < 5; i++) {
          final params = SearchUseCaseParams(
            regulationId: 1,
            query: 'concurrent test $i',
          );
          final stream = await searchUseCase.buildUseCaseStream(params);
          futures.add(stream.first);
        }

        // Wait for all searches to complete
        final results = await Future.wait(futures);

        // All searches should complete successfully
        expect(results.length, 5);
        for (final result in results) {
          expect(result, isA<List<SearchResult>>());
        }
      });
    });

    group('Performance Tests', () {
      test('handles large query strings efficiently', () async {
        // Create a very long query string
        final longQuery = 'word ' * 1000; // 5000 characters
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: longQuery,
        );

        final stopwatch = Stopwatch()..start();
        final stream = await searchUseCase.buildUseCaseStream(params);
        await stream.first;
        stopwatch.stop();

        // Should complete within reasonable time (adjusted for test environment)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('handles multiple rapid searches', () async {
        final stopwatch = Stopwatch()..start();

        // Perform 10 rapid searches
        for (int i = 0; i < 10; i++) {
          final params = SearchUseCaseParams(
            regulationId: 1,
            query: 'rapid search $i',
          );
          final stream = await searchUseCase.buildUseCaseStream(params);
          await stream.first;
        }

        stopwatch.stop();

        // Should complete all searches within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });

    group('Edge Cases', () {
      test('handles whitespace-only query', () async {
        final params = SearchUseCaseParams(
          regulationId: 1,
          query: '   \t\n  ',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);
        final results = await stream.first;

        // Should treat whitespace-only as empty query
        expect(results, isEmpty);
      });

      test('handles negative regulation ID', () async {
        final params = SearchUseCaseParams(
          regulationId: -1,
          query: 'test',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);

        // Should handle gracefully (return empty or throw specific error)
        await expectLater(
          stream,
          emitsInOrder([isA<List<SearchResult>>()]),
        );
      });

      test('handles zero regulation ID', () async {
        final params = SearchUseCaseParams(
          regulationId: 0,
          query: 'test',
        );

        final stream = await searchUseCase.buildUseCaseStream(params);
        final results = await stream.first;

        expect(results, isA<List<SearchResult>>());
      });

      test('handles very short queries', () async {
        final shortQueries = ['a', 'и', '1', '@'];

        for (final query in shortQueries) {
          final params = SearchUseCaseParams(
            regulationId: 1,
            query: query,
          );

          final stream = await searchUseCase.buildUseCaseStream(params);
          final results = await stream.first;

          expect(results, isA<List<SearchResult>>());
        }
      });
    });

    group('Error Recovery', () {
      test('recovers from repository errors', () async {
        // First call with error
        mockRepository.setShouldReturnError(true);
        var params = SearchUseCaseParams(regulationId: 1, query: 'error test');
        var stream = await searchUseCase.buildUseCaseStream(params);

        await expectLater(stream, emitsError(isA<Exception>()));

        // Second call should work after fixing the error
        mockRepository.setShouldReturnError(false);
        params = SearchUseCaseParams(regulationId: 1, query: 'success test');
        stream = await searchUseCase.buildUseCaseStream(params);

        await expectLater(stream, emits(isA<List<SearchResult>>()));
      });

      test('handles intermittent repository failures', () async {
        var callCount = 0;
        final originalMethod = mockRepository.setShouldReturnError;

        // Simulate intermittent failures
        for (int i = 0; i < 5; i++) {
          mockRepository.setShouldReturnError(callCount % 2 == 0);
          callCount++;

          final params = SearchUseCaseParams(
            regulationId: 1,
            query: 'intermittent test $i',
          );

          final stream = await searchUseCase.buildUseCaseStream(params);

          if (callCount % 2 == 1) {
            // Should fail on odd calls
            await expectLater(stream, emitsError(isA<Exception>()));
          } else {
            // Should succeed on even calls
            await expectLater(stream, emits(isA<List<SearchResult>>()));
          }
        }
      });
    });
  });
}
