import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/exam_question.dart';
import '../repositories/exam_repository.dart';

class GetExamQuestionsUseCase extends UseCase<List<ExamQuestion>, int> {
  final ExamRepository _repository;

  GetExamQuestionsUseCase(this._repository);

  @override
  Future<Stream<List<ExamQuestion>>> buildUseCaseStream(int? params) async {
    final controller = StreamController<List<ExamQuestion>>();
    try {
      if (params == null) {
        throw ArgumentError("regulationId cannot be null");
      }
      final questions = await _repository.getQuestions(params);
      controller.add(questions);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
