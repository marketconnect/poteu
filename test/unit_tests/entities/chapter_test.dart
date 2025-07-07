import 'package:flutter_test/flutter_test.dart';
import 'package:poteu/domain/entities/chapter.dart';
import 'package:poteu/domain/entities/paragraph.dart';

void main() {
  group('Chapter Entity Tests', () {
    late Chapter testChapter;
    late List<Paragraph> testParagraphs;

    setUp(() {
      testParagraphs = [
        Paragraph(
          id: 1,
          originalId: 1,
          chapterId: 1,
          num: 1,
          content: 'Test paragraph content',
          textToSpeech: 'Test paragraph text to speech',
          isTable: false,
          isNft: false,
          paragraphClass: 'paragraph',
        ),
      ];

      testChapter = Chapter(
        id: 1,
        regulationId: 1,
        title: 'Test Chapter',
        content: '<p>Test chapter content</p>',
        level: 1,
        subChapters: [],
        paragraphs: testParagraphs,
      );
    });

    group('Constructor and Properties', () {
      test('creates chapter with all required properties', () {
        expect(testChapter.id, 1);
        expect(testChapter.regulationId, 1);
        expect(testChapter.title, 'Test Chapter');
        expect(testChapter.content, '<p>Test chapter content</p>');
        expect(testChapter.level, 1);
        expect(testChapter.subChapters, isEmpty);
        expect(testChapter.paragraphs, testParagraphs);
      });

      test('creates chapter with default empty collections', () {
        final chapter = Chapter(
          id: 2,
          regulationId: 1,
          title: 'Simple Chapter',
          content: '<p>Simple content</p>',
          level: 2,
        );

        expect(chapter.subChapters, isEmpty);
        expect(chapter.paragraphs, isEmpty);
      });
    });

    group('toMap Method', () {
      test('converts chapter to map correctly', () {
        final map = testChapter.toMap();

        expect(map['id'], 1);
        expect(map['regulationId'], 1);
        expect(map['title'], 'Test Chapter');
        expect(map['content'], '<p>Test chapter content</p>');
        expect(map['level'], 1);
      });

      test('map contains all required fields', () {
        final map = testChapter.toMap();

        expect(map, containsPair('id', 1));
        expect(map, containsPair('regulationId', 1));
        expect(map, containsPair('title', 'Test Chapter'));
        expect(map, containsPair('content', '<p>Test chapter content</p>'));
        expect(map, containsPair('level', 1));
      });

      test('handles special characters in content', () {
        final specialChapter = testChapter.copyWith(
          title: 'Chapter with 中文 émojis 🚀',
          content: '<p>Content with special chars: @#\$%^&*()</p>',
        );

        final map = specialChapter.toMap();
        expect(map['title'], 'Chapter with 中文 émojis 🚀');
        expect(map['content'], '<p>Content with special chars: @#\$%^&*()</p>');
      });
    });

    group('fromMap Method', () {
      test('creates chapter from map correctly', () {
        final map = {
          'id': 2,
          'regulationId': 3,
          'title': 'Mapped Chapter',
          'content': '<p>Mapped content</p>',
          'level': 2,
        };

        final chapter = Chapter.fromMap(map);

        expect(chapter.id, 2);
        expect(chapter.regulationId, 3);
        expect(chapter.title, 'Mapped Chapter');
        expect(chapter.content, '<p>Mapped content</p>');
        expect(chapter.level, 2);
        expect(chapter.subChapters, isEmpty);
        expect(chapter.paragraphs, isEmpty);
      });

      test('handles missing optional fields', () {
        final map = {
          'id': 3,
          'regulationId': 4,
          'title': 'Basic Chapter',
          'content': '<p>Basic content</p>',
          'level': 1,
        };

        final chapter = Chapter.fromMap(map);
        expect(chapter.subChapters, isEmpty);
        expect(chapter.paragraphs, isEmpty);
      });

      test('throws on missing required fields', () {
        final invalidMap = <String, dynamic>{
          'id': 1,
          // Missing required fields
        };

        expect(() => Chapter.fromMap(invalidMap), throwsA(isA<TypeError>()));
      });
    });

    group('copyWith Method', () {
      test('returns same chapter when no parameters provided', () {
        final copied = testChapter.copyWith();

        expect(copied.id, testChapter.id);
        expect(copied.regulationId, testChapter.regulationId);
        expect(copied.title, testChapter.title);
        expect(copied.content, testChapter.content);
        expect(copied.level, testChapter.level);
        expect(copied.subChapters, testChapter.subChapters);
        expect(copied.paragraphs, testChapter.paragraphs);
      });

      test('updates specific properties correctly', () {
        final newSubChapters = [
          Chapter(
            id: 10,
            regulationId: 1,
            title: 'Sub Chapter',
            content: '<p>Sub content</p>',
            level: 2,
          ),
        ];

        final copied = testChapter.copyWith(
          title: 'Updated Title',
          level: 3,
          subChapters: newSubChapters,
        );

        expect(copied.title, 'Updated Title');
        expect(copied.level, 3);
        expect(copied.subChapters, newSubChapters);
        // Other properties should remain unchanged
        expect(copied.id, testChapter.id);
        expect(copied.regulationId, testChapter.regulationId);
        expect(copied.content, testChapter.content);
        expect(copied.paragraphs, testChapter.paragraphs);
      });

      test('updates all properties when provided', () {
        final newParagraphs = [
          Paragraph(
            id: 100,
            originalId: 100,
            chapterId: 5,
            num: 1,
            content: 'New paragraph content',
          ),
        ];

        final copied = testChapter.copyWith(
          id: 5,
          regulationId: 10,
          title: 'Completely New Chapter',
          content: '<p>Completely new content</p>',
          level: 5,
          subChapters: [],
          paragraphs: newParagraphs,
        );

        expect(copied.id, 5);
        expect(copied.regulationId, 10);
        expect(copied.title, 'Completely New Chapter');
        expect(copied.content, '<p>Completely new content</p>');
        expect(copied.level, 5);
        expect(copied.subChapters, isEmpty);
        expect(copied.paragraphs, newParagraphs);
      });
    });

    group('Equality and HashCode', () {
      test('equals returns true for identical chapters', () {
        final identical = Chapter(
          id: 1,
          regulationId: 1,
          title: 'Test Chapter',
          content: '<p>Test chapter content</p>',
          level: 1,
          subChapters: [],
          paragraphs: testParagraphs,
        );

        expect(testChapter == identical, true);
        expect(testChapter.hashCode == identical.hashCode, true);
      });

      test('equals returns false for different chapters', () {
        final different = testChapter.copyWith(title: 'Different Title');

        expect(testChapter == different, false);
        expect(testChapter.hashCode == different.hashCode, false);
      });

      test('equals handles all property differences', () {
        expect(testChapter == testChapter.copyWith(id: 2), false);
        expect(testChapter == testChapter.copyWith(regulationId: 2), false);
        expect(testChapter == testChapter.copyWith(title: 'Different'), false);
        expect(
            testChapter == testChapter.copyWith(content: 'Different'), false);
        expect(testChapter == testChapter.copyWith(level: 2), false);
      });

      test('identical objects have same hash code', () {
        final chapter1 = Chapter(
          id: 1,
          regulationId: 1,
          title: 'Test',
          content: '<p>Test</p>',
          level: 1,
        );

        final chapter2 = Chapter(
          id: 1,
          regulationId: 1,
          title: 'Test',
          content: '<p>Test</p>',
          level: 1,
        );

        expect(chapter1.hashCode, chapter2.hashCode);
      });
    });

    group('Business Logic', () {
      test('chapter hierarchy levels work correctly', () {
        final parentChapter = Chapter(
          id: 1,
          regulationId: 1,
          title: 'Parent Chapter',
          content: '<p>Parent content</p>',
          level: 1,
        );

        final childChapter = Chapter(
          id: 2,
          regulationId: 1,
          title: 'Child Chapter',
          content: '<p>Child content</p>',
          level: 2,
        );

        expect(childChapter.level > parentChapter.level, true);
      });

      test('sub-chapters can be added and managed', () {
        final subChapter1 = Chapter(
          id: 2,
          regulationId: 1,
          title: 'Sub Chapter 1',
          content: '<p>Sub content 1</p>',
          level: 2,
        );

        final subChapter2 = Chapter(
          id: 3,
          regulationId: 1,
          title: 'Sub Chapter 2',
          content: '<p>Sub content 2</p>',
          level: 2,
        );

        final chapterWithSubs = testChapter.copyWith(
          subChapters: [subChapter1, subChapter2],
        );

        expect(chapterWithSubs.subChapters.length, 2);
        expect(chapterWithSubs.subChapters.contains(subChapter1), true);
        expect(chapterWithSubs.subChapters.contains(subChapter2), true);
      });

      test('paragraphs can be added and managed', () {
        final paragraph1 = Paragraph(
          id: 1,
          originalId: 1,
          chapterId: 1,
          num: 1,
          content: 'First paragraph',
        );

        final paragraph2 = Paragraph(
          id: 2,
          originalId: 2,
          chapterId: 1,
          num: 2,
          content: 'Second paragraph',
        );

        final chapterWithParagraphs = testChapter.copyWith(
          paragraphs: [paragraph1, paragraph2],
        );

        expect(chapterWithParagraphs.paragraphs.length, 2);
        expect(chapterWithParagraphs.paragraphs.first.num, 1);
        expect(chapterWithParagraphs.paragraphs.last.num, 2);
      });
    });

    group('Edge Cases', () {
      test('handles empty content', () {
        final emptyChapter = testChapter.copyWith(
          title: '',
          content: '',
        );

        expect(emptyChapter.title, '');
        expect(emptyChapter.content, '');
      });

      test('handles extreme level values', () {
        final deepChapter = testChapter.copyWith(level: 10);
        final rootChapter = testChapter.copyWith(level: 0);

        expect(deepChapter.level, 10);
        expect(rootChapter.level, 0);
      });

      test('handles HTML content correctly', () {
        final htmlChapter = testChapter.copyWith(
          content:
              '<div><p>Complex <strong>HTML</strong> content with <em>formatting</em></p></div>',
        );

        expect(htmlChapter.content, contains('<div>'));
        expect(htmlChapter.content, contains('<strong>'));
        expect(htmlChapter.content, contains('<em>'));
      });
    });
  });

  group('ChapterInfo Tests', () {
    test('creates chapter info with all properties', () {
      final chapterInfo = ChapterInfo(
        id: 1,
        orderNum: 5,
        name: 'Chapter Info Name',
        regulationId: 10,
      );

      expect(chapterInfo.id, 1);
      expect(chapterInfo.orderNum, 5);
      expect(chapterInfo.name, 'Chapter Info Name');
      expect(chapterInfo.regulationId, 10);
    });
  });
}
