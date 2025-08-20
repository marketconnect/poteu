import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/data/repositories/cloud_exam_repository.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'exam_presenter.dart';

class ExamController extends Controller {
  final int regulationId;
  final ExamPresenter _presenter;

  bool _isLoading = true;
  String? _error;
  List<ExamQuestion> _examQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  final Map<int, String> _userAnswers = {};
  bool _showResults = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ExamQuestion> get examQuestions => _examQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  ExamQuestion? get currentQuestion =>
      _examQuestions.isNotEmpty ? _examQuestions[_currentQuestionIndex] : null;
  String? get selectedAnswer => _selectedAnswer;
  bool get isAnswered => _isAnswered;
  Map<int, String> get userAnswers => _userAnswers;
  bool get showResults => _showResults;

  ExamController(this.regulationId)
      : _presenter = ExamPresenter(CloudExamRepository()) {
    initListeners();
    _presenter.getQuestions(regulationId);
  }

  @override
  void initListeners() {
    _presenter.onQuestionsLoaded = (List<ExamQuestion> questions) {
      questions.shuffle();
      _examQuestions = questions.take(10).toList();
      _isLoading = false;
      refreshUI();
    };

    _presenter.onError = (e) {
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    };
  }

  void selectAnswer(String answer) {
    if (_isAnswered) return;
    _selectedAnswer = answer;
    _isAnswered = true;
    _userAnswers[_currentQuestionIndex] = answer;
    refreshUI();
  }

  void nextQuestion() {
    if (!_isAnswered) return;

    if (_currentQuestionIndex < _examQuestions.length - 1) {
      _currentQuestionIndex++;
      _isAnswered = false;
      _selectedAnswer = null;
      refreshUI();
    } else {
      _showResults = true;
      refreshUI();
    }
  }

  void restartExam() {
    _isLoading = true;
    _error = null;
    _examQuestions = [];
    _currentQuestionIndex = 0;
    _selectedAnswer = null;
    _isAnswered = false;
    _userAnswers.clear();
    _showResults = false;
    refreshUI();
    _presenter.getQuestions(regulationId);
  }

  bool isCorrect(String answer, ExamQuestion question) {
    return question.correctAnswers.contains(answer);
  }

  int get score {
    int correct = 0;
    for (int i = 0; i < _examQuestions.length; i++) {
      if (isCorrect(_userAnswers[i] ?? '', _examQuestions[i])) {
        correct++;
      }
    }
    return correct;
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
