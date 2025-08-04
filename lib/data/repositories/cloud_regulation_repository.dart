import 'dart:io';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:http/http.dart' as http;
import 'package:poteu/data/helpers/duckdb_provider.dart';
import 'package:poteu/data/helpers/remote_data_provider.dart';
import 'package:poteu/domain/entities/regulation.dart';
import 'package:poteu/domain/repositories/cloud_regulation_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

class DataCloudRegulationRepository implements CloudRegulationRepository {
  final RemoteDataProvider _remoteDataProvider = RemoteDataProvider();
  final DuckDBProvider _dbProvider = DuckDBProvider.instance;

  @override
  Future<List<Regulation>> getAvailableRegulations() async {
    dev.log('Fetching available regulations from the cloud...');
    Database? db;
    Connection? conn;
    File? tempFile;

    try {
      // 1. Получаем временную ссылку на файл
      final url = await _remoteDataProvider
          .getPresignedUrl('v1/documents/rules.parquet');

      // 2. Скачиваем файл с помощью Dart http
      dev.log('Downloading parquet file from presigned URL...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to download parquet file: ${response.statusCode}');
      }
      dev.log('Download complete.');

      // 3. Сохраняем скачанные данные во временный файл
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/rules.parquet');
      await tempFile.writeAsBytes(response.bodyBytes);
      dev.log('Parquet file saved to temporary location: ${tempFile.path}');

      // 4. Открываем DuckDB и читаем ЛОКАЛЬНЫЙ файл. httpfs не нужен.
      db = await duckdb.open(":memory:");
      conn = await duckdb.connect(db);

      final ResultSet result = await conn.query(
          "SELECT id, name, abbreviation FROM read_parquet('${tempFile.path}')");

      final regulations = result.fetchAll().map((row) {
        return Regulation(
          id: row[0] as int,
          title: row[1] as String,
          description: row[2] as String,
          // Остальные поля пока не доступны в rules.parquet, используем заглушки
          lastUpdated: DateTime.now(), // Можно будет добавить в parquet
          isDownloaded: false, // По определению не скачан
          isFavorite: false, // Управляется локально
          chapters: [], // Главы будут загружаться отдельно при выборе
        );
      }).toList();

      dev.log('Successfully fetched ${regulations.length} regulations.');
      return regulations;
    } finally {
      // 5. Очищаем ресурсы
      await conn?.dispose();
      await db?.dispose();
      // Удаляем временный файл
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
        dev.log('Deleted temporary file: ${tempFile.path}');
      }
    }
  }

  @override
  Future<bool> isRegulationDataCached(int ruleId) async {
    final conn = await _dbProvider.connection;
    final result = await conn
        .query('SELECT 1 FROM chapters WHERE rule_id = $ruleId LIMIT 1');
    final isCached = result.fetchAll().isNotEmpty;
    dev.log('Checking if regulation $ruleId is cached: $isCached');
    return isCached;
  }

  @override
  Future<void> downloadAndCacheRegulationData(int ruleId) async {
    dev.log('Starting download and cache for regulation $ruleId...');
    // 1. Download chapters
    await _downloadAndInsert(
      objectKey: 'v1/documents/chapters/rule_id=$ruleId/data_0.parquet',
      tableName: 'chapters',
      ruleId: ruleId,
    );
    // 2. Download paragraphs
    await _downloadAndInsert(
      objectKey: 'v1/documents/paragraphs/rule_id=$ruleId/data_0.parquet',
      tableName: 'paragraphs',
      ruleId: ruleId,
    );
    dev.log('Successfully downloaded and cached data for regulation $ruleId.');
  }

  Future<void> _downloadAndInsert(
      {required String objectKey,
      required String tableName,
      required int ruleId}) async {
    File? tempFile;
    try {
      final url = await _remoteDataProvider.getPresignedUrl(objectKey);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to download $objectKey: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/${tableName}_rule_id_$ruleId.parquet');
      await tempFile.writeAsBytes(response.bodyBytes);

      final conn = await _dbProvider.connection;

      String query;
      if (tableName == 'chapters') {
        // For chapters, we need to add the rule_id manually as it's not in the parquet file
        query =
            "INSERT INTO chapters (id, name, num, orderNum, rule_id) SELECT id, name, num, orderNum, $ruleId FROM read_parquet('${tempFile.path}')";
      } else {
        // For other tables (like paragraphs), assume columns match
        query =
            "INSERT INTO $tableName SELECT * FROM read_parquet('${tempFile.path}')";
      }
      await conn.query(query);
      dev.log('Successfully inserted data into $tableName for rule $ruleId');
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
