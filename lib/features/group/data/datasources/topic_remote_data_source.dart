import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/topic_model.dart';

class TopicRemoteDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  TopicRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Lấy danh sách topics từ /api/topics
  Future<List<TopicModel>> fetchTopics(String accessToken) async {
    final uri = Uri.parse('$baseUrl/api/topics');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch topics (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TopicModel.fromJson)
        .toList();
  }
}
