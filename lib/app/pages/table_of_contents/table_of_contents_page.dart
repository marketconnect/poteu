import 'package:flutter/material.dart';
import 'package:rolling_switch/rolling_switch.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../chapter/model/chapter_arguments.dart';
import '../../widgets/regulation_app_bar.dart';
import '../../widgets/table_of_contents_app_bar.dart';
import '../../widgets/chapter_card.dart';
import '../../widgets/font_size_settings_widget.dart';
import '../../../main.dart';
import '../drawer/sound_settings_view.dart';

class TableOfContentsPage extends StatefulWidget {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;

  const TableOfContentsPage({
    super.key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
  });

  @override
  State<TableOfContentsPage> createState() => _TableOfContentsPageState();
}

class _TableOfContentsPageState extends State<TableOfContentsPage> {
  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final tableOfContents =
          await widget.regulationRepository.getTableOfContents();

      setState(() {
        chapters = tableOfContents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              title: 'ПОТЭУ', // Аббревиатура регламента
              name: 'Правила охраны труда при эксплуатации электроустановок',
              regulationRepository: widget.regulationRepository,
              settingsRepository: widget.settingsRepository,
              ttsRepository: widget.ttsRepository,
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (chapters.isEmpty) {
      return const Center(child: Text('Нет глав'));
    }

    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ChapterCard(
          name: chapter['title'] as String,
          num: '', // Можно добавить номер главы если есть в данных
          chapterID: chapter['id'] as int? ?? index,
          chapterOrderNum: index + 1,
          totalChapters: chapters.length,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                            // Заметки
                            ExpansionTile(
                              onExpansionChanged: (bool val) async {
                                Navigator.of(context).pop();
                                Navigator.pushNamed(context, '/notesList');
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
                                  settingsRepository: widget.settingsRepository,
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
                                  settingsRepository: widget.settingsRepository,
                                  ttsRepository: widget.ttsRepository,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Тема
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: StreamBuilder<bool>(
                          stream: ThemeManager().themeStream,
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
}
