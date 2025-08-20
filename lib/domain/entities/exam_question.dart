class ExamQuestion {
  final String name;
  final Question question;
  final List<String> answers;
  final List<String> correctAnswers;

  ExamQuestion({
    required this.name,
    required this.question,
    required this.answers,
    required this.correctAnswers,
  });

  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    final questionMap = map['question'] as Map<String, dynamic>;
    final answersList = (map['answers'] as List).cast<String>();
    final correctAnswersList = (map['correctAnswers'] as List).cast<String>();

    return ExamQuestion(
      name: map['name'] as String,
      question: Question.fromMap(questionMap),
      answers: answersList,
      correctAnswers: correctAnswersList,
    );
  }
}

class Question {
  final String text;
  final String? imageBase64;

  Question({
    required this.text,
    this.imageBase64,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] as String,
      imageBase64: map['imageBase64'] as String?,
    );
  }
}
