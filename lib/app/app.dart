import 'package:flutter/material.dart';
import '../domain/repositories/regulation_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/tts_repository.dart';
import '../domain/repositories/notes_repository.dart';
import '../app/theme/theme.dart';
import 'pages/main/main_view.dart';
import '../data/repositories/static_regulation_repository.dart';

class App extends StatelessWidget {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final NotesRepository notesRepository;

  const App({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.notesRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ПОТЭУ',
      theme: FlutterRegulationTheme.light,
      darkTheme: FlutterRegulationTheme.dark,
      home: MainView(
        regulationRepository:
            regulationRepository as StaticRegulationRepository,
        settingsRepository: settingsRepository,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
