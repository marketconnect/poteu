import 'package:flutter/material.dart';

class EditedParagraphLink {
  final Color color;
  final String text;

  const EditedParagraphLink({
    required this.color,
    required this.text,
  });

  EditedParagraphLink copyWith({
    Color? color,
    String? text,
  }) {
    return EditedParagraphLink(
      color: color ?? this.color,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditedParagraphLink &&
        other.color == color &&
        other.text == text;
  }

  @override
  int get hashCode => color.hashCode ^ text.hashCode;
}

class Note {
  final int paragraphId;
  final int originalParagraphId;
  final int chapterId;
  final int regulationId;
  final int chapterOrderNum;
  final String regulationTitle;
  final String chapterName;
  final String content;
  final DateTime lastTouched;
  final bool isEdited;
  final EditedParagraphLink link;

  const Note({
    required this.paragraphId,
    required this.originalParagraphId,
    required this.chapterId,
    required this.regulationId,
    required this.chapterOrderNum,
    required this.regulationTitle,
    required this.chapterName,
    required this.content,
    required this.lastTouched,
    required this.isEdited,
    required this.link,
  });

  Note copyWith({
    int? paragraphId,
    int? originalParagraphId,
    int? chapterId,
    int? regulationId,
    int? chapterOrderNum,
    String? regulationTitle,
    String? chapterName,
    String? content,
    DateTime? lastTouched,
    bool? isEdited,
    EditedParagraphLink? link,
  }) {
    return Note(
      paragraphId: paragraphId ?? this.paragraphId,
      originalParagraphId: originalParagraphId ?? this.originalParagraphId,
      chapterId: chapterId ?? this.chapterId,
      regulationId: regulationId ?? this.regulationId,
      chapterOrderNum: chapterOrderNum ?? this.chapterOrderNum,
      regulationTitle: regulationTitle ?? this.regulationTitle,
      chapterName: chapterName ?? this.chapterName,
      content: content ?? this.content,
      lastTouched: lastTouched ?? this.lastTouched,
      isEdited: isEdited ?? this.isEdited,
      link: link ?? this.link,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.paragraphId == paragraphId &&
        other.originalParagraphId == originalParagraphId &&
        other.chapterId == chapterId &&
        other.regulationId == regulationId &&
        other.chapterOrderNum == chapterOrderNum &&
        other.regulationTitle == regulationTitle &&
        other.chapterName == chapterName &&
        other.content == content &&
        other.lastTouched == lastTouched &&
        other.isEdited == isEdited &&
        other.link == link;
  }

  @override
  int get hashCode {
    return paragraphId.hashCode ^
        originalParagraphId.hashCode ^
        chapterId.hashCode ^
        regulationId.hashCode ^
        chapterOrderNum.hashCode ^
        regulationTitle.hashCode ^
        chapterName.hashCode ^
        content.hashCode ^
        lastTouched.hashCode ^
        isEdited.hashCode ^
        link.hashCode;
  }

  @override
  String toString() {
    return 'Note(paragraphId: $paragraphId, originalParagraphId: $originalParagraphId, chapterId: $chapterId, regulationId: $regulationId, chapterOrderNum: $chapterOrderNum, regulationTitle: $regulationTitle, chapterName: $chapterName, content: $content, lastTouched: $lastTouched, isEdited: $isEdited, link: $link)';
  }
}
