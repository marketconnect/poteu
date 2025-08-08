import 'chapter.dart';

class Regulation {
  final int id;
  final String title;
  final String description;
  final String sourceName;
  final String sourceUrl;
  final DateTime lastUpdated;
  final bool isDownloaded;
  final bool isFavorite;
  final bool isPremium;
  final List<Chapter> chapters;

  const Regulation({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceName,
    required this.sourceUrl,
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
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
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
      sourceName: json['sourceName'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
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
    String? sourceName,
    String? sourceUrl,
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
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
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
        other.sourceName == sourceName &&
        other.sourceUrl == sourceUrl &&
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
        sourceName.hashCode ^
        sourceUrl.hashCode ^
        lastUpdated.hashCode ^
        isDownloaded.hashCode ^
        isFavorite.hashCode ^
        isPremium.hashCode;
  }

  @override
  String toString() {
    return 'Regulation(id: $id, title: $title, description: $description, sourceName: $sourceName, sourceUrl: $sourceUrl, lastUpdated: $lastUpdated, isDownloaded: $isDownloaded, isFavorite: $isFavorite, isPremium: $isPremium, chapters: ${chapters.length})';
  }
}
