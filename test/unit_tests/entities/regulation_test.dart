import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/domain/entities/regulation.dart';
import 'package:poteu/domain/entities/chapter.dart';

void main() {
  group('Regulation Entity Tests', () {
    late Regulation testRegulation;
    late List<Chapter> testChapters;

    setUp(() {
      testChapters = [
        Chapter(
          id: 1,
          regulationId: 1,
          title: 'Test Chapter 1',
          content: '<p>Content 1</p>',
          level: 1,
        ),
        Chapter(
          id: 2,
          regulationId: 1,
          title: 'Test Chapter 2',
          content: '<p>Content 2</p>',
          level: 2,
        ),
      ];

      testRegulation = Regulation(
        id: 1,
        title: 'ПОТЭУ',
        description: 'Правила охраны труда при эксплуатации электроустановок',
        lastUpdated: DateTime(2023, 12, 1),
        isDownloaded: true,
        isFavorite: false,
        chapters: testChapters,
      );
    });

    group('Constructor and Properties', () {
      test('creates regulation with all required properties', () {
        expect(testRegulation.id, 1);
        expect(testRegulation.title, 'ПОТЭУ');
        expect(testRegulation.description,
            'Правила охраны труда при эксплуатации электроустановок');
        expect(testRegulation.lastUpdated, DateTime(2023, 12, 1));
        expect(testRegulation.isDownloaded, true);
        expect(testRegulation.isFavorite, false);
        expect(testRegulation.chapters, testChapters);
      });

      test('regulation is immutable', () {
        // Regulation should be immutable - properties should be final
        expect(testRegulation.id, 1);
        // Cannot modify properties due to final keyword
      });
    });

    group('copyWith Method', () {
      test('returns same regulation when no parameters provided', () {
        final copied = testRegulation.copyWith();

        expect(copied.id, testRegulation.id);
        expect(copied.title, testRegulation.title);
        expect(copied.description, testRegulation.description);
        expect(copied.lastUpdated, testRegulation.lastUpdated);
        expect(copied.isDownloaded, testRegulation.isDownloaded);
        expect(copied.isFavorite, testRegulation.isFavorite);
        expect(copied.chapters, testRegulation.chapters);
      });

      test('updates specific properties correctly', () {
        final copied = testRegulation.copyWith(
          title: 'New Title',
          isFavorite: true,
          isDownloaded: false,
        );

        expect(copied.title, 'New Title');
        expect(copied.isFavorite, true);
        expect(copied.isDownloaded, false);
        // Other properties should remain unchanged
        expect(copied.id, testRegulation.id);
        expect(copied.description, testRegulation.description);
        expect(copied.lastUpdated, testRegulation.lastUpdated);
      });

      test('updates all properties when provided', () {
        final newDate = DateTime(2024, 1, 1);
        final newChapters = [
          Chapter(
            id: 3,
            regulationId: 2,
            title: 'New Chapter',
            content: '<p>New Content</p>',
            level: 1,
          ),
        ];

        final copied = testRegulation.copyWith(
          id: 2,
          title: 'New ПОТЭУ',
          description: 'New Description',
          lastUpdated: newDate,
          isDownloaded: false,
          isFavorite: true,
          chapters: newChapters,
        );

        expect(copied.id, 2);
        expect(copied.title, 'New ПОТЭУ');
        expect(copied.description, 'New Description');
        expect(copied.lastUpdated, newDate);
        expect(copied.isDownloaded, false);
        expect(copied.isFavorite, true);
        expect(copied.chapters, newChapters);
      });
    });

    group('Equality and HashCode', () {
      test('equals returns true for identical regulations', () {
        final identical = Regulation(
          id: 1,
          title: 'ПОТЭУ',
          description: 'Правила охраны труда при эксплуатации электроустановок',
          lastUpdated: DateTime(2023, 12, 1),
          isDownloaded: true,
          isFavorite: false,
          chapters: testChapters,
        );

        expect(testRegulation == identical, true);
        expect(testRegulation.hashCode == identical.hashCode, true);
      });

      test('equals returns false for different regulations', () {
        final different = testRegulation.copyWith(title: 'Different Title');

        expect(testRegulation == different, false);
        expect(testRegulation.hashCode == different.hashCode, false);
      });

      test('equals returns false for different types', () {
        // Using proper type checks to avoid linter warnings
        expect(testRegulation.runtimeType == String, false);
        expect(testRegulation.runtimeType == int, false);

        // Test with actual objects of different types
        const stringValue = 'string';
        const intValue = 123;

        expect(testRegulation == stringValue, false);
        expect(testRegulation == intValue, false);
      });

      test('equals handles all property differences', () {
        expect(testRegulation == testRegulation.copyWith(id: 2), false);
        expect(testRegulation == testRegulation.copyWith(title: 'Different'),
            false);
        expect(
            testRegulation == testRegulation.copyWith(description: 'Different'),
            false);
        expect(
            testRegulation ==
                testRegulation.copyWith(lastUpdated: DateTime(2024, 1, 1)),
            false);
        expect(testRegulation == testRegulation.copyWith(isDownloaded: false),
            false);
        expect(
            testRegulation == testRegulation.copyWith(isFavorite: true), false);
      });

      test('identical objects have same hash code', () {
        final regulation1 = Regulation(
          id: 1,
          title: 'Test',
          description: 'Test Description',
          lastUpdated: DateTime(2023, 1, 1),
          isDownloaded: true,
          isFavorite: false,
          chapters: [],
        );

        final regulation2 = Regulation(
          id: 1,
          title: 'Test',
          description: 'Test Description',
          lastUpdated: DateTime(2023, 1, 1),
          isDownloaded: true,
          isFavorite: false,
          chapters: [],
        );

        expect(regulation1.hashCode, regulation2.hashCode);
      });
    });

    group('toString Method', () {
      test('returns properly formatted string representation', () {
        final stringRepresentation = testRegulation.toString();

        expect(stringRepresentation, contains('Regulation('));
        expect(stringRepresentation, contains('id: 1'));
        expect(stringRepresentation, contains('title: ПОТЭУ'));
        expect(
            stringRepresentation,
            contains(
                'description: Правила охраны труда при эксплуатации электроустановок'));
        expect(stringRepresentation,
            contains('lastUpdated: 2023-12-01 00:00:00.000'));
        expect(stringRepresentation, contains('isDownloaded: true'));
        expect(stringRepresentation, contains('isFavorite: false'));
        expect(stringRepresentation, contains('chapters: 2'));
      });

      test('toString includes chapter count', () {
        final emptyRegulation = testRegulation.copyWith(chapters: []);
        expect(emptyRegulation.toString(), contains('chapters: 0'));

        final singleChapterRegulation =
            testRegulation.copyWith(chapters: [testChapters.first]);
        expect(singleChapterRegulation.toString(), contains('chapters: 1'));
      });
    });

    group('Edge Cases', () {
      test('handles empty chapters list', () {
        final emptyRegulation = testRegulation.copyWith(chapters: []);

        expect(emptyRegulation.chapters, isEmpty);
        expect(emptyRegulation.toString(), contains('chapters: 0'));
      });

      test('handles special characters in text fields', () {
        final specialRegulation = testRegulation.copyWith(
          title: 'Title with 中文 and émojis 🚀',
          description: 'Description with special chars: @#\$%^&*()',
        );

        expect(specialRegulation.title, 'Title with 中文 and émojis 🚀');
        expect(specialRegulation.description,
            'Description with special chars: @#\$%^&*()');
      });

      test('handles extreme dates', () {
        final futureDate = DateTime(2100, 12, 31);
        final pastDate = DateTime(1900, 1, 1);

        final futureRegulation =
            testRegulation.copyWith(lastUpdated: futureDate);
        final pastRegulation = testRegulation.copyWith(lastUpdated: pastDate);

        expect(futureRegulation.lastUpdated, futureDate);
        expect(pastRegulation.lastUpdated, pastDate);
      });
    });

    group('Business Logic', () {
      test('favorite toggle logic works correctly', () {
        expect(testRegulation.isFavorite, false);

        final favorited = testRegulation.copyWith(isFavorite: true);
        expect(favorited.isFavorite, true);

        final unfavorited = favorited.copyWith(isFavorite: false);
        expect(unfavorited.isFavorite, false);
      });

      test('download state logic works correctly', () {
        expect(testRegulation.isDownloaded, true);

        final notDownloaded = testRegulation.copyWith(isDownloaded: false);
        expect(notDownloaded.isDownloaded, false);

        final downloaded = notDownloaded.copyWith(isDownloaded: true);
        expect(downloaded.isDownloaded, true);
      });

      test('can be both favorite and downloaded', () {
        final regulation = testRegulation.copyWith(
          isFavorite: true,
          isDownloaded: true,
        );

        expect(regulation.isFavorite, true);
        expect(regulation.isDownloaded, true);
      });
    });
  });
}
