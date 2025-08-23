import 'dart:io';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

import 'package:poteu/data/helpers/remote_data_provider.dart';
import 'package:poteu/domain/entities/exam_question.dart';
import 'package:poteu/domain/repositories/exam_repository.dart';

class CloudExamRepository implements ExamRepository {
  final RemoteDataProvider _remoteDataProvider = RemoteDataProvider();

  @override
  Future<List<ExamQuestion>> getQuestions(int regulationId) async {
    dev.log('Fetching exam questions for regulation $regulationId...');
    Database? db;
    Connection? conn;
    File? tempFile;

    try {
      final objectKey =
          'v1/documents/exams/rule_id=$regulationId/data_0.parquet';
      final url = await _remoteDataProvider.getPresignedUrl(objectKey);

      dev.log('Downloading exam parquet file...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 404) {
        dev.log(
            'Exam not found for regulation $regulationId (404). This is a valid case.');
        throw ExamNotFoundException(regulationId);
      }
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to download exam parquet file: ${response.statusCode}');
      }
      dev.log('Download complete.');

      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/exam_$regulationId.parquet');
      await tempFile.writeAsBytes(response.bodyBytes);
      dev.log('Exam parquet file saved to: ${tempFile.path}');

      db = await duckdb.open(":memory:");
      conn = await duckdb.connect(db);

      final ResultSet result = await conn.query(
          "SELECT name, question, answers, correctAnswers FROM read_parquet('${tempFile.path}')");

      return result.fetchAll().map((row) {
        return ExamQuestion.fromMap({
          'name': row[0],
          'question': row[1],
          'answers': row[2],
          'correctAnswers': row[3],
        });
      }).toList();
    } catch (e) {
      dev.log('Error fetching exam questions: $e');
      rethrow;
    } finally {
      await conn?.dispose();
      await db?.dispose();
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
        dev.log('Deleted temporary exam file: ${tempFile.path}');
      }
    }
  }
}
