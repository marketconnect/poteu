import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:poteu/.env.dart';

class RemoteDataProvider {
  // IP-адрес сервиса для получения временных ссылок
  final String _baseUrl = ServerInfo.ycDataProvider;

  Future<String> getPresignedUrl(String objectKey) async {
    final uri = Uri.parse('$_baseUrl/api/v1/generate-url?objectKey=$objectKey');
    dev.log('Requesting presigned URL for: $objectKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final url = data['url'];
      dev.log('Received presigned URL: $url');
      return url;
    } else {
      dev.log(
          'Failed to get presigned URL for $objectKey. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to get presigned URL for $objectKey');
    }
  }
}
