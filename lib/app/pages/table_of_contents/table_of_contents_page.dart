import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import 'package:poteu/app/services/active_regulation_service.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../domain/repositories/notes_repository.dart';
import '../../widgets/regulation_app_bar.dart';
import '../../widgets/table_of_contents_app_bar.dart';
import '../../widgets/chapter_card.dart';
import 'table_of_contents_controller.dart';
import '../drawer/app_drawer.dart';

import 'package:feature_notifier/feature_notifier.dart';
import 'dart:developer' as dev;

class TableOfContentsView extends fca.View {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final NotesRepository notesRepository;
  final int regulationId;
  final SubscriptionRepository subscriptionRepository;

  const TableOfContentsView({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.notesRepository,
    required this.regulationId,
    required this.subscriptionRepository,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<TableOfContentsView> createState() => _TableOfContentsPageState(
        TableOfContentsController(
          regulationId: regulationId,
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
        ),
      );
}

class _TableOfContentsPageState
    extends fca.ViewState<TableOfContentsView, TableOfContentsController> {
  _TableOfContentsPageState(TableOfContentsController controller)
      : super(controller);

  @override
  Widget get view => Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            Theme.of(context).appBarTheme.toolbarHeight ?? 74.0,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: RegulationAppBar(
              child: TableOfContentsAppBar(
                title: ActiveRegulationService().currentAppName,
                name: ActiveRegulationService().currentSourceName,
                regulationRepository: widget.regulationRepository,
                settingsRepository: widget.settingsRepository,
                ttsRepository: widget.ttsRepository,
              ),
            ),
          ),
        ),
        drawer: AppDrawer(
          notesRepository: widget.notesRepository,
          settingsRepository: widget.settingsRepository,
          ttsRepository: widget.ttsRepository,
          subscriptionRepository: widget.subscriptionRepository,
        ),
        // body: fca.ControlledWidgetBuilder<TableOfContentsController>(
        //   builder: (context, controller) {
        //     if (controller.isLoading) {
        //       return const Center(child: CircularProgressIndicator());
        //     }
        //     if (controller.error != null) {
        //       return Center(child: Text('Error: ${controller.error}'));
        //     }
        //     if (controller.chapters.isEmpty) {
        //       return const Center(child: Text('Нет глав'));
        //     }
        //     return ListView.builder(
        //       itemCount: controller.chapters.length,
        //       itemBuilder: (context, index) {
        //         final chapter = controller.chapters[index];
        //         // Проверяем, есть ли onTap у ChapterCard, иначе оборачиваем в GestureDetector
        //         return GestureDetector(
        //           onTap: () => controller.onChapterSelected(chapter),
        //           child: ChapterCard(
        //             name: chapter.title,
        //             num: chapter.num,
        //             chapterID: chapter.id,
        //             chapterOrderNum: chapter.level,
        //             totalChapters: controller.chapters.length,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: FeatureBarNotifier(
                featureKey: 'exam_fire_reg_bar_2025_08_27'.hashCode,
                title: 'Тесты по пожарной безопасности добавлены!',
                titleFontSize: 16,
                icon: const Text('🎉', style: TextStyle(fontSize: 22)),
                showIcon: true,
                backgroundColor: const Color(0xFFE8F5E9),
                strokeColor: const Color(0xFF66BB6A),
                titleColor: Colors.black87,
                // closeIconColor: Colors.black54,
                onClose: () => dev.log("Feature notification closed."),
                onTapCard: () => dev.log("Feature notification tapped."),
              ),
            ),
            Expanded(
              child: fca.ControlledWidgetBuilder<TableOfContentsController>(
                builder: (context, controller) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error != null) {
                    return Center(child: Text('Error: ${controller.error}'));
                  }
                  if (controller.chapters.isEmpty) {
                    return const Center(child: Text('Нет глав'));
                  }
                  return ListView.builder(
                    itemCount: controller.chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = controller.chapters[index];
                      return GestureDetector(
                        onTap: () => controller.onChapterSelected(chapter),
                        child: ChapterCard(
                          name: chapter.title,
                          num: chapter.num,
                          chapterID: chapter.id,
                          chapterOrderNum: chapter.level,
                          totalChapters: controller.chapters.length,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}
