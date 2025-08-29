import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poteu/app/pages/exam/exam_view.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import 'package:rolling_switch/rolling_switch.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/notes_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/font_size_settings_widget.dart';
import '../../../main.dart';
import '../drawer/sound_settings_view.dart';

class AppDrawer extends StatelessWidget {
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final NotesRepository notesRepository;
  final SubscriptionRepository subscriptionRepository;

  const AppDrawer({
    Key? key,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.notesRepository,
    required this.subscriptionRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return MediaQuery.of(context).orientation == Orientation.portrait
            ? Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: Drawer(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).navigationRailTheme.backgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            // Библиотека
                            ListTile(
                              leading: const Icon(Icons.library_books_outlined),
                              title: const Text('Библиотека'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushNamed('/library');
                              },
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedLabelTextStyle!
                                  .color,
                            ),
                            // Заметки
                            ExpansionTile(
                              onExpansionChanged: (bool val) async {
                                if (val) {
                                  Navigator.of(context).pop();
                                  AppNavigator.navigateToNotes(
                                    context,
                                    notesRepository: notesRepository,
                                    subscriptionRepository:
                                        subscriptionRepository,
                                  );
                                }
                              },
                              trailing: const SizedBox(),
                              backgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .indicatorColor,
                              collapsedBackgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .backgroundColor,
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedIconTheme!
                                  .color,
                              collapsedIconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedLabelTextStyle!
                                  .color,
                              collapsedTextColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedLabelTextStyle!
                                  .color,
                              title: const Padding(
                                padding: EdgeInsets.only(bottom: 3.0),
                                child: Text('Заметки'),
                              ),
                              leading: const Icon(Icons.note_alt_outlined),
                              children: [Container()],
                            ),
                            // Шрифт
                            ExpansionTile(
                              trailing: const SizedBox(),
                              backgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .indicatorColor,
                              collapsedBackgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .backgroundColor,
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedIconTheme!
                                  .color,
                              collapsedIconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedLabelTextStyle!
                                  .color,
                              collapsedTextColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedLabelTextStyle!
                                  .color,
                              title: const Padding(
                                padding: EdgeInsets.only(bottom: 3.0),
                                child: Text('Шрифт'),
                              ),
                              leading: const Icon(Icons.font_download_outlined),
                              children: [
                                FontSizeSettingsWidget(
                                  settingsRepository: settingsRepository,
                                ),
                              ],
                            ),
                            // Звук
                            ExpansionTile(
                              trailing: const SizedBox(),
                              backgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .indicatorColor,
                              collapsedBackgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .backgroundColor,
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedIconTheme!
                                  .color,
                              collapsedIconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedLabelTextStyle!
                                  .color,
                              collapsedTextColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedLabelTextStyle!
                                  .color,
                              title: const Padding(
                                padding: EdgeInsets.only(bottom: 3.0),
                                child: Text('Звук'),
                              ),
                              leading: const Icon(Icons.volume_up_outlined),
                              children: [
                                SoundSettingsView(
                                  settingsRepository: settingsRepository,
                                  ttsRepository: ttsRepository,
                                ),
                              ],
                            ),

                            // Экзамен
                            ListTile(
                              leading: const Icon(Icons.quiz_outlined),
                              title: const Text('Экзамен'),
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                final checkSubscriptionUseCase =
                                    CheckSubscriptionUseCase(
                                        subscriptionRepository);
                                navigator.pop();

                                try {
                                  final subscriptionStream =
                                      await checkSubscriptionUseCase
                                          .buildUseCaseStream(null);
                                  final subscription =
                                      await subscriptionStream.first;

                                  final regulationId = ActiveRegulationService()
                                      .currentRegulationId;
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (context) => ExamView(
                                        arguments: ExamArguments(
                                            regulationId: regulationId,
                                            isSubscribed:
                                                subscription.isActive),
                                      ),
                                    ),
                                  );
                                } catch (e, stackTrace) {
                                  await Sentry.captureException(e,
                                      stackTrace: stackTrace);
                                } finally {
                                  checkSubscriptionUseCase.dispose();
                                }
                              },
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedLabelTextStyle!
                                  .color,
                            ),
                            // О программе
                            ExpansionTile(
                              onExpansionChanged: (bool val) {
                                if (val) {
                                  Navigator.of(context).pop(); // Close drawer
                                  _showAboutDialog(context);
                                }
                              },
                              trailing: const SizedBox(),
                              backgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .indicatorColor,
                              collapsedBackgroundColor: Theme.of(context)
                                  .navigationRailTheme
                                  .backgroundColor,
                              iconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedIconTheme!
                                  .color,
                              collapsedIconColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedIconTheme!
                                  .color,
                              textColor: Theme.of(context)
                                  .navigationRailTheme
                                  .selectedLabelTextStyle!
                                  .color,
                              collapsedTextColor: Theme.of(context)
                                  .navigationRailTheme
                                  .unselectedLabelTextStyle!
                                  .color,
                              title: const Padding(
                                padding: EdgeInsets.only(bottom: 3.0),
                                child: Text('О программе'),
                              ),
                              leading: const Icon(Icons.info_outline),
                              children: [Container()],
                            ),
                          ],
                        ),
                      ),
                      // Тема
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: StreamBuilder<bool>(
                          stream: ThemeManager().themeStream,
                          initialData: ThemeManager().isDarkMode,
                          builder: (context, snapshot) {
                            final isDark = snapshot.data ?? false;
                            return ListTile(
                              leading: Icon(
                                isDark ? Icons.dark_mode : Icons.sunny,
                                size: 35,
                                color: Theme.of(context)
                                    .appBarTheme
                                    .foregroundColor,
                              ),
                              trailing: Transform.scale(
                                scale: 0.7,
                                child: RollingSwitch.widget(
                                  initialState: isDark,
                                  onChanged: (bool state) {
                                    ThemeManager().setTheme(state);
                                  },
                                  rollingInfoRight: RollingWidgetInfo(
                                    icon: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFff9500),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF191c1e),
                                    text: const Text('ON'),
                                  ),
                                  rollingInfoLeft: RollingWidgetInfo(
                                    icon: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFff9500),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFfdecd9),
                                    text: const Text(
                                      'OFF',
                                      style:
                                          TextStyle(color: Color(0xFF5a5a5a)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container();
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'О программе',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Данное приложение является частной разработкой и не представляет государственный орган. Оно создано исключительно в образовательных и справочных целях. Для юридически значимых действий всегда обращайтесь к официальным первоисточникам.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'ИСТОЧНИК ИНФОРМАЦИИ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final url = ActiveRegulationService().currentSourceUrl;
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Ссылка на официальный источник скопирована')),
                    );
                  },
                  child: Text(
                    ActiveRegulationService().currentSourceName,
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // A plausible URL for the privacy policy.
                    const url =
                        'https://marketconnect.github.io/app-policies/poteu/';
                    Clipboard.setData(const ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Ссылка на политику конфиденциальности скопирована')),
                    );
                  },
                  child: const Text(
                    'Политика конфиденциальности (нажмите, чтобы скопировать ссылку).',
                    style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Закрыть'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
