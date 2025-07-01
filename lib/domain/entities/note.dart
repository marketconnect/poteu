class Note {
  final int id;
  final int chapterId;
  final int? paragraphId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    required this.chapterId,
    this.paragraphId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Note copyWith({
    int? id,
    int? chapterId,
    int? paragraphId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      paragraphId: paragraphId ?? this.paragraphId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Note &&
        other.id == id &&
        other.chapterId == chapterId &&
        other.paragraphId == paragraphId &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chapterId.hashCode ^
        paragraphId.hashCode ^
        title.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Note(id: $id, chapterId: $chapterId, paragraphId: $paragraphId, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
