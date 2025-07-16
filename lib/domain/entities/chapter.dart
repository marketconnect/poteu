import 'paragraph.dart';

class ChapterInfo {
  final int id;
  final int orderNum;
  final String name;
  final int regulationId;

  ChapterInfo({
    required this.id,
    required this.orderNum,
    required this.name,
    required this.regulationId,
  });
}

class Chapter {
  final int id;
  final String num;
  final int regulationId;
  final String title;
  final String content;
  final int level;
  final List<Chapter> subChapters;
  final List<Paragraph> paragraphs;

  Chapter({
    required this.id,
    required this.num,
    required this.regulationId,
    required this.title,
    required this.content,
    required this.level,
    this.subChapters = const [],
    this.paragraphs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'num': num,
      'regulationId': regulationId,
      'title': title,
      'content': content,
      'level': level,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as int,
      num: map['num'] as String,
      regulationId: map['regulationId'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      level: map['level'] as int,
    );
  }

  Chapter copyWith({
    int? id,
    String? num,
    int? regulationId,
    String? title,
    String? content,
    int? level,
    List<Chapter>? subChapters,
    List<Paragraph>? paragraphs,
  }) {
    return Chapter(
      id: id ?? this.id,
      num: num ?? this.num,
      regulationId: regulationId ?? this.regulationId,
      title: title ?? this.title,
      content: content ?? this.content,
      level: level ?? this.level,
      subChapters: subChapters ?? this.subChapters,
      paragraphs: paragraphs ?? this.paragraphs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter &&
        other.id == id &&
        other.num == num &&
        other.regulationId == regulationId &&
        other.title == title &&
        other.content == content &&
        other.level == level;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        regulationId.hashCode ^
        title.hashCode ^
        content.hashCode ^
        level.hashCode;
  }
}
