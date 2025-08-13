import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

import 'package:poteu/config.dart';

/// Провайдер для управления единственным соединением с базой данных DuckDB
/// Реализует паттерн Singleton для оптимизации доступа к БД
class DuckDBProvider {
  static DuckDBProvider? _instance;
  static Database? _database;
  static Connection? _connection;
  static bool _isInitialized = false;

  DuckDBProvider._();

  /// Получение единственного экземпляра провайдера
  static DuckDBProvider get instance {
    _instance ??= DuckDBProvider._();
    return _instance!;
  }

  /// Инициализация базы данных (выполняется только один раз)
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // 1. Загрузка из assets
      final data = await rootBundle.load(AppConfig.instance.databasePath);
      final dir = await getApplicationDocumentsDirectory();
      final flavorName = AppConfig.instance.flavorName;
      final localDbPath = '${dir.path}/${flavorName}_regulations.duckdb';
      final file = File(localDbPath);

      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List());
      }

      // 2. Открытие БД
      _database = await duckdb.open(file.path);
      _connection = await duckdb.connect(_database!);

      // Создаем таблицу для пользовательских правок, если она не существует
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS user_paragraph_edits (
          original_id INTEGER PRIMARY KEY,
          content TEXT,
          note TEXT,
          updated_at TIMESTAMP
        );
      ''');

      // Add change_date column to rules table if it doesn't exist for version sync
      await _connection!
          .query('ALTER TABLE rules ADD COLUMN IF NOT EXISTS change_date TEXT;');

      _isInitialized = true;
      dev.log('🗄️ DuckDB initialized successfully');
    } catch (e) {
      dev.log('❌ Error initializing DuckDB: $e');
      rethrow;
    }
  }

  /// Получение активного соединения
  Future<Connection> get connection async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_connection == null) {
      throw Exception('Database connection is not available');
    }

    return _connection!;
  }

  /// Проверка, инициализирована ли база данных
  bool get isInitialized => _isInitialized;

  /// Закрытие соединения и освобождение ресурсов
  Future<void> dispose() async {
    try {
      if (_connection != null) {
        await _connection!.dispose();
        _connection = null;
      }

      if (_database != null) {
        await _database!.dispose();
        _database = null;
      }

      _isInitialized = false;
      dev.log('🗄️ DuckDB disposed successfully');
    } catch (e) {
      dev.log('❌ Error disposing DuckDB: $e');
    }
  }

  /// Выполнение запроса с автоматическим управлением соединением
  Future<ResultSet> executeQuery(String query) async {
    final conn = await connection;
    return await conn.query(query);
  }

  Future<void> forceCheckpoint() async {
    if (!_isInitialized || _connection == null) {
      return;
    }
    try {
      await _connection!.query('CHECKPOINT;');
      dev.log('🗄️ DuckDB CHECKPOINT successful');
    } catch (e) {
      dev.log('❌ Error during DuckDB CHECKPOINT: $e');
    }
  }

  /// Выполнение транзакции
  Future<T> executeTransaction<T>(
      Future<T> Function(Connection) transaction) async {
    final conn = await connection;
    return await transaction(conn);
  }
}
