import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'data/repositories/data_settings_repository.dart';
import 'data/repositories/data_tts_repository.dart';
import 'data/repositories/data_notes_repository.dart';

import 'app/theme/dynamic_theme.dart';
import 'app/router/app_router.dart';
import 'domain/entities/settings.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/tts_repository.dart';
import 'domain/repositories/notes_repository.dart';
import 'domain/repositories/regulation_repository.dart';
import 'data/repositories/static_regulation_repository.dart';
import 'data/repositories/data_regulation_repository.dart';
import 'data/migration/migration_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

const String sentryDsn =
    ''; // Set to empty for development, replace with your actual Sentry DSN

// Font Manager for Clean Architecture
class FontManager {
  static final FontManager _instance = FontManager._internal();
  factory FontManager() => _instance;
  FontManager._internal();

  final StreamController<Settings> _fontController =
      StreamController<Settings>.broadcast();
  Stream<Settings> get fontStream => _fontController.stream;

  Settings _currentSettings = Settings.defaultSettings();
  Settings get currentSettings => _currentSettings;

  DataSettingsRepository? _settingsRepository;

  void initialize(
      DataSettingsRepository settingsRepository, Settings initialSettings) {
    _settingsRepository = settingsRepository;
    _currentSettings = initialSettings;
    print('FontManager initialized with fontSize: ${initialSettings.fontSize}');
  }

  void updateSettings(Settings newSettings) async {
    print('FontManager.updateSettings called');
    _currentSettings = newSettings;

    // Save to settings repository
    if (_settingsRepository != null) {
      try {
        await _settingsRepository!.saveSettings(newSettings);
        print('Font settings saved to repository');
      } catch (e) {
        print('Error saving font settings: $e');
      }
    }

    print('Adding settings to stream...');
    _fontController.add(_currentSettings);
    print('Font settings added to stream successfully');
  }

  void dispose() {
    _fontController.close();
  }
}

// Theme Manager for Clean Architecture
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final StreamController<bool> _themeController =
      StreamController<bool>.broadcast();
  Stream<bool> get themeStream => _themeController.stream;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  DataSettingsRepository? _settingsRepository;

  void initialize(
      DataSettingsRepository settingsRepository, bool initialTheme) {
    _settingsRepository = settingsRepository;
    _isDarkMode = initialTheme;
    print('ThemeManager initialized with theme: $initialTheme');
  }

  void setTheme(bool isDark) async {
    print('ThemeManager.setTheme called with: $isDark');
    print('Previous theme state: $_isDarkMode');

    if (_isDarkMode == isDark) {
      print('Theme is already $isDark, skipping update');
      return;
    }

    _isDarkMode = isDark;
    print('New theme state: $_isDarkMode');

    // Save to settings repository
    if (_settingsRepository != null) {
      try {
        final currentSettings = await _settingsRepository!.getSettings();
        final newSettings = currentSettings.copyWith(isDarkMode: isDark);
        await _settingsRepository!.saveSettings(newSettings);
        print('Theme saved to settings repository');

        // Update FontManager with new settings
        FontManager().updateSettings(newSettings);
      } catch (e) {
        print('Error saving theme to settings: $e');
      }
    }

    print('Adding to stream...');
    _themeController.add(_isDarkMode);
    print('Theme added to stream successfully');
  }

  void dispose() {
    _themeController.close();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.black),
  );

  final prefs = await SharedPreferences.getInstance();
  final settingsRepository = DataSettingsRepository(prefs);
  final regulationRepository = StaticRegulationRepository();
  final ttsRepository = DataTTSRepository(settingsRepository, FlutterTts());

  final notesRepository = DataNotesRepository();

  // === ЗАПУСК МИГРАЦИИ ===
  final dataRegulationRepository = DataRegulationRepository();
  final migrationService = MigrationService(
    staticRepo: regulationRepository,
    dataRepo: dataRegulationRepository, // Передаем его
  );
  await migrationService.migrateIfNeeded();
  // =======================

  final settings = await settingsRepository.getSettings();

  print('Initial settings loaded - isDarkMode: ${settings.isDarkMode}');

  ThemeManager().initialize(settingsRepository, settings.isDarkMode);
  FontManager().updateSettings(settings);

  // Only initialize Sentry if a valid DSN is provided
  if (sentryDsn.isNotEmpty && sentryDsn != 'YOUR_SENTRY_DSN') {
    // await SentryFlutter.init(
    //   (options) => options.dsn = sentryDsn,
    //   appRunner: () => runApp(PoteuApp(
    //     settings: settings,
    //     settingsRepository: settingsRepository,
    //     regulationRepository: regulationRepository,
    //     ttsRepository: ttsRepository,
    //     notesRepository: notesRepository,
    //   )),
    // );
  } else {
    // Run app without Sentry for development
    runApp(PoteuApp(
      settings: settings,
      settingsRepository: settingsRepository,
      regulationRepository: regulationRepository,
      ttsRepository: ttsRepository,
      notesRepository: notesRepository,
    ));
  }
}

class PoteuApp extends StatefulWidget {
  final Settings settings;
  final DataSettingsRepository settingsRepository;
  final RegulationRepository regulationRepository;
  final DataTTSRepository ttsRepository;
  final DataNotesRepository notesRepository;

  const PoteuApp({
    Key? key,
    required this.settings,
    required this.settingsRepository,
    required this.regulationRepository,
    required this.ttsRepository,
    required this.notesRepository,
  }) : super(key: key);

  @override
  State<PoteuApp> createState() => _PoteuAppState();
}

class _PoteuAppState extends State<PoteuApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(
      settingsRepository: widget.settingsRepository,
      ttsRepository: widget.ttsRepository,
      notesRepository: widget.notesRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ThemeManager().themeStream,
      initialData: ThemeManager().isDarkMode,
      builder: (context, themeSnapshot) {
        return StreamBuilder<Settings>(
          stream: FontManager().fontStream,
          initialData: FontManager().currentSettings,
          builder: (context, fontSnapshot) {
            final isDarkMode = themeSnapshot.data ?? false;
            final settings = fontSnapshot.data ?? Settings.defaultSettings();

            print('App rebuild - isDarkMode: $isDarkMode');
            print('App rebuild - fontSize: ${settings.fontSize}');

            final lightTheme = DynamicTheme.getLight(settings);
            final darkTheme = DynamicTheme.getDark(settings);

            print('Applied theme');

            return MaterialApp(
              title: 'POTEU',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              onGenerateRoute: _appRouter.onGenerateRoute,
              initialRoute: '/',
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    ThemeManager().dispose();
    FontManager().dispose();
    super.dispose();
  }
}
