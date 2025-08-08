class AppConfig {
  final String databasePath;
  final String appName;
  final String sourceName;
  final int regulationId;
  final String flavorName;
  final String source;

  AppConfig({
    required this.databasePath,
    required this.appName,
    required this.sourceName,
    required this.regulationId,
    required this.flavorName,
    required this.source,
  });

  static AppConfig? _instance;

  static void initialize(String flavor) {
    if (_instance != null) return;

    String dbPath;
    String name;
    int regulationId;
    String source;
    String sourceName;
    if (flavor == 'poteu') {
      dbPath = 'assets/poteu/data/regulations.duckdb';
      name = 'ПОТЭУ';
      sourceName =
          'Приказ Минтруда России от 15.12.2020 N 903н (ред. от 29.04.2022)';
      source = 'http://publication.pravo.gov.ru/document/0001202012300142';
      regulationId = 1;
    } else if (flavor == 'height_rules') {
      dbPath = 'assets/height_rules/data/regulations.duckdb';
      name = '782н';
      sourceName =
          'Приказ Минтруда России от 16.11.2020 N 782н "Об утверждении Правил по охране труда при работе на высоте" (Зарегистрировано в Минюсте России 15.12.2020 N 61477)';
      source = 'http://publication.pravo.gov.ru/document/0001202012160036';
      regulationId = 2;
    } else if (flavor == 'pteep') {
      dbPath = 'assets/pteep/data/regulations.duckdb';
      name = 'ПТЭЭП';
      regulationId = 3;
      sourceName =
          'Приказ Минэнерго России от 12.08.2022 N 811 "Об утверждении Правил технической эксплуатации электроустановок потребителей электрической энергии" (Зарегистрировано в Минюсте России 07.10.2022 N 70433)';
      source = 'http://publication.pravo.gov.ru/document/0001202210070065';
    } else if (flavor == 'fz116') {
      dbPath = 'assets/fz116/data/regulations.duckdb';
      name = '116-ФЗ';
      sourceName =
          'Федеральный закон "О промышленной безопасности опасных производственных объектов" от 21.07.1997 N 116-ФЗ (последняя редакция)';
      source = 'http://pravo.gov.ru/proxy/ips/?docbody=&nd=102048376';
      regulationId = 4;
    } else if (flavor == 'fire_reg') {
      dbPath = 'assets/fire_reg/data/regulations.duckdb';
      name = 'ПП №1479';
      sourceName =
          'Постановление Правительства РФ от 16.09.2020 N 1479 (ред. от 30.03.2023) "Об утверждении Правил противопожарного режима в Российской Федерации"';
      source = 'http://publication.pravo.gov.ru/document/0001202009250010';
      regulationId = 5;
    } else {
      throw Exception("Неизвестный flavor: $flavor");
    }

    _instance = AppConfig(
      databasePath: dbPath,
      appName: name,
      flavorName: flavor,
      sourceName: sourceName,
      regulationId: regulationId,
      source: source,
    );
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
        "AppConfig не был инициализирован! Вызовите AppConfig.initialize() в main.",
      );
    }
    return _instance!;
  }
}
