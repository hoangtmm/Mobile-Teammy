import 'dart:convert';

import 'package:http/http.dart' as http;

class GroupMentorDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  GroupMentorDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Gửi lời mời mentor cho nhóm
  /// POST /api/groups/{groupId}/mentor-invites
  Future<void> inviteMentor({
    required String accessToken,
    required String groupId,
    required String mentorUserId,
    required String topicId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId/mentor-invites');
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'mentorUserId': mentorUserId,
        'topicId': topicId,
        'message': message,
      }),
    );

    if (response.statusCode == 409) {
      throw GroupMustBeFullException(
        'Group must be full before inviting mentor',
      );
    }

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to invite mentor (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class GroupMustBeFullException implements Exception {
  final String message;
  GroupMustBeFullException(this.message);

  @override
  String toString() => message;
}
