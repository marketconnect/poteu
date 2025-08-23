import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/data/repositories/cloud_exam_repository.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'package:poteu/domain/repositories/exam_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exam_presenter.dart';
import 'dart:async';
import 'package:poteu/data/repositories/data_regulation_repository.dart';
import 'dart:math';

enum ExamType { standard, errorReview, difficult, quickSet }

class ExamController extends Controller {
  final int regulationId;
  final ExamPresenter _presenter;

  bool _isLoading = true;
  String? _error;
  bool _isExamNotFoundError = false;
  List<ExamQuestion> _allQuestions = [];
  List<ExamQuestion> _examQuestions = [];
  List<String> _availableGroups = [];
  int _currentQuestionIndex = 0;
  final Set<String> _selectedAnswers = {};
  bool _isConfirmed = false;
  final Map<int, Set<String>> _userAnswers = {};
  bool _showResults = false;

  Timer? _timer;
  int _timeRemainingInSeconds = 0;
  int _numberOfQuestions = 20;
  int _examDurationInMinutes = 20;
  ExamType _examType = ExamType.standard;
  bool _isTrainingMode = false;
  int _errorReviewCount = 0;
  int _difficultCount = 0;
  bool _isTrainingStatsLoading = false;

  static const String _numberOfQuestionsKey = 'exam_number_of_questions';
  static const String _examDurationKey = 'exam_duration_minutes';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isExamNotFoundError => _isExamNotFoundError;
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
  int get timeRemainingInSeconds => _timeRemainingInSeconds;
  int get numberOfQuestions => _numberOfQuestions;
  int get examDurationInMinutes => _examDurationInMinutes;
  ExamType get examType => _examType;
  bool get isTrainingMode => _isTrainingMode;
  int get errorReviewCount => _errorReviewCount;
  int get difficultCount => _difficultCount;
  bool get isTrainingStatsLoading => _isTrainingStatsLoading;

  final DataRegulationRepository _dataRepository = DataRegulationRepository();
  ExamController(
    this.regulationId,
  ) : _presenter = ExamPresenter(CloudExamRepository()) {
    initListeners();
    _loadSettingsAndGetQuestions();
  }
  void _loadSettingsAndGetQuestions() async {
    await _loadSettings();
    _presenter.getQuestions(regulationId);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _numberOfQuestions = prefs.getInt(_numberOfQuestionsKey) ?? 20;
    _examDurationInMinutes = prefs.getInt(_examDurationKey) ?? 20;
    refreshUI();
  }

  @override
  void initListeners() {
    _presenter.onQuestionsLoaded = (List<ExamQuestion> questions) {
      _allQuestions = questions;
      _availableGroups = questions.map((q) => q.name).toSet().toList()..sort();
      _isLoading = false;
      refreshUI();
    };

    _presenter.onError = (e) {
      _isLoading = false;
      if (e is ExamNotFoundException) {
        final docName = ActiveRegulationService().currentAppName;
        _error = 'Для документа "$docName" экзамен не добавлен.';
        _isExamNotFoundError = true;
      } else {
        _error = 'Ошибка загрузки: ${e.toString()}';
        _isExamNotFoundError = false;
      }
      refreshUI();
    };
  }

