import 'chapter.dart';

class Regulation {
  final int id;
  final String title;
  final String description;
  final DateTime lastUpdated;
  final bool isDownloaded;
  final bool isFavorite;
  final List<Chapter> chapters;

  const Regulation({
    required this.id,
    required this.title,
    required this.description,
    required this.lastUpdated,
    required this.isDownloaded,
    required this.isFavorite,
    required this.chapters,
  });

  Regulation copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? lastUpdated,
    bool? isDownloaded,
    bool? isFavorite,
    List<Chapter>? chapters,
  }) {
    return Regulation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      chapters: chapters ?? this.chapters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Regulation &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.lastUpdated == lastUpdated &&
        other.isDownloaded == isDownloaded &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        lastUpdated.hashCode ^
        isDownloaded.hashCode ^
        isFavorite.hashCode;
  }

  @override
  String toString() {
    return 'Regulation(id: $id, title: $title, description: $description, lastUpdated: $lastUpdated, isDownloaded: $isDownloaded, isFavorite: $isFavorite, chapters: ${chapters.length})';
  }
}
