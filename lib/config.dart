class AppConfig {
  final String databasePath;
  final String appName;
  final int regulationId;
  final String flavorName;

  AppConfig(
      {required this.databasePath,
      required this.appName,
      required this.regulationId,
      required this.flavorName});

  static AppConfig? _instance;

  static void initialize(String flavor) {
    if (_instance != null) return;

    String dbPath;
    String name;
    int regulationId;
    if (flavor == 'poteu') {
      dbPath = 'assets/poteu/data/regulations.duckdb';
      name = 'ПОТЭУ';
      regulationId = 1;
    } else if (flavor == 'height_782n') {
      dbPath = 'assets/height_782n/data/regulations.duckdb';
      name = 'Высота 782н';
      regulationId = 2;
    } else if (flavor == 'pteep') {
      dbPath = 'assets/pteep/data/regulations.duckdb';
      name = 'ПТЭЭП';
      regulationId = 3;
    } else {
      throw Exception("Неизвестный flavor: $flavor");
    }

    _instance = AppConfig(
        databasePath: dbPath,
        appName: name,
        flavorName: flavor,
        regulationId: regulationId);
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
          "AppConfig не был инициализирован! Вызовите AppConfig.initialize() в main.");
    }
    return _instance!;
  }
}
