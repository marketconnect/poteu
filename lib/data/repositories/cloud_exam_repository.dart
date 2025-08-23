import 'dart:io';
import 'dart:convert';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poteu/data/helpers/remote_data_provider.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'package:poteu/domain/repositories/exam_repository.dart';

class CloudExamRepository implements ExamRepository {
  final RemoteDataProvider _remoteDataProvider = RemoteDataProvider();

  // Helper для получения пути к локальному файлу кэша
  Future<File> _getLocalExamFile(int regulationId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/exam_data_$regulationId.parquet');
  }

  // Helper для получения ключа для хранения версии в SharedPreferences
  String _getVersionKey(int regulationId) => 'exam_version_$regulationId';
  // Helper для получения ключа для хранения даты последней проверки
  String _getLastCheckDateKey(int regulationId) =>
      'exam_last_check_date_$regulationId';

  @override
  Future<List<ExamQuestion>> getQuestions(int regulationId) async {
    dev.log('Fetching exam questions for regulation $regulationId...');
    final file = await _getLocalExamFile(regulationId);
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString(_getLastCheckDateKey(regulationId));
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 1. Проверяем, нужно ли вообще обращаться к сети (логика "раз в сутки")
    if (lastCheckDate == today && await file.exists()) {
      dev.log('Daily check already performed. Using cached file.');
      return _loadQuestionsFromFile(file);
    }

    try {
      // 2. Если проверка нужна, получаем последнюю версию с сервера
      final versionObjectKey =
          'v1/documents/exams/rule_id=$regulationId/version.json';
      final versionUrl =
          await _remoteDataProvider.getPresignedUrl(versionObjectKey);
      final versionResponse = await http.get(Uri.parse(versionUrl));

      if (versionResponse.statusCode == 200) {
        final serverVersionData = json.decode(versionResponse.body);
        final serverVersion = serverVersionData['version'] as String;
        final localVersion = prefs.getString(_getVersionKey(regulationId));

        dev.log('Local version: $localVersion, Server version: $serverVersion');

        // 3. Сравниваем версии и при необходимости скачиваем новый файл
        if (serverVersion != localVersion || !await file.exists()) {
          dev.log('New version found or file is missing. Downloading...');
          final dataObjectKey =
              'v1/documents/exams/rule_id=$regulationId/data_0.parquet';
          final dataUrl =
              await _remoteDataProvider.getPresignedUrl(dataObjectKey);
          final dataResponse = await http.get(Uri.parse(dataUrl));

          if (dataResponse.statusCode == 200) {
            // Перезаписываем старый файл новым содержимым
            await file.writeAsBytes(dataResponse.bodyBytes);
            await prefs.setString(_getVersionKey(regulationId), serverVersion);
            dev.log(
                'Successfully downloaded and cached new version: $serverVersion');
          } else {
            throw Exception(
                'Failed to download exam data file: ${dataResponse.statusCode}');
          }
        } else {
          dev.log('Local version is up-to-date.');
        }
      } else if (versionResponse.statusCode == 404) {
        // Если файла версии нет, но и локального файла тоже нет - значит экзамена не существует
        if (!await file.exists()) {
          throw ExamNotFoundException(regulationId);
        }
        // Если файла версии нет, но локальный есть - просто используем его
        dev.log('version.json not found on server, using existing local file.');
      } else {
        // Другая ошибка при получении версии
        dev.log(
            'Could not fetch version.json. Status: ${versionResponse.statusCode}. Using cache if available.');
      }

      // 4. После всех проверок обновляем дату последней проверки на сегодня
      await prefs.setString(_getLastCheckDateKey(regulationId), today);

      // 5. Загружаем вопросы из локального файла (который теперь актуален)
      if (!await file.exists()) {
        throw Exception(
            'Exam file not available locally and could not be downloaded.');
      }
      return _loadQuestionsFromFile(file);
    } catch (e) {
      dev.log(
          'Error during update check: $e. Attempting to load from cache as a fallback.');
      if (await file.exists()) {
        dev.log('Loading from cache due to network error.');
        return _loadQuestionsFromFile(file);
      }
      // Если произошла ошибка и кэша нет, пробрасываем ошибку дальше
      rethrow;
    }
  }

  /// Вспомогательная функция для чтения вопросов из локального файла Parquet
  Future<List<ExamQuestion>> _loadQuestionsFromFile(File file) async {
    Database? db;
    Connection? conn;
    try {
      dev.log('Loading questions from local file: ${file.path}');
      db = await duckdb.open(":memory:");
      conn = await duckdb.connect(db);

      final ResultSet result = await conn.query(
          "SELECT name, question, answers, correctAnswers FROM read_parquet('${file.path}')");

      final questions = result.fetchAll().map((row) {
        return ExamQuestion.fromMap({
          'name': row[0],
          'question': row[1],
          'answers': row[2],
          'correctAnswers': row[3],
        });
      }).toList();
      dev.log('Successfully loaded ${questions.length} questions from file.');
      return questions;
    } finally {
      await conn?.dispose();
      await db?.dispose();
    }
  }
}
