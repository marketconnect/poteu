class SearchResult {
  final int id;
  final int regulationId;
  final String? regulationTitle;
  final int paragraphId;
  final int chapterOrderNum;
  final String text;
  final int matchStart;
  final int matchEnd;

  SearchResult({
    required this.id,
    required this.regulationId,
    this.regulationTitle,
    required this.paragraphId,
    required this.chapterOrderNum,
    required this.text,
    required this.matchStart,
    required this.matchEnd,
  });
}