  void setNumberOfQuestions(int count) async {
    _numberOfQuestions = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_numberOfQuestionsKey, count);
    refreshUI();
  }

  void setExamDuration(int minutes) async {
    _examDurationInMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_examDurationKey, minutes);
    refreshUI();
  }

  void toggleTrainingMode() {
    _isTrainingMode = !_isTrainingMode;
    if (_isTrainingMode) {
      loadTrainingStats();
    }
    refreshUI();
  }

  Future<void> loadTrainingStats() async {
    _isTrainingStatsLoading = true;
    refreshUI();
    try {
      final errorIds = await _dataRepository.getErrorReviewQuestionIds(
          regulationId: regulationId);
      final difficultIds = await _dataRepository.getDifficultQuestionIds(
          regulationId: regulationId);
      _errorReviewCount = errorIds.length;
      _difficultCount = difficultIds.length;
    } catch (e) {
      _error = e.toString();
    }
    _isTrainingStatsLoading = false;
    refreshUI();
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    _examQuestions = _allQuestions.where((q) => q.name == group).toList()
      ..shuffle();
    if (_examQuestions.length > _numberOfQuestions) {
      _examQuestions = _examQuestions.take(_numberOfQuestions).toList();
    }
    _examType = ExamType.standard;
    if (!_isTrainingMode) {
      _startTimer();
    }
    refreshUI();
  }

  void _startTimer() {
    if (_isTrainingMode) return;
    _timer?.cancel();
    _timeRemainingInSeconds = _examDurationInMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingInSeconds > 0) {
        _timeRemainingInSeconds--;
        refreshUI();
      } else {
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    _timer?.cancel();
    _showResults = true;
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
    final question = currentQuestion;
    if (question != null) {
      final isCorrect = isAnswerCorrect(_currentQuestionIndex);
      _dataRepository.updateExamQuestionStats(
        regulationId: regulationId,
        questionId: question.question.text,
        isCorrect: isCorrect,
      );
    }
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
      _timer?.cancel();
      _showResults = true;
      refreshUI();
    }
  }

  void restartExam() {
    _timer?.cancel();
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
    _isExamNotFoundError = false;
    _isTrainingMode = false;
    refreshUI();
    _presenter.getQuestions(regulationId);
  }

  void backToSelection() {
    _timer?.cancel();
    _selectedGroup = null;
    _examQuestions = [];
    _currentQuestionIndex = 0;
    _selectedAnswers.clear();
    _isConfirmed = false;
    _userAnswers.clear();
    _showResults = false;
    refreshUI();
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

  void _resetExamStateForTraining(String groupName, ExamType type) {
    _selectedGroup = groupName;
    _examType = type;
    _currentQuestionIndex = 0;
    _selectedAnswers.clear();
    _isConfirmed = false;
    _userAnswers.clear();
    _showResults = false;
    _timeRemainingInSeconds = 0;
    _timer?.cancel();
  }

  Future<void> startErrorReview() async {
    _isLoading = true;
    refreshUI();
    try {
      final questionIds = await _dataRepository.getErrorReviewQuestionIds(
          regulationId: regulationId);
      _examQuestions = _allQuestions
          .where((q) => questionIds.contains(q.question.text))
          .toList()
        ..shuffle();
      if (_examQuestions.length > _numberOfQuestions) {
        _examQuestions = _examQuestions.take(_numberOfQuestions).toList();
      }
      _resetExamStateForTraining('Повтор ошибок', ExamType.errorReview);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    refreshUI();
  }

  Future<void> startDifficult() async {
    _isLoading = true;
    refreshUI();
    try {
      final questionIds = await _dataRepository.getDifficultQuestionIds(
          regulationId: regulationId);
      _examQuestions = _allQuestions
          .where((q) => questionIds.contains(q.question.text))
          .toList()
        ..shuffle();
      if (_examQuestions.length > _numberOfQuestions) {
        _examQuestions = _examQuestions.take(_numberOfQuestions).toList();
      }
      _resetExamStateForTraining('Сложные', ExamType.difficult);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    refreshUI();
  }

  Future<void> startQuickSet() async {
    _isLoading = true;
    refreshUI();
    try {
      final errorIds = await _dataRepository.getErrorReviewQuestionIds(
          regulationId: regulationId);
      final difficultIds = await _dataRepository.getDifficultQuestionIds(
          regulationId: regulationId);
      final poolIds = {...errorIds, ...difficultIds};
      final poolQuestions = _allQuestions
          .where((q) => poolIds.contains(q.question.text))
          .toList()
        ..shuffle();
      final randomQuestions = _allQuestions
          .where((q) => !poolIds.contains(q.question.text))
          .toList()
        ..shuffle();
      final int totalQuestions = min(_numberOfQuestions, _allQuestions.length);
      final int poolCount = (totalQuestions * 0.7).round();
      final int randomCount = totalQuestions - poolCount;
      _examQuestions = (poolQuestions.take(poolCount).toList() +
          randomQuestions.take(randomCount).toList())
        ..shuffle();
      _resetExamStateForTraining('Быстрый сет', ExamType.quickSet);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    refreshUI();
  }

  @override
  void onDisposed() {
    _timer?.cancel();
    _presenter.dispose();
    super.onDisposed();
  }
}
