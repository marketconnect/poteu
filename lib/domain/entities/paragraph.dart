class Paragraph {
  final int id;
  final int originalId;
  final int chapterId;
  final int num;
  final String content;
  final String? textToSpeech;
  final bool isTable;
  final bool isNft;
  final String? paragraphClass;
  final String? note;

  Paragraph({
    required this.id,
    required this.originalId,
    required this.chapterId,
    required this.num,
    required this.content,
    this.textToSpeech,
    this.isTable = false,
    this.isNft = false,
    this.paragraphClass,
    this.note,
  });

  factory Paragraph.fromMap(Map<String, dynamic> map) {
    return Paragraph(
      id: map['id'] as int,
      originalId: map['original_id'] as int,
      chapterId: map['chapter_id'] as int,
      num: map['num'] as int,
      content: map['content'] as String,
      textToSpeech: map['text_to_speech'] as String?,
      isTable: (map['is_table'] as int) == 1,
      isNft: (map['is_nft'] as int) == 1,
      paragraphClass: map['paragraph_class'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_id': originalId,
      'chapter_id': chapterId,
      'num': num,
      'content': content,
      'text_to_speech': textToSpeech,
      'is_table': isTable ? 1 : 0,
      'is_nft': isNft ? 1 : 0,
      'paragraph_class': paragraphClass,
      'note': note,
    };
  }

  Paragraph copyWith({
    int? id,
    int? originalId,
    int? chapterId,
    int? num,
    String? content,
    String? textToSpeech,
    bool? isTable,
    bool? isNft,
    String? paragraphClass,
    String? note,
  }) {
    return Paragraph(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      chapterId: chapterId ?? this.chapterId,
      num: num ?? this.num,
      content: content ?? this.content,
      textToSpeech: textToSpeech ?? this.textToSpeech,
      isTable: isTable ?? this.isTable,
      isNft: isNft ?? this.isNft,
      paragraphClass: paragraphClass ?? this.paragraphClass,
      note: note ?? this.note,
    );
  }
}

class EditableParagraph extends Paragraph {
  String editedContent;
  int edited;

  EditableParagraph({
    required super.id,
    required super.originalId,
    required super.chapterId,
    required super.num,
    required super.content,
    super.textToSpeech,
    super.isTable = false,
    super.isNft = false,
    super.paragraphClass,
    super.note,
    this.editedContent = '',
    this.edited = 0,
  });

  @override
  EditableParagraph copyWith({
    int? id,
    int? originalId,
    int? chapterId,
    int? num,
    String? content,
    String? textToSpeech,
    bool? isTable,
    bool? isNft,
    String? paragraphClass,
    String? note,
    String? editedContent,
    int? edited,
  }) {
    return EditableParagraph(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      chapterId: chapterId ?? this.chapterId,
      num: num ?? this.num,
      content: content ?? this.content,
      textToSpeech: textToSpeech ?? this.textToSpeech,
      isTable: isTable ?? this.isTable,
      isNft: isNft ?? this.isNft,
      paragraphClass: paragraphClass ?? this.paragraphClass,
      note: note ?? this.note,
      editedContent: editedContent ?? this.editedContent,
      edited: edited ?? this.edited,
    );
  }
}
