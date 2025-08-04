class ChapterArguments {
  final int totalChapters, chapterOrderNum, scrollTo, regulationId;

  const ChapterArguments(
      {required this.totalChapters,
      required this.chapterOrderNum,
      required this.scrollTo,
      this.regulationId = 0});
}
