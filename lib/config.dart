class AppConfig {
  final String databasePath;
  final String appName;
  final int regulationId;
  final String flavorName;
  final String source;

  AppConfig(
      {required this.databasePath,
      required this.appName,
      required this.regulationId,
      required this.flavorName,
      required this.source});

  static AppConfig? _instance;

  static void initialize(String flavor) {
    if (_instance != null) return;

    String dbPath;
    String name;
    int regulationId;
    String source;
    if (flavor == 'poteu') {
      dbPath = 'assets/poteu/data/regulations.duckdb';
      name = 'ПОТЭУ';
      source = 'http://publication.pravo.gov.ru/document/0001202012300142';
      regulationId = 1;
    } else if (flavor == 'height_rules') {
      dbPath = 'assets/height_rules/data/regulations.duckdb';
      name = '782н';
      source = 'http://publication.pravo.gov.ru/document/0001202012160036';
      regulationId = 2;
    } else if (flavor == 'pteep') {
      dbPath = 'assets/pteep/data/regulations.duckdb';
      name = 'ПТЭЭП';
      regulationId = 3;
      source = 'http://publication.pravo.gov.ru/document/0001202210070065';
    } else if (flavor == 'fz116') {
      dbPath = 'assets/fz116/data/regulations.duckdb';
      name = '116-ФЗ';
      source = 'http://pravo.gov.ru/proxy/ips/?docbody=&nd=102048376';
      regulationId = 4;
    } else {
      throw Exception("Неизвестный flavor: $flavor");
    }

    _instance = AppConfig(
        databasePath: dbPath,
        appName: name,
        flavorName: flavor,
        regulationId: regulationId,
        source: source);
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
          "AppConfig не был инициализирован! Вызовите AppConfig.initialize() в main.");
    }
    return _instance!;
  }
}
