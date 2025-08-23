import '../entities/exam_question.dart';

/// Custom exception thrown when no exam is available for a given regulation.
class ExamNotFoundException implements Exception {
  final int regulationId;
  ExamNotFoundException(this.regulationId);

  @override
  String toString() => 'Exam not found for regulation ID: $regulationId';
}

abstract class ExamRepository {
  Future<List<ExamQuestion>> getQuestions(int regulationId);
}
