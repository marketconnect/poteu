import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/data/repositories/cloud_exam_repository.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'package:flutter/foundation.dart';
import 'exam_presenter.dart';

class ExamController extends Controller {
  final int regulationId;
  final ExamPresenter _presenter;

  bool _isLoading = true;
  String? _error;
  List<ExamQuestion> _allQuestions = [];
  List<ExamQuestion> _examQuestions = [];
  List<String> _availableGroups = [];
  int _currentQuestionIndex = 0;
  final Set<String> _selectedAnswers = {};
  bool _isConfirmed = false;
  final Map<int, Set<String>> _userAnswers = {};
  bool _showResults = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get availableGroups => _availableGroups;
  String? _selectedGroup;
  List<ExamQuestion> get examQuestions => _examQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  ExamQuestion? get currentQuestion =>
      _examQuestions.isNotEmpty ? _examQuestions[_currentQuestionIndex] : null;
  Set<String> get selectedAnswers => _selectedAnswers;
  bool get isConfirmed => _isConfirmed;
  String? get selectedGroup => _selectedGroup;
  Map<int, Set<String>> get userAnswers => _userAnswers;
  bool get showResults => _showResults;

  ExamController(this.regulationId)
      : _presenter = ExamPresenter(CloudExamRepository()) {
    initListeners();
    _presenter.getQuestions(regulationId);
  }

  @override
  void initListeners() {
    _presenter.onQuestionsLoaded = (List<ExamQuestion> questions) {
      _allQuestions = questions;
      _availableGroups =
          questions.map((q) => q.name).toSet().toList()..sort();
      _isLoading = false;
      refreshUI();
    };

    _presenter.onError = (e) {
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    };
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    _examQuestions = _allQuestions.where((q) => q.name == group).toList()
      ..shuffle();
    if (_examQuestions.length > 10) {
      _examQuestions = _examQuestions.take(10).toList();
    }
    refreshUI();
  }

  void toggleAnswerSelection(String answer) {
    if (isConfirmed) return;

    final question = currentQuestion;
    if (question == null) return;

    // Radio button logic for single-answer questions
    if (question.correctAnswers.length == 1) {
      _selectedAnswers.clear();
      _selectedAnswers.add(answer);
    } else {
      // Checkbox logic for multiple-answer questions
      if (_selectedAnswers.contains(answer)) {
        _selectedAnswers.remove(answer);
      } else {
        _selectedAnswers.add(answer);
      }
    }
    refreshUI();
  }

  void confirmAnswer() {
    if (_selectedAnswers.isEmpty) return;
    _isConfirmed = true;
    _userAnswers[_currentQuestionIndex] = Set.from(_selectedAnswers);
    refreshUI();
  }

  void nextQuestion() {
    if (!_isConfirmed) return;

    if (_currentQuestionIndex < _examQuestions.length - 1) {
      _currentQuestionIndex++;
      _isConfirmed = false;
      _selectedAnswers.clear();
      refreshUI();
    } else {
      _showResults = true;
      refreshUI();
    }
  }

  void restartExam() {
    _isLoading = true;
    _error = null;
    _allQuestions = [];
    _examQuestions = [];
    _availableGroups = [];
    _selectedGroup = null;
    _currentQuestionIndex = 0;
    _selectedAnswers.clear();
    _isConfirmed = false;
    _userAnswers.clear();
    _showResults = false;
    refreshUI();
    _presenter.getQuestions(regulationId);
  }

  bool isAnswerCorrect(int questionIndex) {
    final userAnswers = _userAnswers[questionIndex] ?? <String>{};
    final correctAnswers = _examQuestions[questionIndex].correctAnswers.toSet();
    return setEquals(userAnswers, correctAnswers);
  }

  int get score {
    int correct = 0;
    for (int i = 0; i < _examQuestions.length; i++) {
      if (isAnswerCorrect(i)) {
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
