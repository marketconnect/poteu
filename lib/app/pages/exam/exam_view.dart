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
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
        ),
      ),
      body: ControlledWidgetBuilder<ExamController>(
        builder: (context, controller) {
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
          if (controller.examQuestions.isEmpty) {
            return const Center(
                child: Text('Вопросы для этого документа не найдены.'));
          }

          if (controller.showResults) {
            return _buildResultsView(controller);
          } else {
            return _buildQuestionView(controller);
          }
        },
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
            onPressed: controller.isAnswered ? controller.nextQuestion : null,
            child: Text(
              controller.currentQuestionIndex <
                      controller.examQuestions.length - 1
                  ? 'Следующий вопрос'
                  : 'Показать результаты',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerTile(
      ExamController controller, String answer, ExamQuestion question) {
    bool isSelected = controller.selectedAnswer == answer;
    bool isCorrect = controller.isCorrect(answer, question);
    Color? tileColor;

    if (controller.isAnswered) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.3);
      } else if (isSelected && !isCorrect) {
        tileColor = Colors.red.withOpacity(0.3);
      }
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(answer),
        onTap: () => controller.selectAnswer(answer),
        trailing: controller.isAnswered
            ? isCorrect
                ? const Icon(Icons.check_circle, color: Colors.green)
                : (isSelected
                    ? const Icon(Icons.cancel, color: Colors.red)
                    : null)
            : null,
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
              final isCorrect =
                  controller.isCorrect(userAnswer ?? '', question);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вопрос ${index + 1}: ${question.question.text}',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Ваш ответ: $userAnswer',
                          style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red)),
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
            onPressed: controller.restartExam,
            child: const Text('Пройти еще раз'),
          ),
        ],
      ),
    );
  }
}
