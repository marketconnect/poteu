import 'chapter.dart';

class Regulation {
  final int id;
  final String title;
  final String description;
  final DateTime lastUpdated;
  final bool isDownloaded;
  final bool isFavorite;
  final bool isPremium;
  final List<Chapter> chapters;

  const Regulation({
    required this.id,
    required this.title,
    required this.description,
    required this.lastUpdated,
    required this.isDownloaded,
    required this.isFavorite,
    this.isPremium = false,
    required this.chapters,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDownloaded': isDownloaded,
      'isFavorite': isFavorite,
      'isPremium': isPremium,
    };
  }

  factory Regulation.fromJson(Map<String, dynamic> json) {
    return Regulation(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isDownloaded: json['isDownloaded'] as bool,
      isFavorite: json['isFavorite'] as bool,
      isPremium: json['isPremium'] as bool,
      chapters: const [], // Cloud regulations don't have chapters in this context
    );
  }
  Regulation copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? lastUpdated,
    bool? isDownloaded,
    bool? isFavorite,
    bool? isPremium,
    List<Chapter>? chapters,
  }) {
    return Regulation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      isPremium: isPremium ?? this.isPremium,
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
        other.isFavorite == isFavorite &&
        other.isPremium == isPremium;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        lastUpdated.hashCode ^
        isDownloaded.hashCode ^
        isFavorite.hashCode ^
        isPremium.hashCode;
  }

  @override
  String toString() {
    return 'Regulation(id: $id, title: $title, description: $description, lastUpdated: $lastUpdated, isDownloaded: $isDownloaded, isFavorite: $isFavorite, isPremium: $isPremium, chapters: ${chapters.length})';
  }
}
