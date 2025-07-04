class SearchResult {
  final int chapterId;
  final int chapterOrderNum;
  final String chapterTitle;
  final int paragraphId;
  final String paragraphContent;
  final String highlightedText;

  SearchResult({
    required this.chapterId,
    required this.chapterOrderNum,
    required this.chapterTitle,
    required this.paragraphId,
    required this.paragraphContent,
    required this.highlightedText,
  });
}
