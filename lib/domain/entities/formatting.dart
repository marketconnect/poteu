enum Tag { m, u, c }

class TextSelection {
  final int start;
  final int end;
  final String selectedText;

  TextSelection(
      {required this.start, required this.end, required this.selectedText});
}

class FormattingData {
  final Tag tag;
  final int color;
  final int start;
  final int end;

  FormattingData({
    required this.tag,
    required this.color,
    required this.start,
    required this.end,
  });
}
