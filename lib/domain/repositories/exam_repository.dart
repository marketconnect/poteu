import '../entities/exam_question.dart';

abstract class ExamRepository {
  Future<List<ExamQuestion>> getQuestions(int regulationId);
}
