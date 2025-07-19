import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poteu/config.dart';
import 'package:poteu/data/helpers/duckdb_provider.dart';
import 'data/repositories/data_settings_repository.dart';
import 'data/repositories/data_tts_repository.dart';
import 'data/repositories/data_notes_repository.dart';

import 'app/theme/dynamic_theme.dart';
import 'app/router/app_router.dart';
import 'domain/entities/settings.dart';
import 'domain/repositories/regulation_repository.dart';
import 'data/repositories/static_regulation_repository.dart';
import 'data/repositories/data_regulation_repository.dart';
import 'data/migration/migration_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';
import 'dart:developer' as dev;

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
    dev.log(
        'FontManager initialized with fontSize: ${initialSettings.fontSize}');
  }

  void updateSettings(Settings newSettings) async {
    dev.log('FontManager.updateSettings called');
    _currentSettings = newSettings;

    // Save to settings repository
    if (_settingsRepository != null) {
      try {
        await _settingsRepository!.saveSettings(newSettings);
        dev.log('Font settings saved to repository');
      } catch (e) {
        dev.log('Error saving font settings: $e');
      }
    }

    dev.log('Adding settings to stream...');
    _fontController.add(_currentSettings);
    dev.log('Font settings added to stream successfully');
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
    dev.log('ThemeManager initialized with theme: $initialTheme');
  }

  void setTheme(bool isDark) async {
    dev.log('ThemeManager.setTheme called with: $isDark');
    dev.log('Previous theme state: $_isDarkMode');

    if (_isDarkMode == isDark) {
      dev.log('Theme is already $isDark, skipping update');
      return;
    }

    _isDarkMode = isDark;
    dev.log('New theme state: $_isDarkMode');

    // Save to settings repository
    if (_settingsRepository != null) {
      try {
        final currentSettings = await _settingsRepository!.getSettings();
        final newSettings = currentSettings.copyWith(isDarkMode: isDark);
        await _settingsRepository!.saveSettings(newSettings);
        dev.log('Theme saved to settings repository');

        // Update FontManager with new settings
        FontManager().updateSettings(newSettings);
      } catch (e) {
        dev.log('Error saving theme to settings: $e');
      }
    }

    dev.log('Adding to stream...');
    _themeController.add(_isDarkMode);
    dev.log('Theme added to stream successfully');
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

  const flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
  if (flavor.isEmpty) {
    throw Exception(
        "FLUTTER_APP_FLAVOR не был определен. Запустите приложение с флагом --flavor");
  }

  AppConfig.initialize(flavor);

  // === ЦЕНТРАЛИЗОВАННАЯ ИНИЦИАЛИЗАЦИЯ БД ===
  // Гарантируем, что база данных полностью готова ДО любых других действий.
  await DuckDBProvider.instance.initialize();
  // ==========================================

  final prefs = await SharedPreferences.getInstance();
  final settingsRepository = DataSettingsRepository(prefs);
  final regulationRepository = StaticRegulationRepository();
  final ttsRepository = DataTTSRepository(settingsRepository, FlutterTts());

  // Теперь создание репозиториев безопасно
  final notesRepository = DataNotesRepository();
  final dataRegulationRepository = DataRegulationRepository();

  // === ЗАПУСК МИГРАЦИИ ===
  // Миграция теперь будет работать со 100% готовой базой данных
  final migrationService = MigrationService(
    staticRepo: regulationRepository,
    dataRepo: dataRegulationRepository,
  );
  await migrationService.migrateIfNeeded();
  // =======================

  final settings = await settingsRepository.getSettings();
  dev.log('Initial settings loaded - isDarkMode: ${settings.isDarkMode}');

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

            dev.log('App rebuild - isDarkMode: $isDarkMode');
            dev.log('App rebuild - fontSize: ${settings.fontSize}');

            final lightTheme = DynamicTheme.getLight(settings);
            final darkTheme = DynamicTheme.getDark(settings);

            dev.log('Applied theme');

            return MaterialApp(
              title: AppConfig.instance.appName,
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
