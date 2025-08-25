import 'dart:convert';
import 'package:flutter/material.dart' hide View;
import 'package:flutter/services.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/widgets/regulation_app_bar.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'exam_controller.dart';

class ExamArguments {
  final int regulationId;
  final bool isSubscribed;
  ExamArguments({required this.regulationId, this.isSubscribed = true});
}

class ExamView extends View {
  final ExamArguments arguments;

  const ExamView({Key? key, required this.arguments}) : super(key: key);

  @override
  ExamViewState createState() =>
      // ignore: no_logic_in_create_state
      ExamViewState(
          ExamController(arguments.regulationId, arguments.isSubscribed));
}

class ExamViewState extends ViewState<ExamView, ExamController> {
  ExamViewState(ExamController controller) : super(controller);
  bool _showSettings = false;
  @override
  Widget get view {
    return ControlledWidgetBuilder<ExamController>(
        builder: (context, controller) {
      return PopScope(
        canPop: controller.selectedGroup == null,
        onPopInvoked: (bool didPop) {
          if (didPop) return;
          controller.backToSelection();
        },
        child: Scaffold(
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
                      onPressed: () {
                        if (controller.selectedGroup != null) {
                          controller.backToSelection();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        size:
                            Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        controller.isTrainingMode ? 'Тренировка' : 'Экзамен',
                        style: controller.isTrainingMode
                            ? Theme.of(context)
                                .appBarTheme
                                .titleTextStyle
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .navigationRailTheme
                                      .selectedIconTheme
                                      ?.color,
                                )
                            : Theme.of(context).appBarTheme.titleTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (controller.selectedGroup == null)
                      Switch(
                        value: controller.isTrainingMode,
                        onChanged: (value) {
                          controller.toggleTrainingMode();
                        },
                        activeColor: Theme.of(context)
                            .navigationRailTheme
                            .selectedIconTheme
                            ?.color,
                      )
                    else if (controller.selectedGroup != null &&
                        !controller.showResults)
                      if (!controller.isTrainingMode)
                        _buildTimer(context, controller)
                      else
                        const SizedBox(
                          width: 48,
                        )
                  ],
                ),
              ),
            ),
          ),
          body: _buildBody(controller),
        ),
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
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Text(
            //     controller.error!,
            //     textAlign: TextAlign.center,
            //   ),
            // ),
            if (!controller.isExamNotFoundError) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.restartExam,
                child: const Text('Попробовать снова'),
              )
            ]
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

  Widget _buildTrainingSection(
      BuildContext context, ExamController controller) {
    final textTheme = Theme.of(context).textTheme;
    const chipColor1 = Color(0xFFFEF8E3); // Повтор ошибок
    const chipColor2 = Color(0xFFF3F3FD); // Сложные
    const chipColor3 = Color(0xFFEBF2FF); // Быстрый сет
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          border:
              Border.all(color: Theme.of(context).shadowColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тренировка',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isTrainingStatsLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            else ...[
              _buildTrainingChip(
                context,
                label: 'Повтор ошибок',
                count: controller.errorReviewCount,
                color: chipColor1,
                onTap: () {
                  if (controller.errorReviewCount > 0) {
                    controller.startErrorReview();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Нет вопросов для повторения ошибок.')),
                    );
                  }
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 8),
              _buildTrainingChip(
                context,
                label: 'Сложные',
                count: controller.difficultCount,
                color: chipColor2,
                onTap: () {
                  if (controller.difficultCount > 0) {
                    controller.startDifficult();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Нет сложных вопросов.')),
                    );
                  }
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 8),
              _buildTrainingChip(
                context,
                label: 'Быстрый сет',
                color: chipColor3,
                onTap: controller.startQuickSet,
                isFullWidth: true,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingChip(BuildContext context,
      {required String label,
      int? count,
      required Color color,
      required VoidCallback onTap,
      bool isFullWidth = false}) {
    final textTheme = Theme.of(context).textTheme;
    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ]
          ],
        ),
      ),
    );
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: content,
      );
    }
    return content;
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
        title: Text(answer, style: Theme.of(context).textTheme.bodyLarge),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Правильных ответов: ${controller.score} из ${controller.examQuestions.length}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
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
    if (controller.isTrainingMode) {
      if (!controller.isSubscribed) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Режим тренировки доступен только для подписчиков',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/subscription'),
                  child: const Text('Оформить подписку'),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        children: [_buildTrainingSection(context, controller)],
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Готовность: 74% • Серия: 3 дня',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.top / 2,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                      color: Theme.of(context).shadowColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Время: ${controller.examDurationInMinutes} мин.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      ' • Вопросов: ${controller.numberOfQuestions}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )
                  ],
                ),
              ),
            ),
          ),
          if (_showSettings)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Количество вопросов:',
                          style: Theme.of(context).textTheme.bodyLarge),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: controller.numberOfQuestions.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            final count = int.tryParse(value);
                            if (count != null && count > 0) {
                              controller.setNumberOfQuestions(count);
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Время (минут):',
                          style: Theme.of(context).textTheme.bodyLarge),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue:
                              controller.examDurationInMinutes.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            final minutes = int.tryParse(value);
                            if (minutes != null && minutes > 0) {
                              controller.setExamDuration(minutes);
                            }
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  title: Text('Группа $group',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => controller.selectGroup(group),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
