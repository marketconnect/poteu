import 'dart:convert';
import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/widgets/regulation_app_bar.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'exam_controller.dart';

class ExamArguments {
  final int regulationId;
  ExamArguments({required this.regulationId});
}

class ExamView extends View {
  final ExamArguments arguments;

  const ExamView({Key? key, required this.arguments}) : super(key: key);

  @override
  ExamViewState createState() =>
      // ignore: no_logic_in_create_state
      ExamViewState(ExamController(arguments.regulationId));
}

class ExamViewState extends ViewState<ExamView, ExamController> {
  ExamViewState(ExamController controller) : super(controller);

  @override
  Widget get view {
    return ControlledWidgetBuilder<ExamController>(
        builder: (context, controller) {
      return Scaffold(
        key: globalKey,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
              Theme.of(context).appBarTheme.toolbarHeight ?? 74.0),
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: RegulationAppBar(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Экзамен',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (controller.selectedGroup != null &&
                      !controller.showResults)
                    _buildTimer(context, controller)
                  else
                    const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),
        ),
        body: _buildBody(controller),
      );
    });
  }

  Widget _buildBody(ExamController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка: ${controller.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.restartExam,
              child: const Text('Попробовать снова'),
            )
          ],
        ),
      );
    }
    if (controller.selectedGroup == null) {
      return _buildGroupSelectionView(controller);
    } else {
      if (controller.examQuestions.isEmpty) {
        return Center(
            child: Text(
                'Вопросы для группы "${controller.selectedGroup}" не найдены.'));
      }
      if (controller.showResults) {
        return _buildResultsView(controller);
      } else {
        return _buildQuestionView(controller);
      }
    }
  }

  Widget _buildTimer(BuildContext context, ExamController controller) {
    final duration = Duration(seconds: controller.timeRemainingInSeconds);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final isRunningLow = duration.inSeconds < 60;
    return SizedBox(
      width: 60,
      child: Text(
        '$minutes:$seconds',
        style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
              color: isRunningLow
                  ? Colors.red
                  : Theme.of(context).appBarTheme.titleTextStyle?.color,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildQuestionView(ExamController controller) {
    final question = controller.currentQuestion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Вопрос ${controller.currentQuestionIndex + 1} из ${controller.examQuestions.length}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (controller.currentQuestionIndex + 1) /
                controller.examQuestions.length,
          ),
          const SizedBox(height: 24),
          if (question.question.imageBase64 != null &&
              question.question.imageBase64!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Image.memory(base64Decode(question.question.imageBase64!)),
            ),
          Text(
            question.question.text,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ...question.answers
              .map((answer) => _buildAnswerTile(controller, answer, question)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .navigationRailTheme
                  .selectedIconTheme
                  ?.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: controller.isConfirmed
                ? controller.nextQuestion
                : (controller.selectedAnswers.isNotEmpty
                    ? controller.confirmAnswer
                    : null),
            child: Text(
              controller.isConfirmed
                  ? (controller.currentQuestionIndex <
                          controller.examQuestions.length - 1
                      ? 'Следующий вопрос'
                      : 'Показать результаты')
                  : 'Подтвердить ответ',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerTile(
      ExamController controller, String answer, ExamQuestion question) {
    final bool isSelected = controller.selectedAnswers.contains(answer);
    final bool isThisAnswerCorrect = question.correctAnswers.contains(answer);

    Color? tileColor;
    Widget? leadingIcon;

    if (controller.isConfirmed) {
      // After user confirms their answer
      if (isSelected && isThisAnswerCorrect) {
        tileColor = Colors.green.withOpacity(0.2);
        leadingIcon = const Icon(Icons.check_box, color: Colors.green);
      } else if (isSelected && !isThisAnswerCorrect) {
        tileColor = Theme.of(context).colorScheme.error.withOpacity(0.2);
        leadingIcon =
            Icon(Icons.cancel, color: Theme.of(context).colorScheme.error);
      } else if (!isSelected && isThisAnswerCorrect) {
        tileColor = Colors.green.withOpacity(0.1);
        leadingIcon =
            const Icon(Icons.check_box_outline_blank, color: Colors.green);
      }
    } else {
      // Before user confirms their answer
      final isSingleChoice = question.correctAnswers.length == 1;
      if (isSingleChoice) {
        leadingIcon = Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected ? Theme.of(context).primaryColor : null);
      } else {
        leadingIcon = Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: isSelected ? Theme.of(context).primaryColor : null);
      }
    }

    return Card(
      elevation: 0,
      color: tileColor ?? Theme.of(context).scaffoldBackgroundColor,
      margin: EdgeInsets.zero,
      shape: Border(
        bottom: BorderSide(
          width: 1.0,
          color: Theme.of(context).shadowColor,
        ),
      ),
      child: ListTile(
        leading: leadingIcon,
        title: Text(answer),
        onTap: () => controller.toggleAnswerSelection(answer),
      ),
    );
  }

  Widget _buildResultsView(ExamController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Результаты экзамена',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Правильных ответов: ${controller.score} из ${controller.examQuestions.length}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.examQuestions.length,
            itemBuilder: (context, index) {
              final question = controller.examQuestions[index];
              final userAnswer = controller.userAnswers[index];
              final isCorrect = controller.isAnswerCorrect(index);
              return Card(
                elevation: 0,
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: EdgeInsets.zero,
                shape: Border(
                  bottom: BorderSide(
                    width: 1.0,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вопрос ${index + 1}: ${question.question.text}',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                          'Ваш ответ: ${userAnswer?.join(", ") ?? "Нет ответа"}',
                          style: TextStyle(
                              color: isCorrect
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error)),
                      if (!isCorrect)
                        Text(
                            'Правильный ответ: ${question.correctAnswers.join(", ")}',
                            style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .navigationRailTheme
                  .selectedIconTheme
                  ?.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: controller.restartExam,
            child: Text('Пройти еще раз',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelectionView(ExamController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Выберите группу допуска',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.availableGroups.length,
            itemBuilder: (context, index) {
              final group = controller.availableGroups[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: EdgeInsets.zero,
                shape: Border(
                  bottom: BorderSide(
                    width: 1.0,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                child: ListTile(
                  title: Text('Группа $group'),
                  onTap: () => controller.selectGroup(group),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
