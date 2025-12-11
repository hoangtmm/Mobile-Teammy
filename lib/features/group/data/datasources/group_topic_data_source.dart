import 'dart:convert';

import 'package:http/http.dart' as http;

class GroupTopicDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  GroupTopicDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Cập nhật topic cho nhóm
  /// PATCH /api/groups/{groupId}
  Future<void> updateGroupTopic({
    required String accessToken,
    required String groupId,
    required String topicId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId');
    
    final response = await _httpClient.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'topicId': topicId,
      }),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to update group topic (${response.statusCode}): ${response.body}',
      );
    }
  }
}
