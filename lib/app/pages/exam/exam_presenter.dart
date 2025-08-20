import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'package:poteu/domain/repositories/exam_repository.dart';
import 'package:poteu/domain/usecases/get_exam_questions_usecase.dart';

class ExamPresenter extends Presenter {
  late Function(List<ExamQuestion>) onQuestionsLoaded;
  late Function(dynamic) onError;

  final GetExamQuestionsUseCase _getExamQuestionsUseCase;

  ExamPresenter(ExamRepository repository)
      : _getExamQuestionsUseCase = GetExamQuestionsUseCase(repository);

  void getQuestions(int regulationId) {
    _getExamQuestionsUseCase.execute(
        _GetExamQuestionsObserver(this), regulationId);
  }

  @override
  void dispose() {
    _getExamQuestionsUseCase.dispose();
  }
}

class _GetExamQuestionsObserver extends Observer<List<ExamQuestion>> {
  final ExamPresenter _presenter;

  _GetExamQuestionsObserver(this._presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _presenter.onError(e);
  }

  @override
  void onNext(List<ExamQuestion>? response) {
    if (response != null) {
      _presenter.onQuestionsLoaded(response);
    }
  }
}
